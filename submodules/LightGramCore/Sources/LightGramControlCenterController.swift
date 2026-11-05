import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import AccountContext
import PresentationDataUtils
import AlertUI

public final class LightGramControlCenterController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let context: AccountContext?
    private var dashboardHeaderView: LightGramDashboardTilesHeaderView?
    
    private var sections: [(title: String, items: [(title: String, subtitle: String, icon: String, destination: String)])] {
        return [
            (LightGramStrings.tr("GhostMode_Header"), [
                (LightGramStrings.tr("GhostMode"), LightGramStrings.tr("GhostMode_Master_Desc"), "👻", "ghost"),
                (LightGramStrings.tr("SpyMode"), LightGramStrings.tr("SpyMode_Master_Desc"), "🕵️‍♂️", "spy"),
                (LightGramStrings.tr("CircleStudio_Title"), LightGramStrings.tr("CircleStudio_Header"), "⭕", "circles"),
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
                ("Network Diagnostics", "Live DC ping RTT & NWConnection status", "📶", "diagnostics")
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
        self.view.backgroundColor = LightGramDesignSystem.Colors.amoledBlack
        self.setupViews()
    }
    
    private func setupViews() {
        self.tableView.backgroundColor = LightGramDesignSystem.Colors.amoledBlack
        self.tableView.separatorColor = LightGramDesignSystem.Colors.borderGraphite
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        let header = LightGramDashboardTilesHeaderView(width: UIScreen.main.bounds.width) { [weak self] action in
            self?.handleTileAction(action)
        }
        self.dashboardHeaderView = header
        self.tableView.tableHeaderView = header
        self.view.insertSubview(self.tableView, at: 0)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topOffset = self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)
        self.tableView.frame = CGRect(x: 0, y: topOffset, width: layout.size.width, height: max(0, layout.size.height - topOffset))
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: layout.intrinsicInsets.bottom, right: 0)
        
        if let header = self.dashboardHeaderView {
            header.updateLayout(width: layout.size.width)
            self.tableView.tableHeaderView = header
        }
    }
    
    private func handleTileAction(_ action: DashboardTileAction) {
        LightGramDesignSystem.Haptics.impact(.medium)
        
        switch action {
        case .oneTime:
            if let context = self.context {
                self.push(LightGramMediaVaultController(context: context, initialFilter: "onetime"))
            } else {
                self.push(LightGramSettingsController(context: self.context))
            }
        case .settings:
            self.push(LightGramSettingsController(context: self.context))
        case .stats:
            if let context = self.context {
                self.push(LightGramStatisticsController(context: context))
            } else {
                self.push(LightGramSettingsController(context: self.context))
            }
        case .favorites:
            if let context = self.context {
                self.push(LightGramMediaVaultController(context: context, initialFilter: "favorites"))
            } else {
                self.push(LightGramSettingsController(context: self.context))
            }
        case .vault:
            if let context = self.context {
                self.push(LightGramMediaVaultController(context: context, initialFilter: "all"))
            } else {
                self.push(LightGramSettingsController(context: self.context))
            }
        case .delete:
            LightGramMediaVaultManager.shared.cleanupTemporaryCache()
            LightGramSettings.shared.manualBadgeCount = 0
            LightGramDesignSystem.Haptics.notification(.success)
            
            if let context = self.context {
                let alert = textAlertController(
                    context: context,
                    title: LightGramStrings.tr("Dashboard_Delete"),
                    text: LightGramStrings.tr("MediaCenter_CacheCleared"),
                    actions: [
                        TextAlertAction(type: .defaultAction, title: LightGramStrings.tr("OK"), action: {})
                    ]
                )
                self.present(alert, in: .window(.root))
            }
        }
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
        case "circles":
            if let context = self.context {
                targetController = LightGramCircleStudioController(context: context)
            } else {
                targetController = LightGramSettingsController(context: self.context)
            }
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

// MARK: - Dashboard 6-Tile Grid Header
public enum DashboardTileAction {
    case oneTime
    case settings
    case stats
    case favorites
    case vault
    case delete
}

private final class LightGramDashboardTilesHeaderView: UIView {
    private let onSelect: (DashboardTileAction) -> Void
    private var tiles: [LightGramTileButton] = []
    
    init(width: CGFloat, onSelect: @escaping (DashboardTileAction) -> Void) {
        self.onSelect = onSelect
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: 320))
        self.backgroundColor = LightGramDesignSystem.Colors.amoledBlack
        
        let tileConfigs: [(icon: String, titleKey: String, subtitle: String, action: DashboardTileAction)] = [
            ("👆", "Dashboard_OneTime", "VO Vault", .oneTime),
            ("⚙️", "Dashboard_Settings", "Preferences", .settings),
            ("📊", "Dashboard_Stats", "Activity", .stats),
            ("❤️", "Dashboard_Favorites", "Favorites", .favorites),
            ("💾", "Dashboard_Vault", "All Media", .vault),
            ("❌", "Dashboard_Delete", "Clean Cache", .delete)
        ]
        
        for config in tileConfigs {
            let tile = LightGramTileButton(icon: config.icon, title: LightGramStrings.tr(config.titleKey), subtitle: config.subtitle) { [weak self] in
                self?.onSelect(config.action)
            }
            self.addSubview(tile)
            self.tiles.append(tile)
        }
        
        self.layoutTiles(width: width)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLayout(width: CGFloat) {
        self.layoutTiles(width: width)
    }
    
    private func layoutTiles(width: CGFloat) {
        let padding: CGFloat = 16.0
        let spacing: CGFloat = 12.0
        let colWidth = (width - padding * 2 - spacing) / 2.0
        let tileHeight: CGFloat = 82.0
        
        for (i, tile) in self.tiles.enumerated() {
            let row = CGFloat(i / 2)
            let col = CGFloat(i % 2)
            let x = padding + col * (colWidth + spacing)
            let y = 14.0 + row * (tileHeight + spacing)
            tile.frame = CGRect(x: x, y: y, width: colWidth, height: tileHeight)
        }
        
        let totalH = 14.0 + 3 * (tileHeight + spacing) + 8.0
        self.frame = CGRect(x: 0, y: 0, width: width, height: totalH)
    }
}

private final class LightGramTileButton: UIControl {
    private let action: () -> Void
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    init(icon: String, title: String, subtitle: String, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        
        self.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        self.layer.cornerRadius = 16.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = LightGramDesignSystem.Colors.borderGraphite.cgColor
        self.layer.masksToBounds = true
        
        self.iconLabel.text = icon
        self.iconLabel.font = UIFont.systemFont(ofSize: 26)
        self.iconLabel.textAlignment = .left
        self.addSubview(self.iconLabel)
        
        self.titleLabel.text = title
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        self.titleLabel.textColor = .white
        self.addSubview(self.titleLabel)
        
        self.subtitleLabel.text = subtitle
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        self.subtitleLabel.textColor = LightGramSettings.signatureYellowAccent
        self.addSubview(self.subtitleLabel)
        
        self.addTarget(self, action: #selector(self.touchDown), for: [.touchDown, .touchDragEnter])
        self.addTarget(self, action: #selector(self.touchUp), for: [.touchUpInside, .touchDragExit, .touchCancel])
        self.addTarget(self, action: #selector(self.tapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.15) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.backgroundColor = LightGramDesignSystem.Colors.cardElevated
        }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.15) {
            self.transform = .identity
            self.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        }
    }
    
    @objc private func tapped() {
        self.action()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.iconLabel.frame = CGRect(x: 14.0, y: 12.0, width: 34.0, height: 34.0)
        let textX = self.iconLabel.frame.maxX + 8.0
        let maxTextW = self.bounds.width - textX - 8.0
        
        self.titleLabel.frame = CGRect(x: textX, y: 18.0, width: maxTextW, height: 20.0)
        self.subtitleLabel.frame = CGRect(x: textX, y: 40.0, width: maxTextW, height: 16.0)
    }
}
