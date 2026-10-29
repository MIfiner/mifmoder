import Foundation
import UIKit
import SwiftSignalKit

public struct SpyDeletedMessageRecord: Codable, Equatable {
    public let id: String
    public let peerId: Int64
    public let messageId: Int32
    public let authorName: String
    public let text: String
    public let mediaType: String?
    public let originalTimestamp: Int32
    public let deletionTimestamp: Int32
    
    public init(peerId: Int64, messageId: Int32, authorName: String, text: String, mediaType: String?, originalTimestamp: Int32, deletionTimestamp: Int32) {
        self.id = "\(peerId)_\(messageId)_\(deletionTimestamp)"
        self.peerId = peerId
        self.messageId = messageId
        self.authorName = authorName
        self.text = text
        self.mediaType = mediaType
        self.originalTimestamp = originalTimestamp
        self.deletionTimestamp = deletionTimestamp
    }
}

public struct SpyEditRecord: Codable, Equatable {
    public let id: String
    public let peerId: Int64
    public let messageId: Int32
    public let authorName: String
    public let previousText: String
    public let newText: String
    public let timestamp: Int32
    public let revision: Int
    
    public init(peerId: Int64, messageId: Int32, authorName: String, previousText: String, newText: String, timestamp: Int32, revision: Int) {
        self.id = "\(peerId)_\(messageId)_rev\(revision)"
        self.peerId = peerId
        self.messageId = messageId
        self.authorName = authorName
        self.previousText = previousText
        self.newText = newText
        self.timestamp = timestamp
        self.revision = revision
    }
}

public final class LightGramSpyManager {
    public static let shared = LightGramSpyManager()
    
    private let queue = DispatchQueue(label: "site.lightgram.spymanager", qos: .utility)
    private let archiveDirectory: URL
    private let deletedMessagesFile: URL
    private let editedMessagesFile: URL
    
    private var deletedMessagesCache: [SpyDeletedMessageRecord] = []
    private var editedMessagesCache: [SpyEditRecord] = []
    private var hasLoadedCache = false
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.archiveDirectory = appSupport.appendingPathComponent("LightGramSpyArchive", isDirectory: true)
        self.deletedMessagesFile = self.archiveDirectory.appendingPathComponent("deleted_messages.json")
        self.editedMessagesFile = self.archiveDirectory.appendingPathComponent("edited_messages.json")
        
        try? fileManager.createDirectory(at: self.archiveDirectory, withIntermediateDirectories: true, attributes: [
            FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ])
        
        self.loadFromDisk()
    }
    
    private func loadFromDisk() {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            
            if let deletedData = try? Data(contentsOf: self.deletedMessagesFile),
               let records = try? JSONDecoder().decode([SpyDeletedMessageRecord].self, from: deletedData) {
                self.deletedMessagesCache = records
            }
            
            if let editedData = try? Data(contentsOf: self.editedMessagesFile),
               let records = try? JSONDecoder().decode([SpyEditRecord].self, from: editedData) {
                self.editedMessagesCache = records
            }
            
            self.hasLoadedCache = true
            self.enforceTTL()
        }
    }
    
    private func persistDeletedMessages() {
        guard let data = try? JSONEncoder().encode(self.deletedMessagesCache) else { return }
        try? data.write(to: self.deletedMessagesFile, options: .atomic)
    }
    
    private func persistEditedMessages() {
        guard let data = try? JSONEncoder().encode(self.editedMessagesCache) else { return }
        try? data.write(to: self.editedMessagesFile, options: .atomic)
    }
    
    public func recordDeletedMessage(peerId: Int64, messageId: Int32, authorName: String, text: String, mediaType: String?, originalTimestamp: Int32) {
        guard LightGramSettings.shared.saveDeletedMessages else { return }
        
        self.queue.async { [weak self] in
            guard let self = self else { return }
            let now = Int32(Date().timeIntervalSince1970)
            let record = SpyDeletedMessageRecord(
                peerId: peerId,
                messageId: messageId,
                authorName: authorName.isEmpty ? "Unknown" : authorName,
                text: text,
                mediaType: mediaType,
                originalTimestamp: originalTimestamp,
                deletionTimestamp: now
            )
            
            // Avoid duplicate entries
            if !self.deletedMessagesCache.contains(where: { $0.peerId == peerId && $0.messageId == messageId }) {
                self.deletedMessagesCache.insert(record, at: 0)
                // Cap cache in memory/disk to 5000 items
                if self.deletedMessagesCache.count > 5000 {
                    self.deletedMessagesCache.removeLast()
                }
                self.persistDeletedMessages()
            }
        }
    }
    
    public func recordEditedMessage(peerId: Int64, messageId: Int32, authorName: String, previousText: String, newText: String) {
        guard LightGramSettings.shared.saveEditHistory else { return }
        if previousText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
        if previousText == newText { return }
        
        self.queue.async { [weak self] in
            guard let self = self else { return }
            let now = Int32(Date().timeIntervalSince1970)
            let existingRevs = self.editedMessagesCache.filter { $0.peerId == peerId && $0.messageId == messageId }
            let revNum = existingRevs.count + 1
            
            let record = SpyEditRecord(
                peerId: peerId,
                messageId: messageId,
                authorName: authorName.isEmpty ? "Unknown" : authorName,
                previousText: previousText,
                newText: newText,
                timestamp: now,
                revision: revNum
            )
            
            self.editedMessagesCache.insert(record, at: 0)
            if self.editedMessagesCache.count > 5000 {
                self.editedMessagesCache.removeLast()
            }
            self.persistEditedMessages()
        }
    }
    
    public func fetchDeletedMessages(peerId: Int64? = nil, completion: @escaping ([SpyDeletedMessageRecord]) -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let results: [SpyDeletedMessageRecord]
            if let pid = peerId {
                results = self.deletedMessagesCache.filter { $0.peerId == pid }
            } else {
                results = self.deletedMessagesCache
            }
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    public func fetchEditHistory(peerId: Int64, messageId: Int32, completion: @escaping ([SpyEditRecord]) -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let results = self.editedMessagesCache.filter { $0.peerId == peerId && $0.messageId == messageId }
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    public func enforceTTL() {
        let ttlDays = LightGramSettings.shared.retentionDaysTTL
        guard ttlDays > 0 else { return }
        
        let cutoff = Int32(Date().timeIntervalSince1970) - Int32(ttlDays * 86400)
        let initialDeletedCount = self.deletedMessagesCache.count
        let initialEditedCount = self.editedMessagesCache.count
        
        self.deletedMessagesCache.removeAll(where: { $0.deletionTimestamp < cutoff })
        self.editedMessagesCache.removeAll(where: { $0.timestamp < cutoff })
        
        if self.deletedMessagesCache.count != initialDeletedCount {
            self.persistDeletedMessages()
        }
        if self.editedMessagesCache.count != initialEditedCount {
            self.persistEditedMessages()
        }
    }
    
    public func clearAllData(completion: @escaping () -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.deletedMessagesCache.removeAll()
            self.editedMessagesCache.removeAll()
            try? FileManager.default.removeItem(at: self.deletedMessagesFile)
            try? FileManager.default.removeItem(at: self.editedMessagesFile)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    public func formattedArchiveSize() -> String {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        if let attrs1 = try? fileManager.attributesOfItem(atPath: self.deletedMessagesFile.path),
           let s1 = attrs1[.size] as? Int64 {
            totalSize += s1
        }
        if let attrs2 = try? fileManager.attributesOfItem(atPath: self.editedMessagesFile.path),
           let s2 = attrs2[.size] as? Int64 {
            totalSize += s2
        }
        
        if totalSize < 1024 {
            return "\(totalSize) B"
        } else if totalSize < 1024 * 1024 {
            return String(format: "%.1f KB", Double(totalSize) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(totalSize) / (1024.0 * 1024.0))
        }
    }
}
