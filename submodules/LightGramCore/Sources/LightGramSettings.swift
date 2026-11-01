import Foundation
import UIKit
import SwiftSignalKit

public final class LightGramSettings {
    public static let shared = LightGramSettings()
    
    private let userDefaults: UserDefaults
    private let queue = DispatchQueue(label: "site.lightgram.settings.queue", attributes: .concurrent)
    
    private enum Keys {
        static let ghostModeEnabled = "lightgram_ghost_mode_enabled"
        static let suppressReadHistory = "lightgram_suppress_read_history"
        static let suppressTyping = "lightgram_suppress_typing"
        static let suppressStoryViews = "lightgram_suppress_story_views"
        static let markAsReadOnReply = "lightgram_mark_as_read_on_reply"
        
        static let spyModeEnabled = "lightgram_spy_mode_enabled"
        static let saveDeletedMessages = "lightgram_save_deleted_messages"
        static let saveEditHistory = "lightgram_save_edit_history"
        static let retentionDaysTTL = "lightgram_retention_days_ttl"
        
        static let biometricLockArchive = "lightgram_biometric_lock_archive"
        static let forwardWithoutQuoting = "lightgram_forward_without_quoting"
        static let smartFiltersEnabled = "lightgram_smart_filters_enabled"
        static let activeFilterIndex = "lightgram_active_filter_index"
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
        get { userDefaults.bool(forKey: Keys.ghostModeEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.ghostModeEnabled) }
    }
    
    public var suppressReadHistory: Bool {
        get { isGhostModeEnabled && userDefaults.bool(forKey: Keys.suppressReadHistory) }
        set { userDefaults.set(newValue, forKey: Keys.suppressReadHistory) }
    }
    
    public var suppressTyping: Bool {
        get { isGhostModeEnabled && userDefaults.bool(forKey: Keys.suppressTyping) }
        set { userDefaults.set(newValue, forKey: Keys.suppressTyping) }
    }
    
    public var suppressStoryViews: Bool {
        get { isGhostModeEnabled && userDefaults.bool(forKey: Keys.suppressStoryViews) }
        set { userDefaults.set(newValue, forKey: Keys.suppressStoryViews) }
    }
    
    public var markAsReadOnReply: Bool {
        get { userDefaults.bool(forKey: Keys.markAsReadOnReply) }
        set { userDefaults.set(newValue, forKey: Keys.markAsReadOnReply) }
    }
    
    // MARK: - Spy Mode Properties
    public var isSpyModeEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.spyModeEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.spyModeEnabled) }
    }
    
    public var saveDeletedMessages: Bool {
        get { isSpyModeEnabled && userDefaults.bool(forKey: Keys.saveDeletedMessages) }
        set { userDefaults.set(newValue, forKey: Keys.saveDeletedMessages) }
    }
    
    public var saveEditHistory: Bool {
        get { isSpyModeEnabled && userDefaults.bool(forKey: Keys.saveEditHistory) }
        set { userDefaults.set(newValue, forKey: Keys.saveEditHistory) }
    }
    
    public var retentionDaysTTL: Int {
        get { userDefaults.integer(forKey: Keys.retentionDaysTTL) }
        set { userDefaults.set(newValue, forKey: Keys.retentionDaysTTL) }
    }
    
    // MARK: - Privacy & Features Properties
    public var biometricLockArchive: Bool {
        get { userDefaults.bool(forKey: Keys.biometricLockArchive) }
        set { userDefaults.set(newValue, forKey: Keys.biometricLockArchive) }
    }
    
    public var forwardWithoutQuoting: Bool {
        get { userDefaults.bool(forKey: Keys.forwardWithoutQuoting) }
        set { userDefaults.set(newValue, forKey: Keys.forwardWithoutQuoting) }
    }
    
    public var smartFiltersEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.smartFiltersEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.smartFiltersEnabled) }
    }
    
    public var activeFilterIndex: Int {
        get { userDefaults.integer(forKey: Keys.activeFilterIndex) }
        set { userDefaults.set(newValue, forKey: Keys.activeFilterIndex) }
    }
    
    // MARK: - LightGram Colors
    public static let signatureYellowAccent = UIColor(rgb: 0xEDB400)
    public static let deepGraphiteBackground = UIColor(rgb: 0x121214)
    public static let oledBlackBackground = UIColor(rgb: 0x000000)
    public static let cardSurfaceColor = UIColor(rgb: 0x1C1C1E)
}
