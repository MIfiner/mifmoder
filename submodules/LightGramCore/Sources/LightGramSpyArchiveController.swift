import Foundation
import UIKit
import Display
import AsyncDisplayKit
import LocalAuthentication
import TelegramCore

public final class LightGramSpyArchiveController: ViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let segmentedControl = UISegmentedControl(items: ["Deleted Messages", "Edit History"])
    private let searchBar = UISearchBar()
    
    private var deletedMessages: [SpyDeletedMessageRecord] = []
    private var filteredDeleted: [SpyDeletedMessageRecord] = []
    private var editRecords: [SpyEditRecord] = []
    private var filteredEdits: [SpyEditRecord] = []
    
    private var selectedChatFilter: String? = nil
    private var isAuthenticated = false
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "Spy Archive"
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
        self.setupNavigationBar()
        self.setupViews()
        self.checkAuthenticationAndLoad()
    }
    
    private func setupNavigationBar() {
        let filterItem = UIBarButtonItem(
            title: "Filter",
            style: .plain,
            target: self,
            action: #selector(self.filterTapped)
        )
        filterItem.tintColor = LightGramSettings.signatureYellowAccent
        
        let clearItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(self.clearArchiveTapped)
        )
        clearItem.tintColor = UIColor(rgb: 0xEB5545)
        
        self.navigationItem.rightBarButtonItems = [clearItem, filterItem]
    }
    
    private func setupViews() {
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.addTarget(self, action: #selector(self.segmentChanged), for: .valueChanged)
        self.segmentedControl.selectedSegmentTintColor = LightGramSettings.signatureYellowAccent
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .regular)], for: .normal)
        self.view.insertSubview(self.segmentedControl, at: 0)
        
        self.searchBar.placeholder = "Search by message text, sender, or chat..."
        self.searchBar.delegate = self
        self.searchBar.barStyle = .black
        self.searchBar.tintColor = LightGramSettings.signatureYellowAccent
        self.searchBar.searchTextField.textColor = .white
        self.searchBar.searchTextField.backgroundColor = LightGramSettings.cardSurfaceColor
        self.view.insertSubview(self.searchBar, at: 0)
        
        self.tableView.backgroundColor = LightGramSettings.deepGraphiteBackground
        self.tableView.separatorColor = UIColor(white: 0.25, alpha: 1.0)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.insertSubview(self.tableView, at: 0)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topOffset = self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)
        
        let segmentHeight: CGFloat = 36.0
        let searchBarHeight: CGFloat = 52.0
        
        self.segmentedControl.frame = CGRect(x: 16, y: topOffset + 8, width: layout.size.width - 32, height: segmentHeight)
        self.searchBar.frame = CGRect(x: 0, y: self.segmentedControl.frame.maxY + 8, width: layout.size.width, height: searchBarHeight)
        let tableTop = self.searchBar.frame.maxY
        self.tableView.frame = CGRect(x: 0, y: tableTop, width: layout.size.width, height: max(0, layout.size.height - tableTop))
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: layout.intrinsicInsets.bottom, right: 0)
    }
    
    private func checkAuthenticationAndLoad() {
        if LightGramSettings.shared.biometricLockArchive && !self.isAuthenticated {
            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock LightGram Spy Archive") { [weak self] success, _ in
                    DispatchQueue.main.async {
                        if success {
                            self?.isAuthenticated = true
                            self?.loadData()
                        } else {
                            if let navigationController = self?.navigationController as? NavigationController {
                                let _ = navigationController.popViewController(animated: true)
                            } else {
                                let _ = self?.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
                return
            }
        }
        self.loadData()
    }
    
    private func loadData() {
        let group = DispatchGroup()
        
        group.enter()
        LightGramSpyManager.shared.fetchAllDeletedMessages { [weak self] deleted in
            self?.deletedMessages = deleted
            group.leave()
        }
        
        group.enter()
        LightGramSpyManager.shared.fetchAllEditRecords { [weak self] edits in
            self?.editRecords = edits
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.updateSegmentTitles()
            self.filterData()
        }
    }
    
    private func updateSegmentTitles() {
        let deletedTitle = "Deleted (\(self.deletedMessages.count))"
        let editsTitle = "Edits (\(self.editRecords.count))"
        self.segmentedControl.setTitle(deletedTitle, forSegmentAt: 0)
        self.segmentedControl.setTitle(editsTitle, forSegmentAt: 1)
    }
    
    private func filterData() {
        let query = self.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let filterChat = self.selectedChatFilter
        
        self.filteredDeleted = self.deletedMessages.filter { item in
            if let filterChat = filterChat, item.chatTitle != filterChat {
                return false
            }
            if query.isEmpty { return true }
            return item.text.lowercased().contains(query) ||
                   item.authorName.lowercased().contains(query) ||
                   item.chatTitle.lowercased().contains(query) ||
                   (item.mediaDescription?.lowercased().contains(query) ?? false)
        }
        
        self.filteredEdits = self.editRecords.filter { item in
            if let filterChat = filterChat, item.chatTitle != filterChat {
                return false
            }
            if query.isEmpty { return true }
            return item.newText.lowercased().contains(query) ||
                   item.previousText.lowercased().contains(query) ||
                   item.authorName.lowercased().contains(query) ||
                   item.chatTitle.lowercased().contains(query)
        }
        
        self.tableView.reloadData()
    }
    
    @objc private func segmentChanged() {
        self.filterData()
    }
    
    @objc private func filterTapped() {
        var chats = Set<String>()
        for m in self.deletedMessages { chats.insert(m.chatTitle) }
        for e in self.editRecords { chats.insert(e.chatTitle) }
        
        let alert = UIAlertController(title: "Filter by Chat", message: "Select a chat to filter archived messages", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "All Chats", style: self.selectedChatFilter == nil ? .destructive : .default, handler: { [weak self] _ in
            self?.selectedChatFilter = nil
            self?.filterData()
        }))
        
        for chat in chats.sorted() {
            let isCurrent = self.selectedChatFilter == chat
            alert.addAction(UIAlertAction(title: isCurrent ? "✓ \(chat)" : chat, style: .default, handler: { [weak self] _ in
                self?.selectedChatFilter = chat
                self?.filterData()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @objc private func clearArchiveTapped() {
        let alert = UIAlertController(
            title: "Clear Spy Archive",
            message: "Are you sure you want to permanently delete all captured messages and edit history? This cannot be undone.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Delete All Records", style: .destructive, handler: { [weak self] _ in
            LightGramSpyManager.shared.clearAllData {
                self?.deletedMessages = []
                self?.editRecords = []
                self?.updateSegmentTitles()
                self?.filterData()
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    // MARK: - UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterData()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UITableViewDataSource & Delegate
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            return max(1, self.filteredDeleted.count)
        } else {
            return max(1, self.filteredEdits.count)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SpyCell")
        cell.backgroundColor = LightGramSettings.cardSurfaceColor
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = UIColor(white: 0.75, alpha: 1.0)
        cell.textLabel?.numberOfLines = 1
        cell.detailTextLabel?.numberOfLines = 4
        
        let isDeleted = self.segmentedControl.selectedSegmentIndex == 0
        if isDeleted {
            if self.filteredDeleted.isEmpty {
                cell.textLabel?.text = "No deleted messages captured"
                cell.detailTextLabel?.text = self.deletedMessages.isEmpty ?
                    "When messages in your chats are deleted, LightGram preserves them here automatically." :
                    "No deleted messages match your search filter."
                cell.textLabel?.textColor = UIColor(white: 0.5, alpha: 1.0)
                cell.selectionStyle = .none
                return cell
            }
            let item = self.filteredDeleted[indexPath.row]
            
            let dateStr = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(item.deletionTimestamp)), dateStyle: .short, timeStyle: .short)
            cell.textLabel?.text = "🗑 \(item.authorName)  •  \(item.chatTitle)"
            cell.textLabel?.textColor = LightGramSettings.signatureYellowAccent
            
            var body = item.text
            if let mediaDesc = item.mediaDescription {
                body = body.isEmpty ? "[\(mediaDesc)]" : "[\(mediaDesc)]\n\(body)"
            }
            cell.detailTextLabel?.text = "\(body)\nSaved at: \(dateStr)"
            cell.selectionStyle = .default
        } else {
            if self.filteredEdits.isEmpty {
                cell.textLabel?.text = "No edit history captured"
                cell.detailTextLabel?.text = self.editRecords.isEmpty ?
                    "When messages in your chats are edited, previous versions are preserved here." :
                    "No edited messages match your search filter."
                cell.textLabel?.textColor = UIColor(white: 0.5, alpha: 1.0)
                cell.selectionStyle = .none
                return cell
            }
            let item = self.filteredEdits[indexPath.row]
            let dateStr = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(item.timestamp)), dateStyle: .short, timeStyle: .short)
            cell.textLabel?.text = "✏️ [Rev \(item.revision)] \(item.authorName)  •  \(item.chatTitle)"
            cell.textLabel?.textColor = LightGramSettings.signatureYellowAccent
            cell.detailTextLabel?.text = "🔴 Was: \"\(item.previousText)\"\n🟢 Now: \"\(item.newText)\"\nEdited at: \(dateStr)"
            cell.selectionStyle = .default
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let isDeleted = self.segmentedControl.selectedSegmentIndex == 0
        
        if isDeleted {
            guard !self.filteredDeleted.isEmpty && indexPath.row < self.filteredDeleted.count else { return }
            let item = self.filteredDeleted[indexPath.row]
            self.showDeletedDetail(item: item)
        } else {
            guard !self.filteredEdits.isEmpty && indexPath.row < self.filteredEdits.count else { return }
            let item = self.filteredEdits[indexPath.row]
            self.showEditDetail(item: item)
        }
    }
    
    private func showDeletedDetail(item: SpyDeletedMessageRecord) {
        let origDate = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(item.originalTimestamp)), dateStyle: .medium, timeStyle: .medium)
        let delDate = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(item.deletionTimestamp)), dateStyle: .medium, timeStyle: .medium)
        
        var messageInfo = "Chat: \(item.chatTitle)\nAuthor: \(item.authorName)\nSent: \(origDate)\nDeleted: \(delDate)\n\n"
        if let mediaDesc = item.mediaDescription {
            messageInfo += "Media: [\(mediaDesc)]\n\n"
        }
        messageInfo += "Message Text:\n\(item.text.isEmpty ? "(No text content)" : item.text)"
        
        let alert = UIAlertController(title: "Deleted Message Details", message: messageInfo, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy Text", style: .default, handler: { _ in
            UIPasteboard.general.string = item.text
        }))
        alert.addAction(UIAlertAction(title: "Delete from Archive", style: .destructive, handler: { [weak self] _ in
            LightGramSpyManager.shared.deleteRecord(id: item.id, isDeletedMessage: true) {
                self?.loadData()
            }
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        self.present(alert, animated: true)
    }
    
    private func showEditDetail(item: SpyEditRecord) {
        let dateStr = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(item.timestamp)), dateStyle: .medium, timeStyle: .medium)
        let messageInfo = "Chat: \(item.chatTitle)\nAuthor: \(item.authorName)\nRevision: \(item.revision)\nEdited: \(dateStr)\n\nPrevious Text:\n\(item.previousText)\n\nCurrent Text:\n\(item.newText)"
        
        let alert = UIAlertController(title: "Message Edit Details", message: messageInfo, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy Previous Text", style: .default, handler: { _ in
            UIPasteboard.general.string = item.previousText
        }))
        alert.addAction(UIAlertAction(title: "Copy Current Text", style: .default, handler: { _ in
            UIPasteboard.general.string = item.newText
        }))
        alert.addAction(UIAlertAction(title: "Delete from Archive", style: .destructive, handler: { [weak self] _ in
            LightGramSpyManager.shared.deleteRecord(id: item.id, isDeletedMessage: false) {
                self?.loadData()
            }
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        self.present(alert, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let isDeleted = self.segmentedControl.selectedSegmentIndex == 0
        if isDeleted {
            return !self.filteredDeleted.isEmpty
        } else {
            return !self.filteredEdits.isEmpty
        }
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let isDeleted = self.segmentedControl.selectedSegmentIndex == 0
        
        if isDeleted {
            guard indexPath.row < self.filteredDeleted.count else { return }
            let item = self.filteredDeleted[indexPath.row]
            LightGramSpyManager.shared.deleteRecord(id: item.id, isDeletedMessage: true) { [weak self] in
                self?.loadData()
            }
        } else {
            guard indexPath.row < self.filteredEdits.count else { return }
            let item = self.filteredEdits[indexPath.row]
            LightGramSpyManager.shared.deleteRecord(id: item.id, isDeletedMessage: false) { [weak self] in
                self?.loadData()
            }
        }
    }
}
