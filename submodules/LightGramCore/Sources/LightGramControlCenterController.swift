import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore

public final class LightGramControlCenterController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let sections: [(title: String, items: [(title: String, subtitle: String, icon: String, destination: String)])] = [
        ("Core Stealth & Privacy", [
            ("Ghost Mode 2.0", "Manage read receipts, typing & online stealth", "👻", "ghost"),
            ("Spy Mode & Anti-Recall", "Inline deleted & edited message preservation", "🕵️‍♂️", "spy"),
            ("Privacy & Security Hub", "Biometric lock, notification privacy & data export", "🛡", "privacy")
        ]),
        ("Advanced Productivity Tools", [
            ("Smart Folders", "Custom chat categorization & auto-sorting", "📁", "folders"),
            ("Notes & Reminders", "Personal message notes & scheduled reminders", "📝", "notes"),
            ("Media Center", "Categorized media library & storage cleaner", "🎬", "media"),
            ("Bot & Group Manager", "Admin tools & bot shortcuts palette", "🤖", "bots")
        ]),
        ("System & Diagnostics", [
            ("Network & MTProto Diagnostics", "Live DC ping RTT & connection status", "📶", "diagnostics"),
            ("LightGram Settings", "Comprehensive application configuration", "⚙️", "settings")
        ])
    ]
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "LightGram Control Center"
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
        return self.sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].items.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HubCell")
        cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = LightGramDesignSystem.Typography.headline
        cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.textSecondary
        cell.accessoryType = .disclosureIndicator
        
        let item = self.sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = "\(item.icon)  \(item.title)"
        cell.detailTextLabel?.text = item.subtitle
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        LightGramDesignSystem.Haptics.selection()
        
        let dest = self.sections[indexPath.section].items[indexPath.row].destination
        let targetController: ViewController
        switch dest {
        case "ghost":
            targetController = LightGramSettingsController()
        case "spy":
            targetController = LightGramSpyArchiveController()
        case "privacy":
            targetController = LightGramPrivacyCenterController()
        case "folders":
            targetController = LightGramSmartFoldersController()
        case "notes":
            targetController = LightGramNotesController()
        case "media":
            targetController = LightGramMediaCenterController()
        case "bots":
            targetController = LightGramBotManagerController()
        case "diagnostics":
            targetController = LightGramNetworkDiagnosticsController()
        default:
            targetController = LightGramSettingsController()
        }
        
        self.push(targetController)
    }
}
