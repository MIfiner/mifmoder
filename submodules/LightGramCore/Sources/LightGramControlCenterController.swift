import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import AccountContext

public final class LightGramControlCenterController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let context: AccountContext?
    
    private var sections: [(title: String, items: [(title: String, subtitle: String, icon: String, destination: String)])] {
        return [
            (LightGramStrings.tr("GhostMode_Header"), [
                (LightGramStrings.tr("GhostMode"), LightGramStrings.tr("GhostMode_Master_Desc"), "👻", "ghost"),
                (LightGramStrings.tr("SpyMode"), LightGramStrings.tr("SpyMode_Master_Desc"), "🕵️‍♂️", "spy"),
                (LightGramStrings.tr("PrivacyCenter_Title"), LightGramStrings.tr("PrivacyCenter_Header"), "🛡", "privacy")
            ]),
            (LightGramStrings.tr("SmartFolders_Header"), [
                (LightGramStrings.tr("SmartFolders_Title"), LightGramStrings.tr("SmartFolders_Header"), "📁", "folders"),
                (LightGramStrings.tr("Notes_Title"), LightGramStrings.tr("Notes_Empty"), "📝", "notes"),
                (LightGramStrings.tr("MediaCenter_Title"), LightGramStrings.tr("MediaCenter_Storage"), "🎬", "media"),
                (LightGramStrings.tr("BotManager_Title"), LightGramStrings.tr("BotManager_Header"), "🤖", "bots")
            ]),
            (LightGramStrings.tr("Settings"), [
                (LightGramStrings.tr("Logos_Title"), LightGramStrings.tr("Logos_Footer"), "🎨", "logos"),
                ("Network Diagnostics", "Live DC ping RTT & NWConnection status", "📶", "diagnostics"),
                (LightGramStrings.tr("Settings"), "LightGram Settings", "⚙️", "settings")
            ])
        ]
    }
    
    public init(context: AccountContext? = nil) {
        self.context = context
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = LightGramStrings.tr("LightGram")
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
            targetController = LightGramSettingsController(context: self.context)
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
        case "logos":
            if let context = self.context {
                targetController = LightGramLogosController(context: context)
            } else {
                targetController = LightGramSettingsController(context: self.context)
            }
        case "diagnostics":
            targetController = LightGramNetworkDiagnosticsController()
        default:
            targetController = LightGramSettingsController(context: self.context)
        }
        
        self.push(targetController)
    }
}
