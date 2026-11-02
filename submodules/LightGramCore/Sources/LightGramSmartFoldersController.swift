import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore

public struct SmartFolderItem: Codable, Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public var isEnabled: Bool
    public var badgeCount: Int
    
    public init(id: String, name: String, icon: String, isEnabled: Bool = true, badgeCount: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isEnabled = isEnabled
        self.badgeCount = badgeCount
    }
}

public final class LightGramSmartFoldersController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var folders: [SmartFolderItem] = [
        SmartFolderItem(id: "all", name: "All Chats", icon: "💬", isEnabled: true),
        SmartFolderItem(id: "unread", name: "Unread", icon: "📬", isEnabled: true),
        SmartFolderItem(id: "personal", name: "Personal (DMs)", icon: "👤", isEnabled: true),
        SmartFolderItem(id: "groups", name: "Groups", icon: "👥", isEnabled: true),
        SmartFolderItem(id: "channels", name: "Channels", icon: "📢", isEnabled: true),
        SmartFolderItem(id: "bots", name: "Bots", icon: "🤖", isEnabled: true),
        SmartFolderItem(id: "work", name: "Work", icon: "💼", isEnabled: false),
        SmartFolderItem(id: "important", name: "Important", icon: "⭐", isEnabled: false),
        SmartFolderItem(id: "archived", name: "Archived", icon: "📦", isEnabled: true)
    ]
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "Smart Folders"
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
        self.loadSavedFolders()
    }
    
    private func setupViews() {
        self.tableView.backgroundColor = LightGramDesignSystem.Colors.deepGraphite
        self.tableView.separatorColor = LightGramDesignSystem.Colors.borderGraphite
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.isEditing = false
        self.view.insertSubview(self.tableView, at: 0)
        
        let editItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.toggleEdit))
        editItem.tintColor = LightGramDesignSystem.Colors.signatureYellow
        self.navigationItem.rightBarButtonItem = editItem
    }
    
    @objc private func toggleEdit() {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        self.navigationItem.rightBarButtonItem?.title = self.tableView.isEditing ? "Done" : "Edit"
        LightGramDesignSystem.Haptics.selection()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topOffset = self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)
        self.tableView.frame = CGRect(x: 0, y: topOffset, width: layout.size.width, height: max(0, layout.size.height - topOffset))
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: layout.intrinsicInsets.bottom, right: 0)
    }
    
    private func loadSavedFolders() {
        if let data = UserDefaults.standard.data(forKey: "lightgram_smart_folders_v2"),
           let saved = try? JSONDecoder().decode([SmartFolderItem].self, from: data) {
            self.folders = saved
            self.tableView.reloadData()
        }
    }
    
    private func saveFolders() {
        if let data = try? JSONEncoder().encode(self.folders) {
            UserDefaults.standard.set(data, forKey: "lightgram_smart_folders_v2")
        }
    }
    
    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.folders.count
        } else {
            return 1
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Active Smart Tabs"
        } else {
            return "Rules & Behavior"
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "FolderCell")
            cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = LightGramDesignSystem.Typography.headline
            
            let item = self.folders[indexPath.row]
            cell.textLabel?.text = "\(item.icon)  \(item.name)"
            
            let switchView = UISwitch()
            switchView.isOn = item.isEnabled
            switchView.onTintColor = LightGramDesignSystem.Colors.signatureYellow
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.folderToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "RuleCell")
            cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = LightGramDesignSystem.Typography.headline
            cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.textSecondary
            cell.textLabel?.text = "Auto-sort Unread to Top"
            cell.detailTextLabel?.text = "Dynamically highlights folders containing unread mentions or messages."
            
            let switchView = UISwitch()
            switchView.isOn = UserDefaults.standard.bool(forKey: "lightgram_smart_folders_autosort")
            switchView.onTintColor = LightGramDesignSystem.Colors.signatureYellow
            switchView.addTarget(self, action: #selector(self.autosortToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            return cell
        }
    }
    
    @objc private func folderToggled(_ sender: UISwitch) {
        let index = sender.tag
        guard index < self.folders.count else { return }
        self.folders[index].isEnabled = sender.isOn
        self.saveFolders()
        LightGramDesignSystem.Haptics.selection()
    }
    
    @objc private func autosortToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "lightgram_smart_folders_autosort")
        LightGramDesignSystem.Haptics.selection()
    }
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.section == 0 && destinationIndexPath.section == 0 else { return }
        let moved = self.folders.remove(at: sourceIndexPath.row)
        self.folders.insert(moved, at: destinationIndexPath.row)
        self.saveFolders()
        LightGramDesignSystem.Haptics.selection()
    }
}
