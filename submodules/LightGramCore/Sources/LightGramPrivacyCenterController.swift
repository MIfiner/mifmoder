import Foundation
import UIKit
import Display
import AsyncDisplayKit
import LocalAuthentication
import TelegramCore

public final class LightGramPrivacyCenterController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "Privacy & Security Center"
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
        self.view.backgroundColor = LightGramDesignSystem.Colors.deepGraphite
        self.setupViews()
    }
    
    private func setupViews() {
        self.tableView.backgroundColor = LightGramDesignSystem.Colors.deepGraphite
        self.tableView.separatorColor = LightGramDesignSystem.Colors.borderGraphite
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.insertSubview(self.tableView, at: 0)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topOffset = self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)
        self.tableView.frame = CGRect(x: 0, y: topOffset, width: layout.size.width, height: max(0, layout.size.height - topOffset))
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: layout.intrinsicInsets.bottom, right: 0)
    }
    
    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Ghost & Spy status
        case 1: return 2 // Biometrics & App Lock
        case 2: return 2 // Retention & TTL
        default: return 2 // Export & Maintenance
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Core Stealth & Protection Status"
        case 1: return "Device Biometrics & Local Lock"
        case 2: return "Data Retention Policy"
        default: return "Archive Maintenance & Export"
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "PrivacyCell")
        cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = LightGramDesignSystem.Typography.headline
        cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.textSecondary
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                cell.textLabel?.text = "👻 Ghost Mode 2.0"
                cell.detailTextLabel?.text = LightGramSettings.shared.isGhostModeEnabled ? "Active (Read receipts, typing & presence suppressed)" : "Disabled"
                let sw = UISwitch()
                sw.isOn = LightGramSettings.shared.isGhostModeEnabled
                sw.onTintColor = LightGramDesignSystem.Colors.signatureYellow
                sw.addTarget(self, action: #selector(self.ghostToggled(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else {
                cell.textLabel?.text = "🕵️‍♂️ Spy Mode & Anti-Recall"
                cell.detailTextLabel?.text = LightGramSettings.shared.isSpyModeEnabled ? "Active (Deleted & edited messages preserved inline)" : "Disabled"
                let sw = UISwitch()
                sw.isOn = LightGramSettings.shared.isSpyModeEnabled
                sw.onTintColor = LightGramDesignSystem.Colors.signatureYellow
                sw.addTarget(self, action: #selector(self.spyToggled(_:)), for: .valueChanged)
                cell.accessoryView = sw
            }
        case 1:
            if indexPath.row == 0 {
                cell.textLabel?.text = "🔒 Biometric Archive Lock"
                cell.detailTextLabel?.text = "Require Face ID or Touch ID to view Spy Archive"
                let sw = UISwitch()
                sw.isOn = LightGramSettings.shared.biometricLockArchive
                sw.onTintColor = LightGramDesignSystem.Colors.signatureYellow
                sw.addTarget(self, action: #selector(self.biometricToggled(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else {
                cell.textLabel?.text = "🙈 Hide Notification Preview"
                cell.detailTextLabel?.text = "Hide message sender and preview text when locked"
                let sw = UISwitch()
                sw.isOn = UserDefaults.standard.bool(forKey: "lightgram_hide_notification_preview")
                sw.onTintColor = LightGramDesignSystem.Colors.signatureYellow
                sw.addTarget(self, action: #selector(self.notificationPreviewToggled(_:)), for: .valueChanged)
                cell.accessoryView = sw
            }
        case 2:
            if indexPath.row == 0 {
                cell.textLabel?.text = "⏳ Archive Retention Period"
                cell.detailTextLabel?.text = "\(LightGramSettings.shared.retentionDaysTTL) days (Older items pruned automatically)"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "🧼 Auto-Clean Ephemeral Cache"
                cell.detailTextLabel?.text = "Removes temporary downloads upon closing chats"
                let sw = UISwitch()
                sw.isOn = UserDefaults.standard.bool(forKey: "lightgram_autoclean_ephemeral")
                sw.onTintColor = LightGramDesignSystem.Colors.signatureYellow
                sw.addTarget(self, action: #selector(self.ephemeralToggled(_:)), for: .valueChanged)
                cell.accessoryView = sw
            }
        default:
            if indexPath.row == 0 {
                cell.textLabel?.text = "📤 Export Archive JSON"
                cell.detailTextLabel?.text = "Export your local deleted and edited messages"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "🗑 Delete All Local Archive Records"
                cell.textLabel?.textColor = LightGramDesignSystem.Colors.deletedRed
                cell.detailTextLabel?.text = "Permanently removes all captured messages"
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    @objc private func ghostToggled(_ sender: UISwitch) {
        LightGramSettings.shared.isGhostModeEnabled = sender.isOn
        LightGramDesignSystem.Haptics.selection()
        self.tableView.reloadData()
    }
    
    @objc private func spyToggled(_ sender: UISwitch) {
        LightGramSettings.shared.isSpyModeEnabled = sender.isOn
        LightGramDesignSystem.Haptics.selection()
        self.tableView.reloadData()
    }
    
    @objc private func biometricToggled(_ sender: UISwitch) {
        if sender.isOn {
            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Confirm Face ID to enable Archive Lock") { success, _ in
                    DispatchQueue.main.async {
                        LightGramSettings.shared.biometricLockArchive = success
                        sender.isOn = success
                        LightGramDesignSystem.Haptics.notification(success ? .success : .error)
                    }
                }
            } else {
                sender.isOn = false
            }
        } else {
            LightGramSettings.shared.biometricLockArchive = false
            LightGramDesignSystem.Haptics.selection()
        }
    }
    
    @objc private func notificationPreviewToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "lightgram_hide_notification_preview")
        LightGramDesignSystem.Haptics.selection()
    }
    
    @objc private func ephemeralToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "lightgram_autoclean_ephemeral")
        LightGramDesignSystem.Haptics.selection()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 && indexPath.row == 0 {
            let alert = UIAlertController(title: "Retention Period", message: "Select how long captured messages and edits should be preserved in local storage:", preferredStyle: .actionSheet)
            for days in [7, 14, 30, 60, 90, 365] {
                alert.addAction(UIAlertAction(title: "\(days) Days", style: .default, handler: { [weak self] _ in
                    LightGramSettings.shared.retentionDaysTTL = days
                    LightGramSpyManager.shared.enforceTTL()
                    self?.tableView.reloadData()
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        } else if indexPath.section == 3 && indexPath.row == 0 {
            LightGramSpyManager.shared.fetchAllDeletedMessages { [weak self] deleted in
                guard let self = self else { return }
                if let data = try? JSONEncoder().encode(deleted),
                   let jsonStr = String(data: data, encoding: .utf8) {
                    let av = UIActivityViewController(activityItems: [jsonStr], applicationActivities: nil)
                    self.present(av, animated: true)
                }
            }
        } else if indexPath.section == 3 && indexPath.row == 1 {
            let alert = UIAlertController(title: "Delete All Records", message: "Are you sure you want to permanently clear all spy archive records?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Delete Everything", style: .destructive, handler: { _ in
                LightGramSpyManager.shared.clearAllData {
                    LightGramDesignSystem.Haptics.notification(.success)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
    }
}
