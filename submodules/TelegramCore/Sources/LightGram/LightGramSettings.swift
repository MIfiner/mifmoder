import Foundation
import SwiftSignalKit

public final class LightGramSettings {
    public static let shared = LightGramSettings()
    
    public static let ghostModePromise = ValuePromise<Bool>(false, ignoreRepeated: true)
    
    private let userDefaults: UserDefaults
    private let settingsFileURL: URL
    private let lock = NSLock()
    private var memoryCache: [String: Any] = [:]
    
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
        self.userDefaults = UserDefaults.standard
        
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let containerDir = appSupport.appendingPathComponent("LightGramContainer", isDirectory: true)
        if !fileManager.fileExists(atPath: containerDir.path) {
            try? fileManager.createDirectory(at: containerDir, withIntermediateDirectories: true)
        }
        self.settingsFileURL = containerDir.appendingPathComponent("settings.json")
        
        // Initial defaults
        self.memoryCache = [
            Keys.ghostModeEnabled: false,
            Keys.suppressReadHistory: true,
            Keys.suppressTyping: true,
            Keys.suppressStoryViews: true,
            Keys.markAsReadOnReply: true,
            Keys.spyModeEnabled: true,
            Keys.saveDeletedMessages: true,
            Keys.saveEditHistory: true,
            Keys.retentionDaysTTL: 30,
            Keys.biometricLockArchive: false,
            Keys.forwardWithoutQuoting: false,
            Keys.smartFiltersEnabled: true,
            Keys.activeFilterIndex: 0
        ]
        
        self.userDefaults.register(defaults: self.memoryCache)
        
        // Load from disk JSON file if available
        if let data = try? Data(contentsOf: self.settingsFileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for (k, v) in json {
                self.memoryCache[k] = v
                self.userDefaults.set(v, forKey: k)
            }
        } else {
            for (key, defaultValue) in self.memoryCache {
                if let existing = self.userDefaults.object(forKey: key) {
                    self.memoryCache[key] = existing
                } else {
                    self.userDefaults.set(defaultValue, forKey: key)
                }
            }
        }
        
        LightGramSettings.ghostModePromise.set(self.isGhostModeEnabled)
    }
    
    private func getBool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let val = self.memoryCache[key] as? Bool {
            return val
        }
        if let val = self.userDefaults.object(forKey: key) as? Bool {
            self.memoryCache[key] = val
            return val
        }
        return defaultValue
    }
    
    private func setBool(_ value: Bool, forKey key: String) {
        self.lock.lock()
        self.memoryCache[key] = value
        self.userDefaults.set(value, forKey: key)
        self.persistSettingsLocked()
        self.lock.unlock()
    }
    
    private func getInt(forKey key: String, default defaultValue: Int = 0) -> Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let val = self.memoryCache[key] as? Int {
            return val
        }
        if let val = self.userDefaults.object(forKey: key) as? Int {
            self.memoryCache[key] = val
            return val
        }
        return defaultValue
    }
    
    private func setInt(_ value: Int, forKey key: String) {
        self.lock.lock()
        self.memoryCache[key] = value
        self.userDefaults.set(value, forKey: key)
        self.persistSettingsLocked()
        self.lock.unlock()
    }
    
    private func persistSettingsLocked() {
        if let data = try? JSONSerialization.data(withJSONObject: self.memoryCache, options: [.prettyPrinted]) {
            try? data.write(to: self.settingsFileURL, options: .atomic)
        }
    }
    
    // MARK: - Ghost Mode Properties
    public var isGhostModeEnabled: Bool {
        get {
            return self.getBool(forKey: Keys.ghostModeEnabled, default: false)
        }
        set {
            self.setBool(newValue, forKey: Keys.ghostModeEnabled)
            LightGramSettings.ghostModePromise.set(newValue)
            NotificationCenter.default.post(name: NSNotification.Name("LightGramGhostModeChanged"), object: nil, userInfo: ["enabled": newValue])
        }
    }
    
    public var suppressReadHistory: Bool {
        get {
            return self.isGhostModeEnabled && self.getBool(forKey: Keys.suppressReadHistory, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.suppressReadHistory)
        }
    }
    
    public var suppressTyping: Bool {
        get {
            return self.isGhostModeEnabled && self.getBool(forKey: Keys.suppressTyping, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.suppressTyping)
        }
    }
    
    public var suppressStoryViews: Bool {
        get {
            return self.isGhostModeEnabled && self.getBool(forKey: Keys.suppressStoryViews, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.suppressStoryViews)
        }
    }
    
    public var markAsReadOnReply: Bool {
        get {
            return self.getBool(forKey: Keys.markAsReadOnReply, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.markAsReadOnReply)
        }
    }
    
    // MARK: - Spy Mode Properties
    public var isSpyModeEnabled: Bool {
        get {
            return self.getBool(forKey: Keys.spyModeEnabled, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.spyModeEnabled)
        }
    }
    
    public var saveDeletedMessages: Bool {
        get {
            return self.isSpyModeEnabled && self.getBool(forKey: Keys.saveDeletedMessages, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.saveDeletedMessages)
        }
    }
    
    public var saveEditHistory: Bool {
        get {
            return self.isSpyModeEnabled && self.getBool(forKey: Keys.saveEditHistory, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.saveEditHistory)
        }
    }
    
    public var retentionDaysTTL: Int {
        get {
            return self.getInt(forKey: Keys.retentionDaysTTL, default: 30)
        }
        set {
            self.setInt(newValue, forKey: Keys.retentionDaysTTL)
        }
    }
    
    // MARK: - Privacy & Features Properties
    public var biometricLockArchive: Bool {
        get {
            return self.getBool(forKey: Keys.biometricLockArchive, default: false)
        }
        set {
            self.setBool(newValue, forKey: Keys.biometricLockArchive)
        }
    }
    
    public var forwardWithoutQuoting: Bool {
        get {
            return self.getBool(forKey: Keys.forwardWithoutQuoting, default: false)
        }
        set {
            self.setBool(newValue, forKey: Keys.forwardWithoutQuoting)
        }
    }
    
    public var smartFiltersEnabled: Bool {
        get {
            return self.getBool(forKey: Keys.smartFiltersEnabled, default: true)
        }
        set {
            self.setBool(newValue, forKey: Keys.smartFiltersEnabled)
        }
    }
    
    public var activeFilterIndex: Int {
        get {
            return self.getInt(forKey: Keys.activeFilterIndex, default: 0)
        }
        set {
            self.setInt(newValue, forKey: Keys.activeFilterIndex)
        }
    }
}
