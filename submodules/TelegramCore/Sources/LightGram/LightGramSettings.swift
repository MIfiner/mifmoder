import Foundation
import SwiftSignalKit

public final class LightGramSettings {
    public static let shared = LightGramSettings()
    
    private let userDefaults: UserDefaults
    private let lock = NSLock()
    
    public enum Keys {
        public static let ghostModeEnabled = "lightgram_ghost_mode_enabled"
        public static let suppressReadHistory = "lightgram_suppress_read_history"
        public static let suppressTyping = "lightgram_suppress_typing"
        public static let suppressStoryViews = "lightgram_suppress_story_views"
        public static let markAsReadOnReply = "lightgram_mark_as_read_on_reply"
        
        public static let spyModeEnabled = "lightgram_spy_mode_enabled"
        public static let saveDeletedMessages = "lightgram_save_deleted_messages"
        public static let saveEditHistory = "lightgram_save_edit_history"
        public static let retentionDaysTTL = "lightgram_retention_days_ttl"
        
        public static let biometricLockArchive = "lightgram_biometric_lock_archive"
        public static let forwardWithoutQuoting = "lightgram_forward_without_quoting"
        public static let smartFiltersEnabled = "lightgram_smart_filters_enabled"
        public static let activeFilterIndex = "lightgram_active_filter_index"
    }
    
    public init() {
        let bundleId = Bundle.main.bundleIdentifier ?? "site.lightgram.ios"
        let groupName = "group.\(bundleId)"
        if let sharedDefaults = UserDefaults(suiteName: groupName) {
            self.userDefaults = sharedDefaults
        } else if let fallbackDefaults = UserDefaults(suiteName: "group.site.lightgram.ios") {
            self.userDefaults = fallbackDefaults
        } else {
            self.userDefaults = UserDefaults.standard
        }
        
        // Register default initial values
        self.userDefaults.register(defaults: [
            Keys.ghostModeEnabled: false,
            Keys.suppressReadHistory: false,
            Keys.suppressTyping: false,
            Keys.suppressStoryViews: false,
            Keys.markAsReadOnReply: true,
            Keys.spyModeEnabled: true,
            Keys.saveDeletedMessages: true,
            Keys.saveEditHistory: true,
            Keys.retentionDaysTTL: 30,
            Keys.biometricLockArchive: false,
            Keys.forwardWithoutQuoting: false,
            Keys.smartFiltersEnabled: true,
            Keys.activeFilterIndex: 0
        ])
    }
    
    // MARK: - Ghost Mode Properties
    public var isGhostModeEnabled: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.ghostModeEnabled)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.ghostModeEnabled)
            self.lock.unlock()
        }
    }
    
    public var suppressReadHistory: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.ghostModeEnabled) && self.userDefaults.bool(forKey: Keys.suppressReadHistory)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.suppressReadHistory)
            self.lock.unlock()
        }
    }
    
    public var suppressTyping: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.ghostModeEnabled) && self.userDefaults.bool(forKey: Keys.suppressTyping)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.suppressTyping)
            self.lock.unlock()
        }
    }
    
    public var suppressStoryViews: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.ghostModeEnabled) && self.userDefaults.bool(forKey: Keys.suppressStoryViews)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.suppressStoryViews)
            self.lock.unlock()
        }
    }
    
    public var markAsReadOnReply: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.markAsReadOnReply)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.markAsReadOnReply)
            self.lock.unlock()
        }
    }
    
    // MARK: - Spy Mode Properties
    public var isSpyModeEnabled: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.spyModeEnabled)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.spyModeEnabled)
            self.lock.unlock()
        }
    }
    
    public var saveDeletedMessages: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.spyModeEnabled) && self.userDefaults.bool(forKey: Keys.saveDeletedMessages)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.saveDeletedMessages)
            self.lock.unlock()
        }
    }
    
    public var saveEditHistory: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.spyModeEnabled) && self.userDefaults.bool(forKey: Keys.saveEditHistory)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.saveEditHistory)
            self.lock.unlock()
        }
    }
    
    public var retentionDaysTTL: Int {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.integer(forKey: Keys.retentionDaysTTL)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.retentionDaysTTL)
            self.lock.unlock()
        }
    }
    
    // MARK: - Privacy & Features Properties
    public var biometricLockArchive: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.biometricLockArchive)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.biometricLockArchive)
            self.lock.unlock()
        }
    }
    
    public var forwardWithoutQuoting: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.forwardWithoutQuoting)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.forwardWithoutQuoting)
            self.lock.unlock()
        }
    }
    
    public var smartFiltersEnabled: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.bool(forKey: Keys.smartFiltersEnabled)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.smartFiltersEnabled)
            self.lock.unlock()
        }
    }
    
    public var activeFilterIndex: Int {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.userDefaults.integer(forKey: Keys.activeFilterIndex)
        }
        set {
            self.lock.lock()
            self.userDefaults.set(newValue, forKey: Keys.activeFilterIndex)
            self.lock.unlock()
        }
    }
}
