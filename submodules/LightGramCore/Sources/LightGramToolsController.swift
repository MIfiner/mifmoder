import Foundation
import UIKit
import Display
import AsyncDisplayKit

public final class LightGramToolsController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let sections = [
        "Group Management & Utilities",
        "Quick Message Templates",
        "Bot Commands Shortcut"
    ]
    
    private let groupUtilities = [
        ("Mute All Group Notifications", "Quickly silence notifications for all participating groups"),
        ("Active Member Filter", "Highlight active members versus silent participants in common groups"),
        ("Media Clean Cache", "Free storage by clearing cached group videos and documents")
    ]
    
    private let messageTemplates = [
        ("👋 Quick Greeting", "\"Hello! How can I help you today?\""),
        ("⏳ Away Notice", "\"I am currently away and will reply shortly.\""),
        ("✅ Acknowledged", "\"Received and confirmed. Thank you!\"")
    ]
    
    private let botShortcuts = [
        ("/start", "Restart active bot session"),
        ("/help", "Request help manual and bot documentation"),
        ("/settings", "Inspect bot parameters and preferences")
    ]
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "Tools & Utilities"
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
        self.view.insertSubview(self.tableView, at: 0)
    }
    
    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return self.groupUtilities.count
        case 1: return self.messageTemplates.count
        case 2: return self.botShortcuts.count
        default: return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ToolCell")
        cell.backgroundColor = LightGramSettings.cardSurfaceColor
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = UIColor(white: 0.7, alpha: 1.0)
        
        switch indexPath.section {
        case 0:
            let item = self.groupUtilities[indexPath.row]
            cell.textLabel?.text = item.0
            cell.detailTextLabel?.text = item.1
            cell.accessoryType = .disclosureIndicator
        case 1:
            let item = self.messageTemplates[indexPath.row]
            cell.textLabel?.text = item.0
            cell.detailTextLabel?.text = item.1
            cell.accessoryType = .none
        case 2:
            let item = self.botShortcuts[indexPath.row]
            cell.textLabel?.text = item.0
            cell.textLabel?.textColor = LightGramSettings.signatureYellowAccent
            cell.detailTextLabel?.text = item.1
            cell.accessoryType = .none
        default:
            break
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let item = self.messageTemplates[indexPath.row]
            UIPasteboard.general.string = item.1.replacingOccurrences(of: "\"", with: "")
            let alert = UIAlertController(title: "Copied!", message: "Template copied to clipboard.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
