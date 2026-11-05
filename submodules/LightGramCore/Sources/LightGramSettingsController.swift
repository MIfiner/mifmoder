import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import AccountContext

public final class LightGramSettingsController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let context: AccountContext?
    
    public init(context: AccountContext? = nil) {
        self.context = context
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = LightGramStrings.tr("Settings")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNodeDidLoad()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = LightGramSettings.deepGraphiteBackground
        self.setupTableView()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topOffset = self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)
        self.tableView.frame = CGRect(x: 0, y: topOffset, width: layout.size.width, height: max(0, layout.size.height - topOffset))
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: layout.intrinsicInsets.bottom, right: 0)
    }
    
    private func setupTableView() {
        self.tableView.backgroundColor = LightGramSettings.deepGraphiteBackground
        self.tableView.separatorColor = UIColor(white: 0.25, alpha: 1.0)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableHeaderView = self.makeHeaderView()
        self.view.insertSubview(self.tableView, at: 0)
    }
    
    private func makeHeaderView() -> UIView {
        let screenWidth = UIScreen.main.bounds.width
        let header = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 160))
        
        let iconImageView = UIImageView()
        iconImageView.layer.cornerRadius = 20
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        
        if let icon = UIImage(named: "Simple-iTunesArtwork") ?? UIImage(named: "AppIcon") ?? UIImage(contentsOfFile: "/opt/lightgram/submodules/LightGramCore/Resources/Logos/01_LightGram_Amber.png") {
            iconImageView.image = icon
        } else {
            iconImageView.backgroundColor = UIColor(rgb: 0x1A1A1C)
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = LightGramStrings.tr("LightGram")
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = LightGramSettings.signatureYellowAccent
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Alternative Telegram iOS Client • Version 1.0"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 0.65, alpha: 1.0)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),
            iconImageView.heightAnchor.constraint(equalToConstant: 64),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16)
        ])
        
        return header
    }
    
    // MARK: - Sections & Rows
    private enum Section: Int, CaseIterable {
        case ghostMode
        case spyMode
        case notifications
        case privacyAndSecurity
        case smartFilters
        case tools
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .ghostMode: return LightGramStrings.tr("GhostMode_Header")
        case .spyMode: return LightGramStrings.tr("SpyMode_Header")
        case .notifications: return LightGramStrings.tr("notifications")
        case .privacyAndSecurity: return LightGramStrings.tr("PrivacyCenter_Header")
        case .smartFilters: return LightGramStrings.tr("SmartFolders_Header")
        case .tools: return LightGramStrings.tr("Settings")
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .ghostMode:
            return LightGramStrings.tr("GhostMode_Master_Desc")
        case .spyMode:
            return LightGramStrings.tr("SpyMode_Master_Desc")
        default:
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0 }
        switch s {
        case .ghostMode: return 5
        case .spyMode: return 5
        case .notifications: return 4
        case .privacyAndSecurity: return 2
        case .smartFilters: return 1
        case .tools: return 11
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = LightGramSettings.cardSurfaceColor
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = UIColor(white: 0.65, alpha: 1.0)
        
        switch s {
        case .ghostMode:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = LightGramStrings.tr("GhostMode_Master")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.isGhostModeEnabled) { [weak self] on in
                    LightGramSettings.shared.isGhostModeEnabled = on
                    self?.tableView.reloadData()
                }
                cell.accessoryView = sw
            case 1:
                cell.textLabel?.text = LightGramStrings.tr("GhostMode_NoReadReceipts")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.suppressReadHistory) { on in
                    LightGramSettings.shared.suppressReadHistory = on
                }
                sw.isEnabled = LightGramSettings.shared.isGhostModeEnabled
                cell.accessoryView = sw
            case 2:
                cell.textLabel?.text = LightGramStrings.tr("GhostMode_HideTyping")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.suppressTyping) { on in
                    LightGramSettings.shared.suppressTyping = on
                }
                sw.isEnabled = LightGramSettings.shared.isGhostModeEnabled
                cell.accessoryView = sw
            case 3:
                cell.textLabel?.text = LightGramStrings.tr("GhostMode_StealthStory")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.suppressStoryViews) { on in
                    LightGramSettings.shared.suppressStoryViews = on
                }
                sw.isEnabled = LightGramSettings.shared.isGhostModeEnabled
                cell.accessoryView = sw
            case 4:
                cell.textLabel?.text = LightGramStrings.tr("GhostMode_MarkOnReply")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.markAsReadOnReply) { on in
                    LightGramSettings.shared.markAsReadOnReply = on
                }
                cell.accessoryView = sw
            default: break
            }
            
        case .spyMode:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = LightGramStrings.tr("SpyMode_Master")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.isSpyModeEnabled) { [weak self] on in
                    LightGramSettings.shared.isSpyModeEnabled = on
                    self?.tableView.reloadData()
                }
                cell.accessoryView = sw
            case 1:
                cell.textLabel?.text = LightGramStrings.tr("SpyMode_SaveDeleted")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.saveDeletedMessages) { on in
                    LightGramSettings.shared.saveDeletedMessages = on
                }
                sw.isEnabled = LightGramSettings.shared.isSpyModeEnabled
                cell.accessoryView = sw
            case 2:
                cell.textLabel?.text = LightGramStrings.tr("SpyMode_SaveEdits")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.saveEditHistory) { on in
                    LightGramSettings.shared.saveEditHistory = on
                }
                sw.isEnabled = LightGramSettings.shared.isSpyModeEnabled
                cell.accessoryView = sw
            case 3:
                cell.textLabel?.text = LightGramStrings.tr("SpyMode_OpenArchive")
                cell.accessoryType = .disclosureIndicator
            case 4:
                cell.textLabel?.text = LightGramStrings.tr("PrivacyCenter_TTL")
                cell.detailTextLabel?.text = "\(LightGramSettings.shared.retentionDaysTTL) days"
            default: break
            }
            
        case .privacyAndSecurity:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = LightGramStrings.tr("PrivacyCenter_Biometrics")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.biometricLockArchive) { on in
                    LightGramSettings.shared.biometricLockArchive = on
                }
                cell.accessoryView = sw
            case 1:
                cell.textLabel?.text = "Forward Without Author Quote"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.forwardWithoutQuoting) { on in
                    LightGramSettings.shared.forwardWithoutQuoting = on
                }
                cell.accessoryView = sw
            default: break
            }
            
        case .notifications:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = LightGramStrings.tr("notifications")
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.nativeNotificationsEnabled) { on in
                    LightGramSettings.shared.nativeNotificationsEnabled = on
                }
                cell.accessoryView = sw
            case 1:
                cell.textLabel?.text = "APNs Categories"
                cell.detailTextLabel?.text = "Message, Call, Vault, Stats"
            case 2:
                cell.textLabel?.text = "Badge Counter"
                cell.detailTextLabel?.text = "\(LightGramSettings.shared.manualBadgeCount) (Tap to Reset)"
                cell.accessoryType = .disclosureIndicator
            case 3:
                cell.textLabel?.text = "Cache Limit (iPhone 13 mini)"
                cell.detailTextLabel?.text = "\(LightGramSettings.shared.maxDiskCacheLimitGB) GB"
            default: break
            }
            
        case .smartFilters:
            cell.textLabel?.text = LightGramStrings.tr("SmartFolders_Header")
            let sw = self.makeSwitch(isOn: LightGramSettings.shared.smartFiltersEnabled) { on in
                LightGramSettings.shared.smartFiltersEnabled = on
            }
            cell.accessoryView = sw
            
        case .tools:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Control Center (Dashboard)"
                cell.accessoryType = .disclosureIndicator
            case 1:
                cell.textLabel?.text = LightGramStrings.tr("Statistics_Title")
                cell.detailTextLabel?.text = "Dashboard & Charts"
                cell.accessoryType = .disclosureIndicator
            case 2:
                cell.textLabel?.text = LightGramStrings.tr("MediaVault_Title")
                cell.detailTextLabel?.text = LightGramMediaVaultManager.shared.formattedStorageSize()
                cell.accessoryType = .disclosureIndicator
            case 3:
                cell.textLabel?.text = LightGramStrings.tr("CircleStudio_Title")
                cell.detailTextLabel?.text = "1:1 Video Notes"
                cell.accessoryType = .disclosureIndicator
            case 4:
                cell.textLabel?.text = LightGramStrings.tr("Logos_Title")
                cell.detailTextLabel?.text = LightGramSettings.shared.activeLogoTheme.replacingOccurrences(of: "Icon", with: "")
                cell.accessoryType = .disclosureIndicator
            case 5:
                cell.textLabel?.text = LightGramStrings.tr("SmartFolders_Title")
                cell.accessoryType = .disclosureIndicator
            case 6:
                cell.textLabel?.text = LightGramStrings.tr("Notes_Title")
                cell.accessoryType = .disclosureIndicator
            case 7:
                cell.textLabel?.text = LightGramStrings.tr("MediaCenter_Title")
                cell.accessoryType = .disclosureIndicator
            case 8:
                cell.textLabel?.text = LightGramStrings.tr("PrivacyCenter_Title")
                cell.accessoryType = .disclosureIndicator
            case 9:
                cell.textLabel?.text = LightGramStrings.tr("BotManager_Title")
                cell.accessoryType = .disclosureIndicator
            case 10:
                cell.textLabel?.text = "Network Diagnostics"
                cell.detailTextLabel?.text = "NWConnection / DC 2"
                cell.accessoryType = .disclosureIndicator
            default: break
            }
        }
        
        return cell
    }
    
    private func makeSwitch(isOn: Bool, handler: @escaping (Bool) -> Void) -> UISwitch {
        let sw = UISwitch()
        sw.isOn = isOn
        sw.onTintColor = LightGramSettings.signatureYellowAccent
        let action = UIAction { [weak sw] _ in
            guard let sw = sw else { return }
            handler(sw.isOn)
        }
        sw.addAction(action, for: .valueChanged)
        return sw
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let s = Section(rawValue: indexPath.section) else { return }
        
        if s == .spyMode && indexPath.row == 3 {
            let archiveVC = LightGramSpyArchiveController()
            self.push(archiveVC)
        } else if s == .notifications && indexPath.row == 2 {
            LightGramSettings.shared.manualBadgeCount = 0
            LightGramDesignSystem.Haptics.impact(.medium)
            self.tableView.reloadData()
        } else if s == .tools {
            switch indexPath.row {
            case 0:
                self.push(LightGramControlCenterController(context: self.context))
            case 1:
                if let context = self.context {
                    self.push(LightGramStatisticsController(context: context))
                }
            case 2:
                if let context = self.context {
                    self.push(LightGramMediaVaultController(context: context))
                }
            case 3:
                if let context = self.context {
                    self.push(LightGramCircleStudioController(context: context))
                }
            case 4:
                if let context = self.context {
                    self.push(LightGramLogosController(context: context))
                }
            case 5:
                self.push(LightGramSmartFoldersController())
            case 6:
                self.push(LightGramNotesController())
            case 7:
                self.push(LightGramMediaCenterController())
            case 8:
                self.push(LightGramPrivacyCenterController())
            case 9:
                self.push(LightGramBotManagerController())
            case 10:
                self.push(LightGramNetworkDiagnosticsController())
            default: break
            }
        }
    }
}
