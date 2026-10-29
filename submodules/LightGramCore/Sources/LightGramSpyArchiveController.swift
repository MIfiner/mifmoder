import Foundation
import UIKit
import Display
import AsyncDisplayKit
import LocalAuthentication

public final class LightGramSpyArchiveController: ViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let segmentedControl = UISegmentedControl(items: ["Deleted Messages", "Edit History"])
    private let searchBar = UISearchBar()
    
    private var deletedMessages: [SpyDeletedMessageRecord] = []
    private var filteredDeleted: [SpyDeletedMessageRecord] = []
    private var editRecords: [SpyEditRecord] = []
    private var filteredEdits: [SpyEditRecord] = []
    
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(self.clearArchiveTapped)
        )
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor(rgb: 0xEB5545)
    }
    
    private func setupViews() {
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.addTarget(self, action: #selector(self.segmentChanged), for: .valueChanged)
        self.segmentedControl.selectedSegmentTintColor = LightGramSettings.signatureYellowAccent
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        self.view.insertSubview(self.segmentedControl, at: 0)
        
        self.searchBar.placeholder = "Search messages or sender..."
        self.searchBar.delegate = self
        self.searchBar.barStyle = .black
        self.searchBar.tintColor = LightGramSettings.signatureYellowAccent
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
                                navigationController.popViewController(animated: true)
                            } else {
                                self?.navigationController?.popViewController(animated: true)
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
        LightGramSpyManager.shared.fetchDeletedMessages { [weak self] deleted in
            guard let self = self else { return }
            self.deletedMessages = deleted
            self.filterData()
        }
    }
    
    private func filterData() {
        let query = self.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if query.isEmpty {
            self.filteredDeleted = self.deletedMessages
            self.filteredEdits = self.editRecords
        } else {
            self.filteredDeleted = self.deletedMessages.filter {
                $0.text.lowercased().contains(query) || $0.authorName.lowercased().contains(query)
            }
            self.filteredEdits = self.editRecords.filter {
                $0.newText.lowercased().contains(query) || $0.previousText.lowercased().contains(query) || $0.authorName.lowercased().contains(query)
            }
        }
        self.tableView.reloadData()
    }
    
    @objc private func segmentChanged() {
        self.filterData()
    }
    
    @objc private func clearArchiveTapped() {
        let alert = UIAlertController(
            title: "Clear Spy Archive",
            message: "Are you sure you want to delete all captured messages? This action cannot be undone.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive, handler: { [weak self] _ in
            LightGramSpyManager.shared.clearAllData {
                self?.deletedMessages = []
                self?.editRecords = []
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
        cell.detailTextLabel?.textColor = UIColor(white: 0.7, alpha: 1.0)
        
        let isDeleted = self.segmentedControl.selectedSegmentIndex == 0
        if isDeleted {
            if self.filteredDeleted.isEmpty {
                cell.textLabel?.text = "No deleted messages captured yet."
                cell.detailTextLabel?.text = "Deleted messages will appear here when detected."
                cell.textLabel?.textColor = UIColor(white: 0.5, alpha: 1.0)
                cell.selectionStyle = .none
                return cell
            }
            let item = self.filteredDeleted[indexPath.row]
            cell.textLabel?.text = "🗑 [Deleted] \(item.authorName)"
            cell.textLabel?.textColor = LightGramSettings.signatureYellowAccent
            let dateStr = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(item.deletionTimestamp)), dateStyle: .short, timeStyle: .short)
            cell.detailTextLabel?.text = "\(item.text)\nSaved at: \(dateStr)"
            cell.detailTextLabel?.numberOfLines = 3
        } else {
            if self.filteredEdits.isEmpty {
                cell.textLabel?.text = "No edited messages captured yet."
                cell.detailTextLabel?.text = "Previous versions of edited messages appear here."
                cell.textLabel?.textColor = UIColor(white: 0.5, alpha: 1.0)
                cell.selectionStyle = .none
                return cell
            }
            let item = self.filteredEdits[indexPath.row]
            cell.textLabel?.text = "✏️ [Rev \(item.revision)] \(item.authorName)"
            cell.textLabel?.textColor = LightGramSettings.signatureYellowAccent
            cell.detailTextLabel?.text = "Was: \"\(item.previousText)\"\nNow: \"\(item.newText)\""
            cell.detailTextLabel?.numberOfLines = 3
        }
        return cell
    }
}
