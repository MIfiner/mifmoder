import Foundation
import UIKit
import Display
import TelegramPresentationData
import AccountContext
import SwiftSignalKit
import TelegramCore

public final class LightGramStatisticsController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var snapshot: LightGramStatisticsSnapshot?
    private var selectedPeriod: StatisticsPeriod = .sevenDays
    private var isLoading: Bool = false
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var segmentedControl: UISegmentedControl!
    private var activityIndicator: UIActivityIndicatorView!
    
    // Cards
    private var overviewCard: UIView!
    private var mediaCard: UIView!
    private var hourlyChartCard: UIView!
    private var dailyChartCard: UIView!
    private var topChatsCard: UIView!
    private var analyticsCard: UIView!
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.title = LightGramStrings.tr("Statistics_Title")
        self.navigationItem.title = LightGramStrings.tr("Statistics_Title")
        
        let initialPeriodRaw = LightGramSettings.shared.statsLastPeriod
        self.selectedPeriod = StatisticsPeriod(rawValue: initialPeriodRaw) ?? .sevenDays
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = LightGramSettings.oledBlackBackground
        
        let exportItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(self.exportTapped))
        exportItem.tintColor = LightGramSettings.signatureYellowAccent
        self.navigationItem.rightBarButtonItem = exportItem
        
        self.setupViews()
        self.loadStatistics(forceRefresh: false)
    }
    
    private func setupViews() {
        self.scrollView = UIScrollView(frame: self.view.bounds)
        self.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.scrollView.backgroundColor = LightGramSettings.oledBlackBackground
        self.scrollView.alwaysBounceVertical = true
        self.view.addSubview(self.scrollView)
        
        self.contentView = UIView()
        self.contentView.backgroundColor = LightGramSettings.oledBlackBackground
        self.scrollView.addSubview(self.contentView)
        
        // Segmented Control
        let periods = [
            LightGramStrings.tr("Statistics_7Days"),
            LightGramStrings.tr("Statistics_30Days"),
            LightGramStrings.tr("Statistics_AllTime")
        ]
        self.segmentedControl = UISegmentedControl(items: periods)
        self.segmentedControl.selectedSegmentIndex = self.selectedPeriod.rawValue
        self.segmentedControl.backgroundColor = LightGramSettings.deepGraphiteBackground
        self.segmentedControl.selectedSegmentTintColor = LightGramSettings.signatureYellowAccent
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 13)], for: .selected)
        self.segmentedControl.addTarget(self, action: #selector(self.periodChanged), for: .valueChanged)
        self.contentView.addSubview(self.segmentedControl)
        
        self.activityIndicator = UIActivityIndicatorView(style: .medium)
        self.activityIndicator.color = LightGramSettings.signatureYellowAccent
        self.activityIndicator.hidesWhenStopped = true
        self.contentView.addSubview(self.activityIndicator)
    }
    
    @objc private func periodChanged() {
        guard let newPeriod = StatisticsPeriod(rawValue: self.segmentedControl.selectedSegmentIndex) else { return }
        self.selectedPeriod = newPeriod
        LightGramSettings.shared.statsLastPeriod = newPeriod.rawValue
        self.loadStatistics(forceRefresh: false)
    }
    
    private func loadStatistics(forceRefresh: Bool) {
        self.isLoading = true
        self.activityIndicator.startAnimating()
        
        LightGramStatisticsManager.shared.fetchStatistics(account: self.context.account, period: self.selectedPeriod, forceRefresh: forceRefresh) { [weak self] snapshot in
            guard let self = self else { return }
            self.isLoading = false
            self.activityIndicator.stopAnimating()
            self.snapshot = snapshot
            self.renderDashboard(snapshot: snapshot)
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topInset = (self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)) + 10.0
        let width = layout.size.width
        let padding: CGFloat = 16.0
        
        self.segmentedControl.frame = CGRect(x: padding, y: topInset, width: width - padding * 2, height: 36)
        self.activityIndicator.center = CGPoint(x: width / 2, y: topInset + 60)
        self.scrollView.frame = CGRect(x: 0, y: topInset + 46, width: width, height: max(0, layout.size.height - (topInset + 46)))
        
        if let s = self.snapshot {
            self.renderDashboard(snapshot: s)
        }
    }
    
    private func renderDashboard(snapshot: LightGramStatisticsSnapshot) {
        // Clear previous cards
        self.overviewCard?.removeFromSuperview()
        self.mediaCard?.removeFromSuperview()
        self.hourlyChartCard?.removeFromSuperview()
        self.dailyChartCard?.removeFromSuperview()
        self.topChatsCard?.removeFromSuperview()
        self.analyticsCard?.removeFromSuperview()
        
        let width = self.view.bounds.width
        let padding: CGFloat = 16.0
        let cardWidth = width - padding * 2
        var currentY = self.segmentedControl.frame.maxY + 16.0
        
        // 1. OVERVIEW CARD
        self.overviewCard = self.createCard(frame: CGRect(x: padding, y: currentY, width: cardWidth, height: 180))
        self.renderOverview(in: self.overviewCard, snapshot: snapshot)
        self.contentView.addSubview(self.overviewCard)
        currentY += self.overviewCard.frame.height + 16.0
        
        // 2. MEDIA CARD
        self.mediaCard = self.createCard(frame: CGRect(x: padding, y: currentY, width: cardWidth, height: 130))
        self.renderMediaBreakdown(in: self.mediaCard, snapshot: snapshot)
        self.contentView.addSubview(self.mediaCard)
        currentY += self.mediaCard.frame.height + 16.0
        
        // 3. HOURLY ACTIVITY CHART
        self.hourlyChartCard = self.createCard(frame: CGRect(x: padding, y: currentY, width: cardWidth, height: 170))
        self.renderHourlyChart(in: self.hourlyChartCard, snapshot: snapshot)
        self.contentView.addSubview(self.hourlyChartCard)
        currentY += self.hourlyChartCard.frame.height + 16.0
        
        // 4. DAILY ACTIVITY CHART
        if !snapshot.dailyActivityCounts.isEmpty {
            self.dailyChartCard = self.createCard(frame: CGRect(x: padding, y: currentY, width: cardWidth, height: 160))
            self.renderDailyChart(in: self.dailyChartCard, snapshot: snapshot)
            self.contentView.addSubview(self.dailyChartCard)
            currentY += self.dailyChartCard.frame.height + 16.0
        }
        
        // 5. TOP CHATS CARD
        if !snapshot.topChats.isEmpty {
            let chatHeight: CGFloat = CGFloat(snapshot.topChats.count * 48 + 48)
            self.topChatsCard = self.createCard(frame: CGRect(x: padding, y: currentY, width: cardWidth, height: chatHeight))
            self.renderTopChats(in: self.topChatsCard, snapshot: snapshot)
            self.contentView.addSubview(self.topChatsCard)
            currentY += self.topChatsCard.frame.height + 16.0
        }
        
        // 6. ADVANCED ANALYTICS CARD
        self.analyticsCard = self.createCard(frame: CGRect(x: padding, y: currentY, width: cardWidth, height: 190))
        self.renderAnalytics(in: self.analyticsCard, snapshot: snapshot)
        self.contentView.addSubview(self.analyticsCard)
        currentY += self.analyticsCard.frame.height + 30.0
        
        self.contentView.frame = CGRect(x: 0, y: 0, width: width, height: currentY)
        self.scrollView.contentSize = CGSize(width: width, height: currentY)
    }
    
    private func createCard(frame: CGRect) -> UIView {
        let card = UIView(frame: frame)
        card.backgroundColor = LightGramSettings.cardSurfaceColor
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1.0
        card.layer.borderColor = LightGramSettings.borderGraphiteColor.cgColor
        card.clipsToBounds = true
        return card
    }
    
    // MARK: - Overview Section
    private func renderOverview(in card: UIView, snapshot: LightGramStatisticsSnapshot) {
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 14, width: card.bounds.width - 32, height: 18))
        headerLabel.text = LightGramStrings.tr("Statistics_Header")
        headerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        headerLabel.textColor = LightGramSettings.signatureYellowAccent
        card.addSubview(headerLabel)
        
        let colW = (card.bounds.width - 48) / 2
        let rowH: CGFloat = 60
        
        let items: [(title: String, val: String, icon: String)] = [
            (LightGramStrings.tr("Statistics_Sent"), "\(snapshot.sentMessagesCount)", "arrow.up.circle.fill"),
            (LightGramStrings.tr("Statistics_Received"), "\(snapshot.receivedMessagesCount)", "arrow.down.circle.fill"),
            (LightGramStrings.tr("Statistics_Total"), "\(snapshot.totalMessagesCount)", "message.fill"),
            (LightGramStrings.tr("Statistics_ActiveChats"), "\(snapshot.activeChatsCount)", "bubble.left.and.bubble.right.fill")
        ]
        
        for (i, item) in items.enumerated() {
            let col = CGFloat(i % 2)
            let row = CGFloat(i / 2)
            let x = 16 + col * (colW + 16)
            let y = 40 + row * (rowH + 8)
            
            let valLabel = UILabel(frame: CGRect(x: x, y: y, width: colW, height: 26))
            valLabel.text = item.val
            valLabel.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
            valLabel.textColor = .white
            card.addSubview(valLabel)
            
            let descLabel = UILabel(frame: CGRect(x: x, y: y + 26, width: colW, height: 16))
            descLabel.text = item.title
            descLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            descLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
            card.addSubview(descLabel)
        }
    }
    
    // MARK: - Media Section
    private func renderMediaBreakdown(in card: UIView, snapshot: LightGramStatisticsSnapshot) {
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 12, width: card.bounds.width - 32, height: 18))
        headerLabel.text = LightGramStrings.tr("Statistics_MediaHeader")
        headerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        headerLabel.textColor = LightGramSettings.signatureYellowAccent
        card.addSubview(headerLabel)
        
        let mediaItems: [(title: String, val: String, color: UIColor)] = [
            (LightGramStrings.tr("Statistics_Photos"), "\(snapshot.photosCount)", UIColor(rgb: 0x30D158)),
            (LightGramStrings.tr("Statistics_Videos"), "\(snapshot.videosCount)", UIColor(rgb: 0x0A84FF)),
            (LightGramStrings.tr("Statistics_Circles"), "\(snapshot.circlesCount)", LightGramSettings.signatureYellowAccent),
            (LightGramStrings.tr("Statistics_Voice"), "\(snapshot.voiceCount)", UIColor(rgb: 0xBF5AF2)),
            (LightGramStrings.tr("Statistics_Files"), "\(snapshot.filesCount)", UIColor(rgb: 0xFF9F0A))
        ]
        
        let itemW = (card.bounds.width - 32) / CGFloat(mediaItems.count)
        for (i, m) in mediaItems.enumerated() {
            let x = 16 + CGFloat(i) * itemW
            let valLabel = UILabel(frame: CGRect(x: x, y: 44, width: itemW, height: 24))
            valLabel.text = m.val
            valLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            valLabel.textColor = m.color
            valLabel.textAlignment = .center
            card.addSubview(valLabel)
            
            let titleLabel = UILabel(frame: CGRect(x: x, y: 70, width: itemW, height: 28))
            titleLabel.text = m.title
            titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
            titleLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 2
            card.addSubview(titleLabel)
        }
    }
    
    // MARK: - Hourly Chart
    private func renderHourlyChart(in card: UIView, snapshot: LightGramStatisticsSnapshot) {
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 12, width: card.bounds.width - 32, height: 18))
        headerLabel.text = LightGramStrings.tr("Statistics_HourlyHeader")
        headerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        headerLabel.textColor = LightGramSettings.signatureYellowAccent
        card.addSubview(headerLabel)
        
        let chartX: CGFloat = 16
        let chartY: CGFloat = 40
        let chartW = card.bounds.width - 32
        let chartH: CGFloat = 85
        
        let maxVal = max(snapshot.hourlyActivity.max() ?? 1, 1)
        let barW = (chartW / 24.0) - 2.0
        
        for hour in 0..<24 {
            let count = snapshot.hourlyActivity[hour]
            let normalizedH = CGFloat(count) / CGFloat(maxVal) * chartH
            let x = chartX + CGFloat(hour) * (barW + 2.0)
            let y = chartY + (chartH - normalizedH)
            
            let barView = UIView(frame: CGRect(x: x, y: y, width: barW, height: max(normalizedH, 2.0)))
            barView.backgroundColor = (count == maxVal && count > 0) ? LightGramSettings.signatureYellowAccent : UIColor(white: 0.3, alpha: 1.0)
            barView.layer.cornerRadius = 1.5
            card.addSubview(barView)
        }
        
        // Hour markers: 00, 06, 12, 18, 23
        let markers = [0, 6, 12, 18, 23]
        for m in markers {
            let x = chartX + CGFloat(m) * (barW + 2.0) - 6
            let lbl = UILabel(frame: CGRect(x: x, y: chartY + chartH + 6, width: 20, height: 12))
            lbl.text = String(format: "%02d", m)
            lbl.font = UIFont.systemFont(ofSize: 8, weight: .medium)
            lbl.textColor = UIColor(white: 0.5, alpha: 1.0)
            lbl.textAlignment = .center
            card.addSubview(lbl)
        }
    }
    
    // MARK: - Daily Chart
    private func renderDailyChart(in card: UIView, snapshot: LightGramStatisticsSnapshot) {
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 12, width: card.bounds.width - 32, height: 18))
        headerLabel.text = LightGramStrings.tr("Statistics_DailyHeader")
        headerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        headerLabel.textColor = LightGramSettings.signatureYellowAccent
        card.addSubview(headerLabel)
        
        let chartX: CGFloat = 16
        let chartY: CGFloat = 40
        let chartW = card.bounds.width - 32
        let chartH: CGFloat = 75
        
        let countBars = snapshot.dailyActivityCounts.count
        guard countBars > 0 else { return }
        
        let maxVal = max(snapshot.dailyActivityCounts.max() ?? 1, 1)
        let barW = (chartW / CGFloat(countBars)) - 8.0
        
        for i in 0..<countBars {
            let count = snapshot.dailyActivityCounts[i]
            let label = snapshot.dailyActivityLabels[i]
            let normalizedH = CGFloat(count) / CGFloat(maxVal) * chartH
            let x = chartX + CGFloat(i) * (barW + 8.0) + 4.0
            let y = chartY + (chartH - normalizedH)
            
            let barView = UIView(frame: CGRect(x: x, y: y, width: barW, height: max(normalizedH, 3.0)))
            barView.backgroundColor = (count == maxVal && count > 0) ? LightGramSettings.signatureYellowAccent : UIColor(white: 0.35, alpha: 1.0)
            barView.layer.cornerRadius = 2
            card.addSubview(barView)
            
            let lbl = UILabel(frame: CGRect(x: x - 4, y: chartY + chartH + 6, width: barW + 8, height: 14))
            lbl.text = label
            lbl.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            lbl.textColor = UIColor(white: 0.6, alpha: 1.0)
            lbl.textAlignment = .center
            card.addSubview(lbl)
        }
    }
    
    // MARK: - Top Chats
    private func renderTopChats(in card: UIView, snapshot: LightGramStatisticsSnapshot) {
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 12, width: card.bounds.width - 32, height: 18))
        headerLabel.text = LightGramStrings.tr("Statistics_TopChatsHeader")
        headerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        headerLabel.textColor = LightGramSettings.signatureYellowAccent
        card.addSubview(headerLabel)
        
        var y: CGFloat = 40
        for (i, chat) in snapshot.topChats.enumerated() {
            let rowView = UIView(frame: CGRect(x: 16, y: y, width: card.bounds.width - 32, height: 44))
            
            // Rank Badge
            let rankLabel = UILabel(frame: CGRect(x: 0, y: 12, width: 22, height: 20))
            rankLabel.text = "#\(i + 1)"
            rankLabel.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
            rankLabel.textColor = i == 0 ? LightGramSettings.signatureYellowAccent : UIColor(white: 0.5, alpha: 1.0)
            rowView.addSubview(rankLabel)
            
            // Chat Title
            let titleLabel = UILabel(frame: CGRect(x: 28, y: 4, width: rowView.bounds.width - 130, height: 18))
            titleLabel.text = chat.title
            titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            titleLabel.textColor = .white
            rowView.addSubview(titleLabel)
            
            // Progress Bar
            let barBg = UIView(frame: CGRect(x: 28, y: 26, width: rowView.bounds.width - 130, height: 4))
            barBg.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            barBg.layer.cornerRadius = 2
            rowView.addSubview(barBg)
            
            let barFg = UIView(frame: CGRect(x: 28, y: 26, width: (rowView.bounds.width - 130) * CGFloat(chat.percentage / 100.0), height: 4))
            barFg.backgroundColor = LightGramSettings.signatureYellowAccent
            barFg.layer.cornerRadius = 2
            rowView.addSubview(barFg)
            
            // Message Count & Percent Badge
            let countLabel = UILabel(frame: CGRect(x: rowView.bounds.width - 95, y: 10, width: 95, height: 24))
            countLabel.text = "\(chat.messageCount) (\(chat.percentage)%)"
            countLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            countLabel.textColor = LightGramSettings.signatureYellowAccent
            countLabel.textAlignment = .right
            rowView.addSubview(countLabel)
            
            // Tap gesture to open chat
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.topChatTapped(_:)))
            rowView.tag = Int(chat.peerId)
            rowView.isUserInteractionEnabled = true
            rowView.addGestureRecognizer(tap)
            
            card.addSubview(rowView)
            y += 48
        }
    }
    
    @objc private func topChatTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        let peerId = EnginePeer.Id(Int64(view.tag))
        let _ = (self.context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
                 |> deliverOnMainQueue).start(next: { [weak self] peer in
            guard let self = self, let peer = peer, let navigationController = self.navigationController as? NavigationController else { return }
            self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(
                navigationController: navigationController,
                context: self.context,
                chatLocation: .peer(peer),
                subject: nil,
                useExisting: true
            ))
        })
    }
    
    // MARK: - Advanced Analytics
    private func renderAnalytics(in card: UIView, snapshot: LightGramStatisticsSnapshot) {
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 12, width: card.bounds.width - 32, height: 18))
        headerLabel.text = LightGramStrings.tr("Statistics_AnalyticsHeader")
        headerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        headerLabel.textColor = LightGramSettings.signatureYellowAccent
        card.addSubview(headerLabel)
        
        let stats: [(String, String)] = [
            (LightGramStrings.tr("Statistics_PeakHour"), snapshot.peakHourLabel),
            (LightGramStrings.tr("Statistics_PeakDay"), snapshot.peakDayLabel),
            (LightGramStrings.tr("Statistics_AvgDay"), "\(snapshot.averageMessagesPerDay)"),
            (LightGramStrings.tr("Statistics_SavedDeleted"), "\(snapshot.deletedMessagesCount)"),
            (LightGramStrings.tr("Statistics_SavedEdits"), "\(snapshot.editedRevisionsCount)"),
            (LightGramStrings.tr("Statistics_VaultItems"), "\(snapshot.vaultItemsCount) (\(snapshot.vaultStorageFormatted))")
        ]
        
        let colW = (card.bounds.width - 48) / 2
        for (i, item) in stats.enumerated() {
            let col = CGFloat(i % 2)
            let row = CGFloat(i / 2)
            let x = 16 + col * (colW + 16)
            let y = 38 + row * 44
            
            let valLbl = UILabel(frame: CGRect(x: x, y: y, width: colW, height: 20))
            valLbl.text = item.1
            valLbl.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            valLbl.textColor = .white
            card.addSubview(valLbl)
            
            let descLbl = UILabel(frame: CGRect(x: x, y: y + 20, width: colW, height: 14))
            descLbl.text = item.0
            descLbl.font = UIFont.systemFont(ofSize: 11, weight: .regular)
            descLbl.textColor = UIColor(white: 0.6, alpha: 1.0)
            card.addSubview(descLbl)
        }
    }
    
    // MARK: - Export PNG & PDF
    @objc private func exportTapped() {
        let alert = UIAlertController(title: LightGramStrings.tr("Statistics_Title"), message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: LightGramStrings.tr("Statistics_ExportPNG"), style: .default, handler: { [weak self] _ in
            self?.exportImage()
        }))
        alert.addAction(UIAlertAction(title: LightGramStrings.tr("Statistics_ExportPDF"), style: .default, handler: { [weak self] _ in
            self?.exportPDF()
        }))
        alert.addAction(UIAlertAction(title: LightGramStrings.tr("Cancel"), style: .cancel))
        self.present(alert, animated: true)
    }
    
    private func exportImage() {
        let renderer = UIGraphicsImageRenderer(bounds: self.contentView.bounds)
        let image = renderer.image { ctx in
            self.contentView.layer.render(in: ctx.cgContext)
        }
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        self.present(activity, animated: true)
    }
    
    private func exportPDF() {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, self.contentView.bounds, nil)
        UIGraphicsBeginPDFPageWithInfo(self.contentView.bounds, nil)
        if let pdfContext = UIGraphicsGetCurrentContext() {
            self.contentView.layer.render(in: pdfContext)
        }
        UIGraphicsEndPDFContext()
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("LightGram_Statistics_Report.pdf")
        pdfData.write(to: tempURL, atomically: true)
        
        let activity = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        self.present(activity, animated: true)
    }
}
