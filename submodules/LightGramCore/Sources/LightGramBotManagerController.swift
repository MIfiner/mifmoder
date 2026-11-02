import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore

public final class LightGramBotManagerController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let favoriteBots: [(name: String, username: String, icon: String, description: String)] = [
        ("Wallet Bot", "@wallet", "👛", "Crypto and TON payments"),
        ("Telegram BotFather", "@botfather", "🎩", "Create and configure bots"),
        ("Stickers Bot", "@stickers", "🎨", "Custom sticker sets management"),
        ("Inline GIF Bot", "@gif", "🎬", "Instant animated GIF search"),
        ("Vote Bot", "@vote", "📊", "Create polls and voting")
    ]
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "Bot & Group Tools"
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
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.favoriteBots.count
        } else {
            return 3
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Favorite Bots & Utilities"
        } else {
            return "Group Administrator Tools"
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "BotCell")
            cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = LightGramDesignSystem.Typography.headline
            cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.textSecondary
            
            let item = self.favoriteBots[indexPath.row]
            cell.textLabel?.text = "\(item.icon)  \(item.name)"
            cell.detailTextLabel?.text = "\(item.username) • \(item.description)"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        } else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "GroupToolCell")
            cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = LightGramDesignSystem.Typography.headline
            cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.textSecondary
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "🛡 Administrator Audit"
                cell.detailTextLabel?.text = "View privileges, recent admin actions and logs"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "📌 Pinned Messages Center"
                cell.detailTextLabel?.text = "Browse and manage pinned items across group chats"
            } else {
                cell.textLabel?.text = "🚫 Anti-Spam & Member Permissions"
                cell.detailTextLabel?.text = "Configure slow mode, media restrictions & bot limits"
            }
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        LightGramDesignSystem.Haptics.selection()
    }
}
