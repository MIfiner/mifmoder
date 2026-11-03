import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore

public final class LightGramMediaCenterController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var cacheSizeString: String = "Calculating..."
    
    private let categories: [(title: String, icon: String, description: String)] = [
        ("Photos & Images", "🖼", "View, filter and export received photos"),
        ("Videos & Reels", "🎥", "Streamed videos, video notes & recordings"),
        ("Documents & Files", "📁", "PDFs, archives, code and attachments"),
        ("Voice Messages", "🎙", "Audio notes & voice recordings"),
        ("Shared Links", "🔗", "Web links, previews and external articles"),
        ("Music & Audio Tracks", "🎵", "High-fidelity tracks and podcasts")
    ]
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = LightGramStrings.tr("MediaCenter_Title")
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
        self.calculateCacheSize()
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
    
    private func calculateCacheSize() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let fileManager = FileManager.default
            var totalBytes: Int64 = 0
            if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                if let enumerator = fileManager.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) {
                    for case let fileURL as URL in enumerator {
                        if let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let size = attrs.fileSize {
                            totalBytes += Int64(size)
                        }
                    }
                }
            }
            
            let formatted: String
            if totalBytes < 1024 * 1024 {
                formatted = String(format: "%.1f KB", Double(totalBytes) / 1024.0)
            } else if totalBytes < 1024 * 1024 * 1024 {
                formatted = String(format: "%.1f MB", Double(totalBytes) / (1024.0 * 1024.0))
            } else {
                formatted = String(format: "%.2f GB", Double(totalBytes) / (1024.0 * 1024.0 * 1024.0))
            }
            
            DispatchQueue.main.async {
                self?.cacheSizeString = formatted
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return self.categories.count
        } else {
            return 2
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Storage Usage"
        } else if section == 1 {
            return "Media Library Categories"
        } else {
            return "Quick Actions"
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "StorageCell")
            cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = LightGramDesignSystem.Typography.headline
            cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.signatureYellow
            cell.detailTextLabel?.font = LightGramDesignSystem.Typography.bodyMedium
            cell.textLabel?.text = "💾 Total Cached Media"
            cell.detailTextLabel?.text = self.cacheSizeString
            cell.selectionStyle = .none
            return cell
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "CategoryCell")
            cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = LightGramDesignSystem.Typography.headline
            cell.detailTextLabel?.textColor = LightGramDesignSystem.Colors.textSecondary
            
            let item = self.categories[indexPath.row]
            cell.textLabel?.text = "\(item.icon)  \(item.title)"
            cell.detailTextLabel?.text = item.description
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "ActionCell")
            cell.backgroundColor = LightGramDesignSystem.Colors.cardSurface
            cell.textLabel?.font = LightGramDesignSystem.Typography.headline
            if indexPath.row == 0 {
                cell.textLabel?.text = "🧹 Clear Local Media Cache"
                cell.textLabel?.textColor = LightGramDesignSystem.Colors.deletedRed
            } else {
                cell.textLabel?.text = "⚡ Optimize Media Bandwidth"
                cell.textLabel?.textColor = LightGramDesignSystem.Colors.signatureYellow
            }
            cell.selectionStyle = .default
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 && indexPath.row == 0 {
            let alert = UIAlertController(title: "Clear Media Cache", message: "This will remove locally cached media to free up disk space. Media can be downloaded again from Telegram at any time.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Clear All Cached Media", style: .destructive, handler: { [weak self] _ in
                DispatchQueue.global(qos: .utility).async {
                    let fileManager = FileManager.default
                    if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                        let contents = (try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)) ?? []
                        for url in contents {
                            try? fileManager.removeItem(at: url)
                        }
                    }
                    DispatchQueue.main.async {
                        LightGramDesignSystem.Haptics.notification(.success)
                        self?.calculateCacheSize()
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        } else if indexPath.section == 1 {
            let item = self.categories[indexPath.row]
            let alert = UIAlertController(title: item.title, message: "Category index for \(item.title) will filter messages containing this media type across all conversations.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
