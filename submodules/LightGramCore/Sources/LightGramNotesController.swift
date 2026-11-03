import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore

public final class LightGramNotesController: ViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let segmentedControl = UISegmentedControl(items: ["Personal Notes", "Reminders"])
    private let searchBar = UISearchBar()
    
    private var notes: [LightGramPersonalNote] = []
    private var filteredNotes: [LightGramPersonalNote] = []
    private var reminders: [LightGramMessageReminder] = []
    private var filteredReminders: [LightGramMessageReminder] = []
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = LightGramStrings.tr("Notes_Title")
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
        self.loadData()
    }
    
    private func setupViews() {
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.addTarget(self, action: #selector(self.segmentChanged), for: .valueChanged)
        self.segmentedControl.selectedSegmentTintColor = LightGramDesignSystem.Colors.signatureYellow
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: LightGramDesignSystem.Typography.subheadlineMedium], for: .selected)
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: LightGramDesignSystem.Typography.subheadline], for: .normal)
        self.view.insertSubview(self.segmentedControl, at: 0)
        
        self.searchBar.placeholder = "Search notes & reminders..."
        self.searchBar.delegate = self
        self.searchBar.barStyle = .black
        self.searchBar.tintColor = LightGramDesignSystem.Colors.signatureYellow
        self.searchBar.searchTextField.textColor = .white
        self.searchBar.searchTextField.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        self.view.insertSubview(self.searchBar, at: 0)
        
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
        
        let segmentHeight: CGFloat = 36.0
        let searchBarHeight: CGFloat = 52.0
        
        self.segmentedControl.frame = CGRect(x: 16, y: topOffset + 8, width: layout.size.width - 32, height: segmentHeight)
        self.searchBar.frame = CGRect(x: 0, y: self.segmentedControl.frame.maxY + 8, width: layout.size.width, height: searchBarHeight)
        let tableTop = self.searchBar.frame.maxY
        self.tableView.frame = CGRect(x: 0, y: tableTop, width: layout.size.width, height: max(0, layout.size.height - tableTop))
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: layout.intrinsicInsets.bottom, right: 0)
    }
    
    private func loadData() {
        LightGramNotesManager.shared.fetchAllNotes { [weak self] notes in
            self?.notes = notes
            self?.filterData()
        }
        LightGramNotesManager.shared.fetchAllReminders { [weak self] reminders in
            self?.reminders = reminders
            self?.filterData()
        }
    }
    
    private func filterData() {
        let query = self.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if query.isEmpty {
            self.filteredNotes = self.notes
            self.filteredReminders = self.reminders
        } else {
            self.filteredNotes = self.notes.filter {
                $0.noteText.lowercased().contains(query) ||
                $0.originalText.lowercased().contains(query) ||
                $0.chatTitle.lowercased().contains(query) ||
                $0.authorName.lowercased().contains(query)
            }
            self.filteredReminders = self.reminders.filter {
                $0.messageText.lowercased().contains(query) ||
                $0.chatTitle.lowercased().contains(query)
            }
        }
        self.tableView.reloadData()
    }
    
    @objc private func segmentChanged() {
        LightGramDesignSystem.Haptics.selection()
        self.filterData()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterData()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            return max(1, self.filteredNotes.count)
        } else {
            return max(1, self.filteredReminders.count)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "NoteCell")
        cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.textSecondary
        cell.textLabel?.numberOfLines = 1
        cell.detailTextLabel?.numberOfLines = 3
        
        let isNotes = self.segmentedControl.selectedSegmentIndex == 0
        if isNotes {
            if self.filteredNotes.isEmpty {
                cell.textLabel?.text = "No personal notes yet"
                cell.detailTextLabel?.text = "You can save any message to your personal notes directly from the message context menu."
                cell.textLabel?.textColor = LightGramDesignSystem.Colors.textTertiary
                cell.selectionStyle = .none
                return cell
            }
            let note = self.filteredNotes[indexPath.row]
            cell.textLabel?.text = "📝 \(note.authorName)  •  \(note.chatTitle)"
            cell.textLabel?.textColor = LightGramDesignSystem.Colors.signatureYellow
            cell.detailTextLabel?.text = "Note: \(note.noteText)\nOriginal: \"\(note.originalText)\""
            cell.selectionStyle = .default
        } else {
            if self.filteredReminders.isEmpty {
                cell.textLabel?.text = "No reminders scheduled"
                cell.detailTextLabel?.text = "Set reminders on important messages to be notified later."
                cell.textLabel?.textColor = LightGramDesignSystem.Colors.textTertiary
                cell.selectionStyle = .none
                return cell
            }
            let rem = self.filteredReminders[indexPath.row]
            let dateStr = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(rem.remindAtTimestamp)), dateStyle: .short, timeStyle: .short)
            cell.textLabel?.text = "\(rem.isCompleted ? "✅" : "⏰") \(rem.chatTitle)  •  Due: \(dateStr)"
            cell.textLabel?.textColor = rem.isCompleted ? LightGramDesignSystem.Colors.onlineGreen : LightGramDesignSystem.Colors.signatureYellow
            cell.detailTextLabel?.text = rem.messageText
            cell.selectionStyle = .default
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let isNotes = self.segmentedControl.selectedSegmentIndex == 0
        if isNotes {
            guard !self.filteredNotes.isEmpty && indexPath.row < self.filteredNotes.count else { return }
            let note = self.filteredNotes[indexPath.row]
            let alert = UIAlertController(title: "Note Details", message: "Chat: \(note.chatTitle)\nAuthor: \(note.authorName)\n\nNote:\n\(note.noteText)\n\nOriginal Message:\n\"\(note.originalText)\"", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Copy Note", style: .default, handler: { _ in
                UIPasteboard.general.string = note.noteText
            }))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
                LightGramNotesManager.shared.deleteNote(id: note.id) {
                    self?.loadData()
                }
            }))
            alert.addAction(UIAlertAction(title: "Close", style: .cancel))
            self.present(alert, animated: true)
        } else {
            guard !self.filteredReminders.isEmpty && indexPath.row < self.filteredReminders.count else { return }
            let rem = self.filteredReminders[indexPath.row]
            LightGramNotesManager.shared.toggleReminderCompleted(id: rem.id) { [weak self] in
                LightGramDesignSystem.Haptics.notification(.success)
                self?.loadData()
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            return !self.filteredNotes.isEmpty
        } else {
            return !self.filteredReminders.isEmpty
        }
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        if self.segmentedControl.selectedSegmentIndex == 0 {
            guard indexPath.row < self.filteredNotes.count else { return }
            let note = self.filteredNotes[indexPath.row]
            LightGramNotesManager.shared.deleteNote(id: note.id) { [weak self] in
                self?.loadData()
            }
        } else {
            guard indexPath.row < self.filteredReminders.count else { return }
            let rem = self.filteredReminders[indexPath.row]
            LightGramNotesManager.shared.deleteReminder(id: rem.id) { [weak self] in
                self?.loadData()
            }
        }
    }
}
