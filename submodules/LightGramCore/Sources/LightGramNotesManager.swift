import Foundation
import UIKit
import TelegramCore

public struct LightGramPersonalNote: Codable, Equatable {
    public let id: String
    public let peerId: Int64
    public let messageId: Int32
    public let chatTitle: String
    public let authorName: String
    public let originalText: String
    public var noteText: String
    public let createdAt: Int32
    public var category: String
    
    public init(peerId: Int64, messageId: Int32, chatTitle: String, authorName: String, originalText: String, noteText: String, category: String = "General") {
        self.id = UUID().uuidString
        self.peerId = peerId
        self.messageId = messageId
        self.chatTitle = chatTitle
        self.authorName = authorName
        self.originalText = originalText
        self.noteText = noteText
        self.createdAt = Int32(Date().timeIntervalSince1970)
        self.category = category
    }
}

public struct LightGramMessageReminder: Codable, Equatable {
    public let id: String
    public let peerId: Int64
    public let messageId: Int32
    public let chatTitle: String
    public let messageText: String
    public let remindAtTimestamp: Int32
    public var isCompleted: Bool
    
    public init(peerId: Int64, messageId: Int32, chatTitle: String, messageText: String, remindAtTimestamp: Int32) {
        self.id = UUID().uuidString
        self.peerId = peerId
        self.messageId = messageId
        self.chatTitle = chatTitle
        self.messageText = messageText
        self.remindAtTimestamp = remindAtTimestamp
        self.isCompleted = false
    }
}

public final class LightGramNotesManager {
    public static let shared = LightGramNotesManager()
    
    private let queue = DispatchQueue(label: "site.lightgram.notesmanager", qos: .utility)
    private let notesFile: URL
    private let remindersFile: URL
    
    private var notesCache: [LightGramPersonalNote] = []
    private var remindersCache: [LightGramMessageReminder] = []
    private let lock = NSLock()
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let containerDir = appSupport.appendingPathComponent("LightGramContainer", isDirectory: true)
        let notesDir = containerDir.appendingPathComponent("LightGramNotes", isDirectory: true)
        
        try? fileManager.createDirectory(at: notesDir, withIntermediateDirectories: true)
        self.notesFile = notesDir.appendingPathComponent("personal_notes.json")
        self.remindersFile = notesDir.appendingPathComponent("message_reminders.json")
        
        self.loadFromDisk()
    }
    
    private func loadFromDisk() {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            
            if let data = try? Data(contentsOf: self.notesFile),
               let notes = try? JSONDecoder().decode([LightGramPersonalNote].self, from: data) {
                self.lock.lock()
                self.notesCache = notes
                self.lock.unlock()
            }
            
            if let data = try? Data(contentsOf: self.remindersFile),
               let reminders = try? JSONDecoder().decode([LightGramMessageReminder].self, from: data) {
                self.lock.lock()
                self.remindersCache = reminders
                self.lock.unlock()
            }
        }
    }
    
    private func persistNotes() {
        self.lock.lock()
        let notes = self.notesCache
        self.lock.unlock()
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: self.notesFile, options: .atomic)
    }
    
    private func persistReminders() {
        self.lock.lock()
        let reminders = self.remindersCache
        self.lock.unlock()
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        try? data.write(to: self.remindersFile, options: .atomic)
    }
    
    // MARK: - Notes API
    public func addNote(peerId: Int64, messageId: Int32, chatTitle: String, authorName: String, originalText: String, noteText: String, category: String = "General", completion: (() -> Void)? = nil) {
        let note = LightGramPersonalNote(
            peerId: peerId,
            messageId: messageId,
            chatTitle: chatTitle,
            authorName: authorName,
            originalText: originalText,
            noteText: noteText,
            category: category
        )
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            self.notesCache.insert(note, at: 0)
            self.lock.unlock()
            self.persistNotes()
            DispatchQueue.main.async { completion?() }
        }
    }
    
    public func fetchAllNotes(completion: @escaping ([LightGramPersonalNote]) -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            self.lock.lock()
            let notes = self.notesCache
            self.lock.unlock()
            DispatchQueue.main.async { completion(notes) }
        }
    }
    
    public func deleteNote(id: String, completion: (() -> Void)? = nil) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            self.notesCache.removeAll(where: { $0.id == id })
            self.lock.unlock()
            self.persistNotes()
            DispatchQueue.main.async { completion?() }
        }
    }
    
    // MARK: - Reminders API
    public func addReminder(peerId: Int64, messageId: Int32, chatTitle: String, messageText: String, remindAt: Date, completion: (() -> Void)? = nil) {
        let reminder = LightGramMessageReminder(
            peerId: peerId,
            messageId: messageId,
            chatTitle: chatTitle,
            messageText: messageText,
            remindAtTimestamp: Int32(remindAt.timeIntervalSince1970)
        )
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            self.remindersCache.insert(reminder, at: 0)
            self.lock.unlock()
            self.persistReminders()
            DispatchQueue.main.async { completion?() }
        }
    }
    
    public func fetchAllReminders(completion: @escaping ([LightGramMessageReminder]) -> Void) {
        self.queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            self.lock.lock()
            let reminders = self.remindersCache
            self.lock.unlock()
            DispatchQueue.main.async { completion(reminders) }
        }
    }
    
    public func toggleReminderCompleted(id: String, completion: (() -> Void)? = nil) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            if let index = self.remindersCache.firstIndex(where: { $0.id == id }) {
                self.remindersCache[index].isCompleted.toggle()
            }
            self.lock.unlock()
            self.persistReminders()
            DispatchQueue.main.async { completion?() }
        }
    }
    
    public func deleteReminder(id: String, completion: (() -> Void)? = nil) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            self.remindersCache.removeAll(where: { $0.id == id })
            self.lock.unlock()
            self.persistReminders()
            DispatchQueue.main.async { completion?() }
        }
    }
}
