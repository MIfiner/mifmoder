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

// MARK: - Reactive State
private struct LightGramSettingsState: Equatable {
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
private final class LightGramSettingsArguments {
    let context: AccountContext?
    let push: (ViewController) -> Void
    let present: (ViewController) -> Void
    let updateState: ((inout LightGramSettingsState) -> Void) -> Void
    
    init(
        context: AccountContext?,
        push: @escaping (ViewController) -> Void,
        present: @escaping (ViewController) -> Void,
        updateState: @escaping ((inout LightGramSettingsState) -> Void) -> Void
    ) {
        self.context = context
        self.push = push
        self.present = present
        self.updateState = updateState
    }
}

// MARK: - Sections
private enum LightGramSettingsSection: Int32 {
    case ghostMode = 0
    case spyMode = 1
    case notifications = 2
    case tools = 3
}

// MARK: - Entries
private enum LightGramSettingsEntry: ItemListNodeEntry {
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
    
    // Notifications & Media
    case notificationsHeader
    case nativeNotifications(Bool)
    case biometricLockVault(Bool)
    case notificationsFooter
    
    // Tools & Control Center
    case toolsHeader
    case openControlCenter
    case logosAndThemes
    case toolsFooter
    
    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostMaster, .ghostNoReadReceipts, .ghostHideTyping, .ghostStealthStories, .ghostMarkOnReply, .ghostFooter:
            return LightGramSettingsSection.ghostMode.rawValue
        case .spyHeader, .spyMaster, .spySaveDeleted, .spySaveEdits, .spyOpenArchive, .spyFooter:
            return LightGramSettingsSection.spyMode.rawValue
        case .notificationsHeader, .nativeNotifications, .biometricLockVault, .notificationsFooter:
            return LightGramSettingsSection.notifications.rawValue
        case .toolsHeader, .openControlCenter, .logosAndThemes, .toolsFooter:
            return LightGramSettingsSection.tools.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .ghostHeader: return 0
        case .ghostMaster: return 1
        case .ghostNoReadReceipts: return 2
        case .ghostHideTyping: return 3
        case .ghostStealthStories: return 4
        case .ghostMarkOnReply: return 5
        case .ghostFooter: return 6
            
        case .spyHeader: return 10
        case .spyMaster: return 11
        case .spySaveDeleted: return 12
        case .spySaveEdits: return 13
        case .spyOpenArchive: return 14
        case .spyFooter: return 15
            
        case .notificationsHeader: return 20
        case .nativeNotifications: return 21
        case .biometricLockVault: return 22
        case .notificationsFooter: return 23
            
        case .toolsHeader: return 30
        case .openControlCenter: return 31
        case .logosAndThemes: return 32
        case .toolsFooter: return 33
        }
    }
    
    static func <(lhs: LightGramSettingsEntry, rhs: LightGramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        LightGramDiagnostics.shared.log("SETTINGS_RENDER_ITEM_BEGIN: \(self) [id=\(self.stableId)]")
        LightGramDiagnostics.shared.recordStage("SETTINGS_RENDER_ITEM_\(self.stableId)")
        defer {
            LightGramDiagnostics.shared.log("SETTINGS_RENDER_ITEM_END: \(self) [id=\(self.stableId)]")
        }
        guard let args = arguments as? LightGramSettingsArguments else {
            return ItemListTextItem(presentationData: presentationData, text: .plain(""), sectionId: self.section)
        }
        
        switch self {
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
        case .notificationsFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("Push notifications run locally via APNs."),
                sectionId: self.section
            )
            
        case .toolsHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: "TOOLS & DASHBOARD",
                sectionId: self.section
            )
        case .openControlCenter:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "⚡️  Control Center & Hub",
                label: "Dashboard",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.push(lightGramControlCenterController(context: args.context))
                }
            )
        case .logosAndThemes:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "🎨  \(LightGramStrings.tr("Logos_Title"))",
                label: "Themes",
                sectionId: self.section,
                style: .blocks,
                action: {
                    if let context = args.context {
                        args.push(LightGramLogosController(context: context))
                    }
                }
            )
        case .toolsFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("LightGram Personal Edition v2.0 (Build 131945)"),
                sectionId: self.section
            )
        }
    }
}

// MARK: - Entries Builder
private func lightGramSettingsEntries(state: LightGramSettingsState) -> [LightGramSettingsEntry] {
    var entries: [LightGramSettingsEntry] = []
    
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
    
    // Notifications
    entries.append(.notificationsHeader)
    entries.append(.nativeNotifications(state.nativeNotificationsEnabled))
    entries.append(.biometricLockVault(state.biometricLockMediaVault))
    entries.append(.notificationsFooter)
    
    // Tools
    entries.append(.toolsHeader)
    entries.append(.openControlCenter)
    entries.append(.logosAndThemes)
    entries.append(.toolsFooter)
    
    return entries
}

// MARK: - Factory Function & Controller
public func lightGramSettingsController(context: AccountContext? = nil) -> ViewController {
    var pushImpl: ((ViewController) -> Void)?
    var presentImpl: ((ViewController) -> Void)?
    
    let stateValue = Atomic(value: LightGramSettingsState())
    let statePromise = ValuePromise<LightGramSettingsState>(stateValue.with { $0 }, ignoreRepeated: true)
    
    let updateState: ((inout LightGramSettingsState) -> Void) -> Void = { f in
        let updated = stateValue.modify { current in
            var mod = current
            f(&mod)
            return mod
        }
        statePromise.set(updated)
    }
    
    let arguments = LightGramSettingsArguments(
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
            title: .text(LightGramStrings.tr("Settings")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: pData.strings.Common_Back),
            animateChanges: true
        )
        let listState = ItemListNodeState(
            presentationData: pData,
            entries: lightGramSettingsEntries(state: state),
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

public func LightGramSettingsController(context: AccountContext? = nil) -> ViewController {
    return lightGramSettingsController(context: context)
}
