import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore

public final class LightGramSettingsController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "LightGram V1"
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
        
        // Load app icon
        if let icon = UIImage(named: "Simple-iTunesArtwork") ?? UIImage(named: "AppIcon") {
            iconImageView.image = icon
        } else {
            iconImageView.backgroundColor = UIColor(rgb: 0x1A1A1C)
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = "LightGram V1"
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
        case .ghostMode: return "👻 Ghost Mode"
        case .spyMode: return "🕵️ Spy Mode & Anti-Recall"
        case .privacyAndSecurity: return "🔒 Privacy & Security"
        case .smartFilters: return "📁 Smart Filters & Navigation"
        case .tools: return "🛠️ Tools & Utilities"
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .ghostMode:
            return "Note: Telegram server automatically advances read status if you send an outgoing message in that chat."
        case .spyMode:
            return "Saved messages are stored in an encrypted local archive on this device."
        case .privacyAndSecurity:
            return "When Forward without author is enabled, quoted metadata is removed during message sharing."
        default:
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0 }
        switch s {
        case .ghostMode: return 5
        case .spyMode: return 5
        case .privacyAndSecurity: return 2
        case .smartFilters: return 1
        case .tools: return 2
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
                cell.textLabel?.text = "Enable Ghost Mode"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.isGhostModeEnabled) { [weak self] on in
                    LightGramSettings.shared.isGhostModeEnabled = on
                    self?.tableView.reloadData()
                }
                cell.accessoryView = sw
            case 1:
                cell.textLabel?.text = "Don't Send Read Receipts"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.suppressReadHistory) { on in
                    LightGramSettings.shared.suppressReadHistory = on
                }
                sw.isEnabled = LightGramSettings.shared.isGhostModeEnabled
                cell.accessoryView = sw
            case 2:
                cell.textLabel?.text = "Hide Typing Status"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.suppressTyping) { on in
                    LightGramSettings.shared.suppressTyping = on
                }
                sw.isEnabled = LightGramSettings.shared.isGhostModeEnabled
                cell.accessoryView = sw
            case 3:
                cell.textLabel?.text = "Stealth Story Views"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.suppressStoryViews) { on in
                    LightGramSettings.shared.suppressStoryViews = on
                }
                sw.isEnabled = LightGramSettings.shared.isGhostModeEnabled
                cell.accessoryView = sw
            case 4:
                cell.textLabel?.text = "Mark As Read On Reply"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.markAsReadOnReply) { on in
                    LightGramSettings.shared.markAsReadOnReply = on
                }
                cell.accessoryView = sw
            default: break
            }
            
        case .spyMode:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Enable Spy Mode"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.isSpyModeEnabled) { [weak self] on in
                    LightGramSettings.shared.isSpyModeEnabled = on
                    self?.tableView.reloadData()
                }
                cell.accessoryView = sw
            case 1:
                cell.textLabel?.text = "Save Deleted Messages"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.saveDeletedMessages) { on in
                    LightGramSettings.shared.saveDeletedMessages = on
                }
                sw.isEnabled = LightGramSettings.shared.isSpyModeEnabled
                cell.accessoryView = sw
            case 2:
                cell.textLabel?.text = "Save Edit History"
                let sw = self.makeSwitch(isOn: LightGramSettings.shared.saveEditHistory) { on in
                    LightGramSettings.shared.saveEditHistory = on
                }
                sw.isEnabled = LightGramSettings.shared.isSpyModeEnabled
                cell.accessoryView = sw
            case 3:
                cell.textLabel?.text = "Browse Spy Archive"
                cell.accessoryType = .disclosureIndicator
            case 4:
                cell.textLabel?.text = "Archive Storage Size"
                cell.detailTextLabel?.text = LightGramSpyManager.shared.formattedArchiveSize()
                cell.accessoryType = .none
            default: break
            }
            
        case .privacyAndSecurity:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Face ID / Passcode For Archive"
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
            
        case .smartFilters:
            cell.textLabel?.text = "Quick Chat Filters (Users, Groups, Bots)"
            let sw = self.makeSwitch(isOn: LightGramSettings.shared.smartFiltersEnabled) { on in
                LightGramSettings.shared.smartFiltersEnabled = on
            }
            cell.accessoryView = sw
            
        case .tools:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Group & Bot Tools"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "Network Diagnostics"
                cell.detailTextLabel?.text = "NWConnection / DC 2"
                cell.accessoryType = .disclosureIndicator
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
        } else if s == .tools {
            if indexPath.row == 0 {
                let toolsVC = LightGramToolsController()
                self.push(toolsVC)
            } else if indexPath.row == 1 {
                self.showNetworkDiagnostics()
            }
        }
    }
    
    private func showNetworkDiagnostics() {
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let logLines = Logger.shared.getRecentLogLines()
        let report = """
        === LightGram V1 Network Diagnostics ===
        App Version: \(appVersion)
        iOS: \(UIDevice.current.systemVersion)
        Active Transport: Network.framework (NWConnection)
        DC 2: 149.154.167.50:443
        DC 1: 149.154.175.50:443
        DC 4: 149.154.167.91:443
        
        Recent Logs (\(logLines.count) lines):
        \(logLines.suffix(60).joined(separator: "\n"))
        """
        
        let alert = UIAlertController(title: "Network Diagnostics", message: "Live MTProto & Transport status:", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy Full Report", style: .default, handler: { _ in
            UIPasteboard.general.string = report
        }))
        alert.addAction(UIAlertAction(title: "Share", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let activity = UIActivityViewController(activityItems: [report], applicationActivities: nil)
            self.present(activity, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
