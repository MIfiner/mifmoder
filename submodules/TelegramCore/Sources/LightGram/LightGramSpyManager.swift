import Foundation
import Postbox

public struct SpyDeletedMessageRecord: Codable, Equatable {
    public let id: String
    public let peerId: Int64
    public let messageId: Int32
    public let chatTitle: String
    public let authorName: String
    public let text: String
    public let mediaType: String?
    public let mediaDescription: String?
    public let originalTimestamp: Int32
    public let deletionTimestamp: Int32
    
    public init(peerId: Int64, messageId: Int32, chatTitle: String = "Chat", authorName: String = "Unknown", text: String = "", mediaType: String? = nil, mediaDescription: String? = nil, originalTimestamp: Int32, deletionTimestamp: Int32) {
        self.id = "\(peerId)_\(messageId)"
        self.peerId = peerId
        self.messageId = messageId
        self.chatTitle = chatTitle
        self.authorName = authorName
        self.text = text
        self.mediaType = mediaType
        self.mediaDescription = mediaDescription
        self.originalTimestamp = originalTimestamp
        self.deletionTimestamp = deletionTimestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.peerId = try container.decode(Int64.self, forKey: .peerId)
        self.messageId = try container.decode(Int32.self, forKey: .messageId)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? "\(self.peerId)_\(self.messageId)"
        self.chatTitle = (try? container.decode(String.self, forKey: .chatTitle)) ?? "Chat"
        self.authorName = (try? container.decode(String.self, forKey: .authorName)) ?? "Unknown"
        self.text = (try? container.decode(String.self, forKey: .text)) ?? ""
        self.mediaType = try? container.decode(String.self, forKey: .mediaType)
        self.mediaDescription = try? container.decode(String.self, forKey: .mediaDescription)
        self.originalTimestamp = (try? container.decode(Int32.self, forKey: .originalTimestamp)) ?? 0
        self.deletionTimestamp = (try? container.decode(Int32.self, forKey: .deletionTimestamp)) ?? 0
    }
}

public struct SpyEditRecord: Codable, Equatable {
    public let id: String
    public let peerId: Int64
    public let messageId: Int32
    public let chatTitle: String
    public let authorName: String
    public let previousText: String
    public let newText: String
    public let timestamp: Int32
    public let revision: Int
    
    public init(peerId: Int64, messageId: Int32, chatTitle: String = "Chat", authorName: String = "Unknown", previousText: String, newText: String, timestamp: Int32, revision: Int) {
        self.id = "\(peerId)_\(messageId)_rev\(revision)"
        self.peerId = peerId
        self.messageId = messageId
        self.chatTitle = chatTitle
        self.authorName = authorName
        self.previousText = previousText
        self.newText = newText
        self.timestamp = timestamp
        self.revision = revision
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.peerId = try container.decode(Int64.self, forKey: .peerId)
        self.messageId = try container.decode(Int32.self, forKey: .messageId)
        self.revision = (try? container.decode(Int.self, forKey: .revision)) ?? 1
        self.id = (try? container.decode(String.self, forKey: .id)) ?? "\(self.peerId)_\(self.messageId)_rev\(self.revision)"
        self.chatTitle = (try? container.decode(String.self, forKey: .chatTitle)) ?? "Chat"
        self.authorName = (try? container.decode(String.self, forKey: .authorName)) ?? "Unknown"
        self.previousText = (try? container.decode(String.self, forKey: .previousText)) ?? ""
        self.newText = (try? container.decode(String.self, forKey: .newText)) ?? ""
        self.timestamp = (try? container.decode(Int32.self, forKey: .timestamp)) ?? 0
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
    
    private var deletedMap: [String: SpyDeletedMessageRecord] = [:]
    private var editedMap: [String: [SpyEditRecord]] = [:]
    private let mapLock = NSLock()
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        
        // Prioritize LightGramContainer for Sideloadly / TrollStore sandbox consistency
        let containerDir = appSupport.appendingPathComponent("LightGramContainer", isDirectory: true)
        if !fileManager.fileExists(atPath: containerDir.path) {
            try? fileManager.createDirectory(at: containerDir, withIntermediateDirectories: true)
        }
        
        self.archiveDirectory = containerDir.appendingPathComponent("LightGramSpyArchive", isDirectory: true)
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
            
            var loadedDeleted: [SpyDeletedMessageRecord] = []
            if let deletedData = try? Data(contentsOf: self.deletedMessagesFile),
               let records = try? JSONDecoder().decode([SpyDeletedMessageRecord].self, from: deletedData) {
                loadedDeleted = records
                self.deletedMessagesCache = records
            }
            
            var loadedEdits: [SpyEditRecord] = []
            if let editedData = try? Data(contentsOf: self.editedMessagesFile),
               let records = try? JSONDecoder().decode([SpyEditRecord].self, from: editedData) {
                loadedEdits = records
                self.editedMessagesCache = records
            }
            
            self.mapLock.lock()
            self.deletedMap.removeAll()
            for record in loadedDeleted {
                self.deletedMap[record.id] = record
            }
            self.editedMap.removeAll()
            for record in loadedEdits {
                let key = "\(record.peerId)_\(record.messageId)"
                var list = self.editedMap[key] ?? []
                list.append(record)
                self.editedMap[key] = list
            }
            self.mapLock.unlock()
            
            self.hasLoadedCache = true
            self.enforceTTL()
        }
    }
    
    // MARK: - Synchronous Fast Lookups for Chat Bubbles
    public func isMessageDeleted(peerId: Int64, messageId: Int32) -> Bool {
        self.mapLock.lock()
        defer { self.mapLock.unlock() }
        return self.deletedMap["\(peerId)_\(messageId)"] != nil
    }
    
    public func getDeletedRecord(peerId: Int64, messageId: Int32) -> SpyDeletedMessageRecord? {
        self.mapLock.lock()
        defer { self.mapLock.unlock() }
        return self.deletedMap["\(peerId)_\(messageId)"]
    }
    
    public func getEditRecords(peerId: Int64, messageId: Int32) -> [SpyEditRecord] {
        self.mapLock.lock()
        defer { self.mapLock.unlock() }
        return self.editedMap["\(peerId)_\(messageId)"] ?? []
    }
    
    public func markMessageAsDeleted(peerId: Int64, messageId: Int32, originalTimestamp: Int32 = 0, chatTitle: String = "Chat", authorName: String = "Unknown", text: String = "", mediaType: String? = nil, mediaDescription: String? = nil) {
        let key = "\(peerId)_\(messageId)"
        let now = Int32(Date().timeIntervalSince1970)
        let record = SpyDeletedMessageRecord(
            peerId: peerId,
            messageId: messageId,
            chatTitle: chatTitle,
            authorName: authorName,
            text: text,
            mediaType: mediaType,
            mediaDescription: mediaDescription,
            originalTimestamp: originalTimestamp,
            deletionTimestamp: now
        )
        self.mapLock.lock()
        self.deletedMap[key] = record
        self.mapLock.unlock()
    }
    
    private func persistDeletedMessages() {
        guard let data = try? JSONEncoder().encode(self.deletedMessagesCache) else { return }
        try? data.write(to: self.deletedMessagesFile, options: .atomic)
    }
    
    private func persistEditedMessages() {
        guard let data = try? JSONEncoder().encode(self.editedMessagesCache) else { return }
        try? data.write(to: self.editedMessagesFile, options: .atomic)
    }
    
    // MARK: - Message Recording
    public func recordDeletedMessage(from message: Message, in transaction: Transaction) {
        guard LightGramSettings.shared.saveDeletedMessages else { return }
        
        let peerId = message.id.peerId.toInt64()
        let messageId = message.id.id
        let chatTitle = transaction.getPeer(message.id.peerId)?.debugDisplayTitle ?? "Chat"
        
        var authorName = "Unknown"
        if let author = message.author {
            authorName = author.debugDisplayTitle
        } else if let authorPeer = transaction.getPeer(message.id.peerId) {
            authorName = authorPeer.debugDisplayTitle
        }
        
        let text = message.text
        var mediaType: String?
        var mediaDescription: String?
        
        if let firstMedia = message.media.first {
            if let _ = firstMedia as? TelegramMediaImage {
                mediaType = "photo"
                mediaDescription = "Photo"
            } else if let file = firstMedia as? TelegramMediaFile {
                if file.isVoice {
                    mediaType = "voice"
                    mediaDescription = "Voice Message"
                } else if file.isVideo {
                    mediaType = "video"
                    mediaDescription = "Video"
                } else if file.isSticker {
                    mediaType = "sticker"
                    mediaDescription = "Sticker (\(file.fileName ?? "sticker"))"
                } else {
                    mediaType = "document"
                    mediaDescription = "File: \(file.fileName ?? "document")"
                }
            } else if let contact = firstMedia as? TelegramMediaContact {
                mediaType = "contact"
                mediaDescription = "Contact: \(contact.firstName) \(contact.lastName)"
            } else if let _ = firstMedia as? TelegramMediaMap {
                mediaType = "location"
                mediaDescription = "Location"
            } else if let poll = firstMedia as? TelegramMediaPoll {
                mediaType = "poll"
                mediaDescription = "Poll: \(poll.text)"
            } else if let _ = firstMedia as? TelegramMediaWebpage {
                mediaType = "link"
                mediaDescription = "Link preview"
            }
        }
        
        self.recordDeletedMessage(
            peerId: peerId,
            messageId: messageId,
            chatTitle: chatTitle,
            authorName: authorName,
            text: text,
            mediaType: mediaType,
            mediaDescription: mediaDescription,
            originalTimestamp: message.timestamp
        )
    }
    
    public func recordDeletedMessage(peerId: Int64, messageId: Int32, chatTitle: String = "Chat", authorName: String = "Unknown", text: String, mediaType: String? = nil, mediaDescription: String? = nil, originalTimestamp: Int32) {
        guard LightGramSettings.shared.saveDeletedMessages else { return }
        
        self.queue.async { [weak self] in
            guard let self = self else { return }
            let now = Int32(Date().timeIntervalSince1970)
            let record = SpyDeletedMessageRecord(
                peerId: peerId,
                messageId: messageId,
                chatTitle: chatTitle.isEmpty ? "Chat" : chatTitle,
                authorName: authorName.isEmpty ? "Unknown" : authorName,
                text: text,
                mediaType: mediaType,
                mediaDescription: mediaDescription,
                originalTimestamp: originalTimestamp,
                deletionTimestamp: now
            )
            
            // Avoid duplicate entries
            if !self.deletedMessagesCache.contains(where: { $0.peerId == peerId && $0.messageId == messageId }) {
                self.deletedMessagesCache.insert(record, at: 0)
                // Cap cache to 10,000 items
                if self.deletedMessagesCache.count > 10000 {
                    let removed = self.deletedMessagesCache.removeLast()
                    self.mapLock.lock()
                    self.deletedMap.removeValue(forKey: removed.id)
                    self.mapLock.unlock()
                }
                self.mapLock.lock()
                self.deletedMap[record.id] = record
                self.mapLock.unlock()
                self.persistDeletedMessages()
            }
        }
    }
    
    public func recordEditedMessage(previousMessage: Message, newMessage: StoreMessage, in transaction: Transaction) {
        guard LightGramSettings.shared.saveEditHistory else { return }
        let previousText = previousMessage.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let newText = newMessage.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if previousText.isEmpty || previousText == newText { return }
        
        let peerId = previousMessage.id.peerId.toInt64()
        let messageId = previousMessage.id.id
        let chatTitle = transaction.getPeer(previousMessage.id.peerId)?.debugDisplayTitle ?? "Chat"
        let authorName = previousMessage.author?.debugDisplayTitle ?? transaction.getPeer(previousMessage.id.peerId)?.debugDisplayTitle ?? "Unknown"
        
        self.recordEditedMessage(
            peerId: peerId,
            messageId: messageId,
            chatTitle: chatTitle,
            authorName: authorName,
            previousText: previousMessage.text,
            newText: newMessage.text
        )
    }
    
    public func recordEditedMessage(peerId: Int64, messageId: Int32, chatTitle: String = "Chat", authorName: String = "Unknown", previousText: String, newText: String) {
        guard LightGramSettings.shared.saveEditHistory else { return }
        let pTrimmed = previousText.trimmingCharacters(in: .whitespacesAndNewlines)
        let nTrimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        if pTrimmed.isEmpty || pTrimmed == nTrimmed { return }
        
        self.queue.async { [weak self] in
            guard let self = self else { return }
            let now = Int32(Date().timeIntervalSince1970)
            let existingRevs = self.editedMessagesCache.filter { $0.peerId == peerId && $0.messageId == messageId }
            let revNum = existingRevs.count + 1
            
            let record = SpyEditRecord(
                peerId: peerId,
                messageId: messageId,
                chatTitle: chatTitle.isEmpty ? "Chat" : chatTitle,
                authorName: authorName.isEmpty ? "Unknown" : authorName,
                previousText: previousText,
                newText: newText,
                timestamp: now,
                revision: revNum
            )
            
            self.editedMessagesCache.insert(record, at: 0)
            if self.editedMessagesCache.count > 10000 {
                self.editedMessagesCache.removeLast()
            }
            let key = "\(peerId)_\(messageId)"
            self.mapLock.lock()
            var list = self.editedMap[key] ?? []
            list.append(record)
            self.editedMap[key] = list
            self.mapLock.unlock()
            self.persistEditedMessages()
        }
    }
    
    // MARK: - Queries
    public func fetchAllDeletedMessages(completion: @escaping ([SpyDeletedMessageRecord]) -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let records = self.deletedMessagesCache
            DispatchQueue.main.async { completion(records) }
        }
    }
    
    public func fetchAllEditRecords(completion: @escaping ([SpyEditRecord]) -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let records = self.editedMessagesCache
            DispatchQueue.main.async { completion(records) }
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
    
    public func deleteRecord(id: String, isDeletedMessage: Bool, completion: @escaping () -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion() }
                return
            }
            if isDeletedMessage {
                self.deletedMessagesCache.removeAll(where: { $0.id == id })
                self.mapLock.lock()
                self.deletedMap.removeValue(forKey: id)
                self.mapLock.unlock()
                self.persistDeletedMessages()
            } else {
                self.editedMessagesCache.removeAll(where: { $0.id == id })
                self.mapLock.lock()
                for (k, v) in self.editedMap {
                    self.editedMap[k] = v.filter { $0.id != id }
                }
                self.mapLock.unlock()
                self.persistEditedMessages()
            }
            DispatchQueue.main.async { completion() }
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
            self.mapLock.lock()
            self.deletedMap.removeAll()
            self.editedMap.removeAll()
            self.mapLock.unlock()
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
