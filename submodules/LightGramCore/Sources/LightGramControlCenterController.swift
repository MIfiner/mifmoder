import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI
import AppBundle

// MARK: - Reactive State
private struct LightGramControlCenterState: Equatable {
    var isGhostModeEnabled: Bool
    var suppressReadHistory: Bool
    var suppressTyping: Bool
    var suppressStoryViews: Bool
    var markAsReadOnReply: Bool
    
    var isSpyModeEnabled: Bool
    var saveDeletedMessages: Bool
    var saveEditHistory: Bool
    
    var nativeNotificationsEnabled: Bool
    var biometricLockMediaVault: Bool
    
    init() {
        let s = LightGramSettings.shared
        self.isGhostModeEnabled = s.isGhostModeEnabled
        self.suppressReadHistory = s.suppressReadHistory
        self.suppressTyping = s.suppressTyping
        self.suppressStoryViews = s.suppressStoryViews
        self.markAsReadOnReply = s.markAsReadOnReply
        
        self.isSpyModeEnabled = s.isSpyModeEnabled
        self.saveDeletedMessages = s.saveDeletedMessages
        self.saveEditHistory = s.saveEditHistory
        
        self.nativeNotificationsEnabled = s.nativeNotificationsEnabled
        self.biometricLockMediaVault = s.biometricLockMediaVault
    }
}

// MARK: - Arguments
private final class LightGramControlCenterArguments {
    let context: AccountContext?
    let push: (ViewController) -> Void
    let present: (ViewController) -> Void
    let updateState: ((inout LightGramControlCenterState) -> Void) -> Void
    
    init(
        context: AccountContext?,
        push: @escaping (ViewController) -> Void,
        present: @escaping (ViewController) -> Void,
        updateState: @escaping ((inout LightGramControlCenterState) -> Void) -> Void
    ) {
        self.context = context
        self.push = push
        self.present = present
        self.updateState = updateState
    }
}

// MARK: - Section IDs
private enum LightGramSection: Int32 {
    case quickActions = 0
    case ghostMode = 1
    case spyMode = 2
    case notifications = 3
    case customization = 4
    case advanced = 5
}

// MARK: - Entries
private enum LightGramEntry: ItemListNodeEntry {
    // Quick Actions
    case quickActionsHeader
    case oneTimeVault
    case favoritesVault
    case allMediaVault
    case statisticsCenter
    case circleStudio
    case clearCacheAction
    
    // Ghost Mode
    case ghostHeader
    case ghostMaster(Bool)
    case ghostNoReadReceipts(Bool)
    case ghostHideTyping(Bool)
    case ghostStealthStories(Bool)
    case ghostMarkOnReply(Bool)
    case ghostFooter
    
    // Spy Mode
    case spyHeader
    case spyMaster(Bool)
    case spySaveDeleted(Bool)
    case spySaveEdits(Bool)
    case spyOpenArchive
    case spyFooter
    
    // Notifications & Badges
    case notificationsHeader
    case nativeNotifications(Bool)
    case biometricLockVault(Bool)
    case resetBadgeAction
    case notificationsFooter
    
    // Customization
    case customizationHeader
    case logosAndThemes
    case customizationFooter
    
    // Advanced & Tools
    case advancedHeader
    case privacyCenter
    case smartFolders
    case notes
    case botManager
    case diagnostics
    case advancedFooter
    
    var section: ItemListSectionId {
        switch self {
        case .quickActionsHeader, .oneTimeVault, .favoritesVault, .allMediaVault, .statisticsCenter, .circleStudio, .clearCacheAction:
            return LightGramSection.quickActions.rawValue
        case .ghostHeader, .ghostMaster, .ghostNoReadReceipts, .ghostHideTyping, .ghostStealthStories, .ghostMarkOnReply, .ghostFooter:
            return LightGramSection.ghostMode.rawValue
        case .spyHeader, .spyMaster, .spySaveDeleted, .spySaveEdits, .spyOpenArchive, .spyFooter:
            return LightGramSection.spyMode.rawValue
        case .notificationsHeader, .nativeNotifications, .biometricLockVault, .resetBadgeAction, .notificationsFooter:
            return LightGramSection.notifications.rawValue
        case .customizationHeader, .logosAndThemes, .customizationFooter:
            return LightGramSection.customization.rawValue
        case .advancedHeader, .privacyCenter, .smartFolders, .notes, .botManager, .diagnostics, .advancedFooter:
            return LightGramSection.advanced.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .quickActionsHeader: return 0
        case .oneTimeVault: return 1
        case .favoritesVault: return 2
        case .allMediaVault: return 3
        case .statisticsCenter: return 4
        case .circleStudio: return 5
        case .clearCacheAction: return 6
            
        case .ghostHeader: return 10
        case .ghostMaster: return 11
        case .ghostNoReadReceipts: return 12
        case .ghostHideTyping: return 13
        case .ghostStealthStories: return 14
        case .ghostMarkOnReply: return 15
        case .ghostFooter: return 16
            
        case .spyHeader: return 20
        case .spyMaster: return 21
        case .spySaveDeleted: return 22
        case .spySaveEdits: return 23
        case .spyOpenArchive: return 24
        case .spyFooter: return 25
            
        case .notificationsHeader: return 30
        case .nativeNotifications: return 31
        case .biometricLockVault: return 32
        case .resetBadgeAction: return 33
        case .notificationsFooter: return 34
            
        case .customizationHeader: return 40
        case .logosAndThemes: return 41
        case .customizationFooter: return 42
            
        case .advancedHeader: return 50
        case .privacyCenter: return 51
        case .smartFolders: return 52
        case .notes: return 53
        case .botManager: return 54
        case .diagnostics: return 55
        case .advancedFooter: return 56
        }
    }
    
    static func <(lhs: LightGramEntry, rhs: LightGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        guard let args = arguments as? LightGramControlCenterArguments else {
            return ItemListTextItem(presentationData: presentationData, text: .plain(""), sectionId: self.section)
        }
        
        switch self {
        // MARK: - Quick Actions
        case .quickActionsHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: LightGramStrings.tr("Dashboard_Title"),
                sectionId: self.section
            )
        case .oneTimeVault:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "👆  \(LightGramStrings.tr("Dashboard_OneTime"))",
                label: "VO Vault",
                sectionId: self.section,
                style: .blocks,
                action: {
                    if let context = args.context {
                        args.push(LightGramMediaVaultController(context: context, initialFilter: "onetime"))
                    }
                }
            )
        case .favoritesVault:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "❤️  \(LightGramStrings.tr("Dashboard_Favorites"))",
                label: "Favorites",
                sectionId: self.section,
                style: .blocks,
                action: {
                    if let context = args.context {
                        args.push(LightGramMediaVaultController(context: context, initialFilter: "favorites"))
                    }
                }
            )
        case .allMediaVault:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "💾  \(LightGramStrings.tr("Dashboard_Vault"))",
                label: "Face ID",
                sectionId: self.section,
                style: .blocks,
                action: {
                    if let context = args.context {
                        args.push(LightGramMediaVaultController(context: context, initialFilter: "all"))
                    }
                }
            )
        case .statisticsCenter:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "📊  \(LightGramStrings.tr("Dashboard_Stats"))",
                label: "Analytics",
                sectionId: self.section,
                style: .blocks,
                action: {
                    if let context = args.context {
                        args.push(LightGramStatisticsController(context: context))
                    }
                }
            )
        case .circleStudio:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "⭕  \(LightGramStrings.tr("CircleStudio_Title"))",
                label: "1:1 Video",
                sectionId: self.section,
                style: .blocks,
                action: {
                    if let context = args.context {
                        args.push(LightGramCircleStudioController(context: context))
                    }
                }
            )
        case .clearCacheAction:
            return ItemListActionItem(
                presentationData: presentationData,
                title: "🗑  \(LightGramStrings.tr("Dashboard_Delete"))",
                kind: .destructive,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    LightGramMediaVaultManager.shared.cleanupTemporaryCache()
                    LightGramSettings.shared.manualBadgeCount = 0
                    LightGramDesignSystem.Haptics.notification(.success)
                    if let context = args.context {
                        let alert = textAlertController(
                            context: context,
                            title: LightGramStrings.tr("Dashboard_Delete"),
                            text: LightGramStrings.tr("MediaCenter_CacheCleared"),
                            actions: [
                                TextAlertAction(type: .defaultAction, title: LightGramStrings.tr("OK"), action: {})
                            ]
                        )
                        args.present(alert)
                    }
                }
            )
            
        // MARK: - Ghost Mode
        case .ghostHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: LightGramStrings.tr("GhostMode_Header"),
                sectionId: self.section
            )
        case let .ghostMaster(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "👻  \(LightGramStrings.tr("GhostMode_Master"))",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.isGhostModeEnabled = val
                    LightGramDesignSystem.Haptics.impact(.medium)
                    args.updateState { $0.isGhostModeEnabled = val }
                }
            )
        case let .ghostNoReadReceipts(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: LightGramStrings.tr("GhostMode_NoReadReceipts"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.suppressReadHistory = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.suppressReadHistory = val }
                }
            )
        case let .ghostHideTyping(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: LightGramStrings.tr("GhostMode_HideTyping"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.suppressTyping = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.suppressTyping = val }
                }
            )
        case let .ghostStealthStories(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: LightGramStrings.tr("GhostMode_StealthStory"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.suppressStoryViews = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.suppressStoryViews = val }
                }
            )
        case let .ghostMarkOnReply(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: LightGramStrings.tr("GhostMode_MarkOnReply"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.markAsReadOnReply = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.markAsReadOnReply = val }
                }
            )
        case .ghostFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(LightGramStrings.tr("GhostMode_Master_Desc")),
                sectionId: self.section
            )
            
        // MARK: - Spy Mode
        case .spyHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: LightGramStrings.tr("SpyMode_Header"),
                sectionId: self.section
            )
        case let .spyMaster(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "🕵️‍♂️  \(LightGramStrings.tr("SpyMode_Master"))",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.isSpyModeEnabled = val
                    LightGramDesignSystem.Haptics.impact(.medium)
                    args.updateState { $0.isSpyModeEnabled = val }
                }
            )
        case let .spySaveDeleted(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: LightGramStrings.tr("SpyMode_SaveDeleted"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.saveDeletedMessages = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.saveDeletedMessages = val }
                }
            )
        case let .spySaveEdits(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: LightGramStrings.tr("SpyMode_SaveEdits"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.saveEditHistory = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.saveEditHistory = val }
                }
            )
        case .spyOpenArchive:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "🗄  \(LightGramStrings.tr("SpyMode_OpenArchive"))",
                label: "Archive",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.push(LightGramSpyArchiveController())
                }
            )
        case .spyFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(LightGramStrings.tr("SpyMode_Master_Desc")),
                sectionId: self.section
            )
            
        // MARK: - Notifications & Media Protection
        case .notificationsHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: "NOTIFICATIONS & PROTECTION",
                sectionId: self.section
            )
        case let .nativeNotifications(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "🔔  Native Push Notifications",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.nativeNotificationsEnabled = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.nativeNotificationsEnabled = val }
                }
            )
        case let .biometricLockVault(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "🔒  Face ID Vault Protection",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    LightGramSettings.shared.biometricLockMediaVault = val
                    LightGramDesignSystem.Haptics.selection()
                    args.updateState { $0.biometricLockMediaVault = val }
                }
            )
        case .resetBadgeAction:
            return ItemListActionItem(
                presentationData: presentationData,
                title: "Reset Badge Count to 0",
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    LightGramSettings.shared.manualBadgeCount = 0
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    LightGramDesignSystem.Haptics.notification(.success)
                    if let context = args.context {
                        let alert = textAlertController(
                            context: context,
                            title: "Badge Reset",
                            text: "Application icon badge count has been reset to 0.",
                            actions: [
                                TextAlertAction(type: .defaultAction, title: LightGramStrings.tr("OK"), action: {})
                            ]
                        )
                        args.present(alert)
                    }
                }
            )
        case .notificationsFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("Push notifications run locally via APNs. Vault encryption and badge count can be managed manually."),
                sectionId: self.section
            )
            
        // MARK: - Customization
        case .customizationHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: LightGramStrings.tr("Logos_Header"),
                sectionId: self.section
            )
        case .logosAndThemes:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "🎨  \(LightGramStrings.tr("Logos_Title"))",
                label: "AMOLED Amber",
                sectionId: self.section,
                style: .blocks,
                action: {
                    if let context = args.context {
                        args.push(LightGramLogosController(context: context))
                    }
                }
            )
        case .customizationFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(LightGramStrings.tr("Logos_Footer")),
                sectionId: self.section
            )
            
        // MARK: - Advanced Tools
        case .advancedHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: "ADVANCED TOOLS & PRIVACY",
                sectionId: self.section
            )
        case .privacyCenter:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "🛡  \(LightGramStrings.tr("PrivacyCenter_Title"))",
                label: "Face ID",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.push(LightGramPrivacyCenterController())
                }
            )
        case .smartFolders:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "📁  \(LightGramStrings.tr("SmartFolders_Title"))",
                label: "Folders",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.push(LightGramSmartFoldersController())
                }
            )
        case .notes:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "📝  \(LightGramStrings.tr("Notes_Title"))",
                label: "Saved Notes",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.push(LightGramNotesController())
                }
            )
        case .botManager:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "🤖  \(LightGramStrings.tr("BotManager_Title"))",
                label: "Bots",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.push(LightGramBotManagerController())
                }
            )
        case .diagnostics:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "📶  Network Diagnostics",
                label: "DC Ping RTT",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.push(LightGramNetworkDiagnosticsController())
                }
            )
        case .advancedFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("LightGram Personal Edition v2.0 (Build 131945) — iPhone 13 mini"),
                sectionId: self.section
            )
        }
    }
}

// MARK: - Entries Builder
private func lightGramControlCenterEntries(state: LightGramControlCenterState) -> [LightGramEntry] {
    var entries: [LightGramEntry] = []
    
    // Quick Actions
    entries.append(.quickActionsHeader)
    entries.append(.oneTimeVault)
    entries.append(.favoritesVault)
    entries.append(.allMediaVault)
    entries.append(.statisticsCenter)
    entries.append(.circleStudio)
    entries.append(.clearCacheAction)
    
    // Ghost Mode
    entries.append(.ghostHeader)
    entries.append(.ghostMaster(state.isGhostModeEnabled))
    if state.isGhostModeEnabled {
        entries.append(.ghostNoReadReceipts(state.suppressReadHistory))
        entries.append(.ghostHideTyping(state.suppressTyping))
        entries.append(.ghostStealthStories(state.suppressStoryViews))
        entries.append(.ghostMarkOnReply(state.markAsReadOnReply))
    }
    entries.append(.ghostFooter)
    
    // Spy Mode
    entries.append(.spyHeader)
    entries.append(.spyMaster(state.isSpyModeEnabled))
    if state.isSpyModeEnabled {
        entries.append(.spySaveDeleted(state.saveDeletedMessages))
        entries.append(.spySaveEdits(state.saveEditHistory))
        entries.append(.spyOpenArchive)
    }
    entries.append(.spyFooter)
    
    // Notifications & Protection
    entries.append(.notificationsHeader)
    entries.append(.nativeNotifications(state.nativeNotificationsEnabled))
    entries.append(.biometricLockVault(state.biometricLockMediaVault))
    entries.append(.resetBadgeAction)
    entries.append(.notificationsFooter)
    
    // Customization
    entries.append(.customizationHeader)
    entries.append(.logosAndThemes)
    entries.append(.customizationFooter)
    
    // Advanced & Tools
    entries.append(.advancedHeader)
    entries.append(.privacyCenter)
    entries.append(.smartFolders)
    entries.append(.notes)
    entries.append(.botManager)
    entries.append(.diagnostics)
    entries.append(.advancedFooter)
    
    return entries
}

// MARK: - Factory Function & Controller
public func lightGramControlCenterController(context: AccountContext? = nil) -> ViewController {
    var pushImpl: ((ViewController) -> Void)?
    var presentImpl: ((ViewController) -> Void)?
    
    let stateValue = Atomic(value: LightGramControlCenterState())
    let statePromise = ValuePromise<LightGramControlCenterState>(stateValue.with { $0 }, ignoreRepeated: true)
    
    let updateState: ((inout LightGramControlCenterState) -> Void) -> Void = { f in
        let updated = stateValue.modify { current in
            var mod = current
            f(&mod)
            return mod
        }
        statePromise.set(updated)
    }
    
    let arguments = LightGramControlCenterArguments(
        context: context,
        push: { c in pushImpl?(c) },
        present: { c in presentImpl?(c) },
        updateState: updateState
    )
    
    let presentationData: ItemListPresentationData
    let updatedPresentationData: Signal<ItemListPresentationData, NoError>
    
    if let context = context {
        let pd = context.sharedContext.currentPresentationData.with { $0 }
        presentationData = ItemListPresentationData(pd)
        updatedPresentationData = context.sharedContext.presentationData |> map(ItemListPresentationData.init(_:))
    } else {
        let pd = defaultPresentationData()
        presentationData = ItemListPresentationData(pd)
        updatedPresentationData = .single(presentationData)
    }
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, Any)), NoError> = combineLatest(
        queue: .mainQueue(),
        updatedPresentationData,
        statePromise.get()
    )
    |> map { pData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: pData,
            title: .text(LightGramStrings.tr("LightGram")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: pData.strings.Common_Back),
            animateChanges: true
        )
        let listState = ItemListNodeState(
            presentationData: pData,
            entries: lightGramControlCenterEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }
    
    let controller: ItemListController
    if let context = context {
        controller = ItemListController(context: context, state: signal)
    } else {
        controller = ItemListController(
            presentationData: presentationData,
            updatedPresentationData: updatedPresentationData,
            state: signal,
            tabBarItem: nil
        )
    }
    
    pushImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    presentImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}

public func LightGramControlCenterController(context: AccountContext? = nil) -> ViewController {
    return lightGramControlCenterController(context: context)
}
