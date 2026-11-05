import Foundation
import UIKit
import Photos
import LocalAuthentication
import SwiftSignalKit
import Postbox
import CommonCrypto

public struct MediaVaultItem: Codable, Equatable {
    public let id: String
    public let peerId: Int64
    public let messageId: Int32
    public let chatTitle: String
    public let authorName: String
    public let timestamp: Int32
    public let savedTimestamp: Int32
    public let mediaType: String // "photo", "video", "circle", "voice", "file"
    public let fileName: String
    public let fileSize: Int64
    public let relativePath: String
    public var isFavorite: Bool
    public let isOneTime: Bool
    public let mimeType: String
    public let duration: Double?
    public let dimensions: String?
    public var fileHash: String?
    
    public init(
        id: String = UUID().uuidString,
        peerId: Int64,
        messageId: Int32,
        chatTitle: String,
        authorName: String,
        timestamp: Int32,
        savedTimestamp: Int32 = Int32(Date().timeIntervalSince1970),
        mediaType: String,
        fileName: String,
        fileSize: Int64,
        relativePath: String,
        isFavorite: Bool = false,
        isOneTime: Bool = false,
        mimeType: String = "",
        duration: Double? = nil,
        dimensions: String? = nil,
        fileHash: String? = nil
    ) {
        self.id = id
        self.peerId = peerId
        self.messageId = messageId
        self.chatTitle = chatTitle
        self.authorName = authorName
        self.timestamp = timestamp
        self.savedTimestamp = savedTimestamp
        self.mediaType = mediaType
        self.fileName = fileName
        self.fileSize = fileSize
        self.relativePath = relativePath
        self.isFavorite = isFavorite
        self.isOneTime = isOneTime
        self.mimeType = mimeType
        self.duration = duration
        self.dimensions = dimensions
        self.fileHash = fileHash
    }
}

public final class LightGramMediaVaultManager {
    public static let shared = LightGramMediaVaultManager()
    
    private let queue = DispatchQueue(label: "site.lightgram.mediavault", qos: .utility)
    private let vaultDirectory: URL
    private let itemsDirectory: URL
    private let manifestFile: URL
    
    private var itemsCache: [MediaVaultItem] = []
    private let lock = NSLock()
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let containerDir = appSupport.appendingPathComponent("LightGramContainer", isDirectory: true)
        if !fileManager.fileExists(atPath: containerDir.path) {
            try? fileManager.createDirectory(at: containerDir, withIntermediateDirectories: true)
        }
        
        self.vaultDirectory = containerDir.appendingPathComponent("MediaVault", isDirectory: true)
        self.itemsDirectory = self.vaultDirectory.appendingPathComponent("items", isDirectory: true)
        self.manifestFile = self.vaultDirectory.appendingPathComponent("vault_items.json")
        
        try? fileManager.createDirectory(at: self.vaultDirectory, withIntermediateDirectories: true, attributes: [
            FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ])
        try? fileManager.createDirectory(at: self.itemsDirectory, withIntermediateDirectories: true, attributes: [
            FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ])
        
        self.loadManifestSync()
    }
    
    private func loadManifestSync() {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        if let data = try? Data(contentsOf: self.manifestFile),
           let items = try? JSONDecoder().decode([MediaVaultItem].self, from: data) {
            self.itemsCache = items
        } else {
            self.itemsCache = []
        }
    }
    
    private func saveManifestLocked() {
        if let data = try? JSONEncoder().encode(self.itemsCache) {
            try? data.write(to: self.manifestFile, options: .atomic)
        }
    }
    
    public func resolveItemURL(item: MediaVaultItem) -> URL {
        return self.vaultDirectory.appendingPathComponent(item.relativePath)
    }
    
    // MARK: - Save Media to Vault
    public func saveMedia(
        peerId: PeerId,
        messageId: MessageId,
        chatTitle: String,
        authorName: String,
        media: Any,
        isOneTime: Bool,
        account: Account,
        completion: @escaping (Bool, String?) -> Void
    ) {
        self.queue.async {
            var targetResource: TelegramMediaResource?
            var detectedType = "file"
            var extensionName = "dat"
            var mimeType = "application/octet-stream"
            var originalFileName = "file"
            var duration: Double? = nil
            var dimensions: String? = nil
            
            if let image = media as? TelegramMediaImage {
                detectedType = "photo"
                extensionName = "jpg"
                mimeType = "image/jpeg"
                originalFileName = "Photo_\(messageId.id).jpg"
                if let rep = largestImageRepresentation(image.representations) {
                    targetResource = rep.resource
                    dimensions = "\(Int(rep.dimensions.width))x\(Int(rep.dimensions.height))"
                }
            } else if let file = media as? TelegramMediaFile {
                targetResource = file.resource
                mimeType = file.mimeType
                if let dur = file.duration {
                    duration = Double(dur)
                }
                if let dims = file.dimensions {
                    dimensions = "\(Int(dims.width))x\(Int(dims.height))"
                }
                
                if file.isInstantVideo {
                    detectedType = "circle"
                    extensionName = "mp4"
                    originalFileName = "Circle_\(messageId.id).mp4"
                } else if file.isVideo || file.mimeType.hasPrefix("video/") {
                    detectedType = "video"
                    extensionName = "mp4"
                    originalFileName = file.fileName ?? "Video_\(messageId.id).mp4"
                } else if file.isVoice || file.mimeType.hasPrefix("audio/ogg") {
                    detectedType = "voice"
                    extensionName = "ogg"
                    originalFileName = file.fileName ?? "Voice_\(messageId.id).ogg"
                } else {
                    detectedType = "file"
                    if let fn = file.fileName, !fn.isEmpty {
                        originalFileName = fn
                        let ext = (fn as NSString).pathExtension
                        if !ext.isEmpty {
                            extensionName = ext
                        }
                    } else {
                        originalFileName = "File_\(messageId.id).dat"
                    }
                }
            }
            
            guard let resource = targetResource else {
                DispatchQueue.main.async { completion(false, "No valid media resource") }
                return
            }
            
            // Deduplication check: check if already saved
            self.lock.lock()
            let alreadyExists = self.itemsCache.contains {
                $0.peerId == peerId.toInt64() && $0.messageId == messageId.id && $0.mediaType == detectedType
            }
            self.lock.unlock()
            
            if alreadyExists {
                DispatchQueue.main.async { completion(true, "Already in Media Vault") }
                return
            }
            
            // Find cached file in Postbox mediaBox
            let fileManager = FileManager.default
            let cachedPath = account.postbox.mediaBox.completedResourcePath(resource)
            
            if let cachedPath = cachedPath, fileManager.fileExists(atPath: cachedPath) {
                self.copyAndStoreItem(
                    sourcePath: cachedPath,
                    peerId: peerId.toInt64(),
                    messageId: messageId.id,
                    chatTitle: chatTitle,
                    authorName: authorName,
                    timestamp: Int32(Date().timeIntervalSince1970),
                    detectedType: detectedType,
                    fileName: originalFileName,
                    extensionName: extensionName,
                    mimeType: mimeType,
                    duration: duration,
                    dimensions: dimensions,
                    isOneTime: isOneTime,
                    completion: completion
                )
                return
            }
            
            // If not cached locally, read data stream
            let dataPath = account.postbox.mediaBox.resourceData(id: resource.id, pathExtension: extensionName, option: .complete(waitUntilFetchStatus: true))
            let _ = (dataPath |> take(1)).start(next: { data in
                if data.complete && !data.path.isEmpty {
                    self.copyAndStoreItem(
                        sourcePath: data.path,
                        peerId: peerId.toInt64(),
                        messageId: messageId.id,
                        chatTitle: chatTitle,
                        authorName: authorName,
                        timestamp: Int32(Date().timeIntervalSince1970),
                        detectedType: detectedType,
                        fileName: originalFileName,
                        extensionName: extensionName,
                        mimeType: mimeType,
                        duration: duration,
                        dimensions: dimensions,
                        isOneTime: isOneTime,
                        completion: completion
                    )
                } else {
                    DispatchQueue.main.async { completion(false, "Media file downloading, retry in a moment") }
                }
            })
        }
    }
    
    private func computeFileHash(url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return "" }
        defer { try? handle.close() }
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 64 * 1024)
            if data.isEmpty { return false }
            data.withUnsafeBytes { buffer in
                _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
            }
            return true
        }) {}
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public func cleanupTemporaryCache() {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: tmpURL, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else { return }
        let cutoff = Date().addingTimeInterval(-180)
        for file in files {
            let name = file.lastPathComponent
            if name.hasPrefix("circle_") || name.hasPrefix("vo_") || name.hasPrefix("vault_") || name.hasPrefix("export_") {
                if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                   let modDate = attrs[.modificationDate] as? Date,
                   modDate < cutoff {
                    try? fileManager.removeItem(at: file)
                }
            }
        }
    }
    
    private func copyAndStoreItem(
        sourcePath: String,
        peerId: Int64,
        messageId: Int32,
        chatTitle: String,
        authorName: String,
        timestamp: Int32,
        detectedType: String,
        fileName: String,
        extensionName: String,
        mimeType: String,
        duration: Double?,
        dimensions: String?,
        isOneTime: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let fileManager = FileManager.default
        let itemId = UUID().uuidString
        let destFileName = "\(itemId).\(extensionName)"
        let relativePath = "items/\(destFileName)"
        let destURL = self.itemsDirectory.appendingPathComponent(destFileName)
        
        do {
            let hash = self.computeFileHash(url: URL(fileURLWithPath: sourcePath))
            if !hash.isEmpty {
                self.lock.lock()
                let alreadyExists = self.itemsCache.contains { $0.fileHash == hash }
                self.lock.unlock()
                if alreadyExists {
                    self.cleanupTemporaryCache()
                    DispatchQueue.main.async { completion(true, "Already in Media Vault") }
                    return
                }
            }
            
            try fileManager.copyItem(at: URL(fileURLWithPath: sourcePath), to: destURL)
            let attrs = try fileManager.attributesOfItem(atPath: destURL.path)
            let fileSize = (attrs[.size] as? Int64) ?? 0
            
            let item = MediaVaultItem(
                id: itemId,
                peerId: peerId,
                messageId: messageId,
                chatTitle: chatTitle,
                authorName: authorName,
                timestamp: timestamp,
                savedTimestamp: Int32(Date().timeIntervalSince1970),
                mediaType: detectedType,
                fileName: fileName,
                fileSize: fileSize,
                relativePath: relativePath,
                isFavorite: false,
                isOneTime: isOneTime,
                mimeType: mimeType,
                duration: duration,
                dimensions: dimensions,
                fileHash: hash
            )
            
            self.lock.lock()
            self.itemsCache.insert(item, at: 0)
            self.saveManifestLocked()
            self.lock.unlock()
            
            self.cleanupTemporaryCache()
            DispatchQueue.main.async {
                completion(true, nil)
            }
        } catch {
            self.cleanupTemporaryCache()
            DispatchQueue.main.async {
                completion(false, error.localizedDescription)
            }
        }
    }
    
    // MARK: - Direct File Import (Circle Studio & External Media)
    public func saveDirectFile(
        sourceURL: URL,
        fileName: String,
        mediaType: String,
        chatTitle: String,
        authorName: String,
        isOneTime: Bool,
        duration: Double? = nil,
        dimensions: String? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        self.queue.async {
            let fileManager = FileManager.default
            let itemId = UUID().uuidString
            let ext = (fileName as NSString).pathExtension
            let cleanExt = ext.isEmpty ? "mp4" : ext
            let destFileName = "\(itemId).\(cleanExt)"
            let relativePath = "items/\(destFileName)"
            let destURL = self.itemsDirectory.appendingPathComponent(destFileName)
            
            do {
                let hash = self.computeFileHash(url: sourceURL)
                if !hash.isEmpty {
                    self.lock.lock()
                    let alreadyExists = self.itemsCache.contains { $0.fileHash == hash }
                    self.lock.unlock()
                    if alreadyExists {
                        self.cleanupTemporaryCache()
                        DispatchQueue.main.async { completion(true, "Already in Media Vault") }
                        return
                    }
                }
                
                if fileManager.fileExists(atPath: destURL.path) {
                    try? fileManager.removeItem(at: destURL)
                }
                try fileManager.copyItem(at: sourceURL, to: destURL)
                let attrs = try fileManager.attributesOfItem(atPath: destURL.path)
                let fileSize = (attrs[.size] as? Int64) ?? 0
                
                let item = MediaVaultItem(
                    id: itemId,
                    peerId: 0,
                    messageId: 0,
                    chatTitle: chatTitle,
                    authorName: authorName,
                    timestamp: Int32(Date().timeIntervalSince1970),
                    savedTimestamp: Int32(Date().timeIntervalSince1970),
                    mediaType: mediaType,
                    fileName: fileName,
                    fileSize: fileSize,
                    relativePath: relativePath,
                    isFavorite: false,
                    isOneTime: isOneTime,
                    mimeType: mediaType == "circle" || mediaType == "video" ? "video/mp4" : "application/octet-stream",
                    duration: duration,
                    dimensions: dimensions,
                    fileHash: hash
                )
                
                self.lock.lock()
                self.itemsCache.insert(item, at: 0)
                self.saveManifestLocked()
                self.lock.unlock()
                
                self.cleanupTemporaryCache()
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                self.cleanupTemporaryCache()
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Query & Filter Items
    public func getItems(
        typeFilter: String? = nil,
        searchQuery: String? = nil,
        favoritesOnly: Bool = false
    ) -> [MediaVaultItem] {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        return self.itemsCache.filter { item in
            if favoritesOnly && !item.isFavorite {
                return false
            }
            if let type = typeFilter, !type.isEmpty, type != "all" {
                if item.mediaType != type {
                    return false
                }
            }
            if let query = searchQuery, !query.isEmpty {
                let low = query.lowercased()
                let matchTitle = item.chatTitle.lowercased().contains(low)
                let matchAuthor = item.authorName.lowercased().contains(low)
                let matchFile = item.fileName.lowercased().contains(low)
                return matchTitle || matchAuthor || matchFile
            }
            return true
        }
    }
    
    // MARK: - Toggle Favorite
    public func toggleFavorite(id: String) -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        if let idx = self.itemsCache.firstIndex(where: { $0.id == id }) {
            self.itemsCache[idx].isFavorite.toggle()
            let newVal = self.itemsCache[idx].isFavorite
            self.saveManifestLocked()
            return newVal
        }
        return false
    }
    
    // MARK: - Delete Item
    public func deleteItem(id: String, completion: @escaping (Bool) -> Void) {
        self.queue.async {
            self.lock.lock()
            guard let idx = self.itemsCache.firstIndex(where: { $0.id == id }) else {
                self.lock.unlock()
                DispatchQueue.main.async { completion(false) }
                return
            }
            let item = self.itemsCache.remove(at: idx)
            self.saveManifestLocked()
            self.lock.unlock()
            
            let fileURL = self.vaultDirectory.appendingPathComponent(item.relativePath)
            try? FileManager.default.removeItem(at: fileURL)
            
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    // MARK: - Clear Vault
    public func clearVault(keepFavorites: Bool = true, completion: @escaping () -> Void) {
        self.queue.async {
            self.lock.lock()
            var toDelete: [MediaVaultItem] = []
            var toKeep: [MediaVaultItem] = []
            
            for item in self.itemsCache {
                if keepFavorites && item.isFavorite {
                    toKeep.append(item)
                } else {
                    toDelete.append(item)
                }
            }
            self.itemsCache = toKeep
            self.saveManifestLocked()
            self.lock.unlock()
            
            let fileManager = FileManager.default
            for item in toDelete {
                let fileURL = self.vaultDirectory.appendingPathComponent(item.relativePath)
                try? fileManager.removeItem(at: fileURL)
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    // MARK: - Storage Analytics
    public func totalStorageBytes() -> Int64 {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.itemsCache.reduce(0) { $0 + $1.fileSize }
    }
    
    public func formattedStorageSize() -> String {
        let bytes = Double(self.totalStorageBytes())
        if bytes < 1024 {
            return "\(Int(bytes)) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024.0)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", bytes / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB", bytes / (1024.0 * 1024.0 * 1024.0))
        }
    }
    
    // MARK: - Retention Policy TTL Enforcement
    public func enforceRetentionTTL(days: Int) {
        guard days > 0 else { return }
        self.queue.async {
            let cutoff = Int32(Date().timeIntervalSince1970) - Int32(days * 86400)
            self.lock.lock()
            var toKeep: [MediaVaultItem] = []
            var toDelete: [MediaVaultItem] = []
            
            for item in self.itemsCache {
                if item.isFavorite || item.savedTimestamp >= cutoff {
                    toKeep.append(item)
                } else {
                    toDelete.append(item)
                }
            }
            self.itemsCache = toKeep
            self.saveManifestLocked()
            self.lock.unlock()
            
            let fileManager = FileManager.default
            for item in toDelete {
                let fileURL = self.vaultDirectory.appendingPathComponent(item.relativePath)
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Export to Camera Roll
    public func exportToCameraRoll(item: MediaVaultItem, completion: @escaping (Bool, String?) -> Void) {
        let fileURL = self.resolveItemURL(item: item)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(false, "File not found on disk")
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    completion(false, "Photos permission denied")
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                if item.mediaType == "video" || item.mediaType == "circle" {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                } else if item.mediaType == "photo" {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                } else {
                    // For files/audio, export via Photos is not applicable, save to Files
                }
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        completion(false, error?.localizedDescription ?? "Export failed")
                    }
                }
            })
        }
    }
}
