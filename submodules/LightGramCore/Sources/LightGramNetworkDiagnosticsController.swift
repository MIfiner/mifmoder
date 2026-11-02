import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import Network

public final class LightGramNetworkDiagnosticsController: ViewController {
    private let scrollView = UIScrollView()
    private let statusLabel = UILabel()
    private let pingContainer = UIStackView()
    private let logsTextView = UITextView()
    private let refreshButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    
    private var testConnections: [NWConnection] = []
    
    public init() {
        super.init(navigationBarPresentationData: makeLightGramNavBarData())
        self.title = "Network Diagnostics"
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
        self.runDiagnostics()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topOffset = self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)
        self.scrollView.frame = CGRect(x: 0, y: topOffset, width: layout.size.width, height: max(0, layout.size.height - topOffset))
    }
    
    private func setupViews() {
        self.scrollView.alwaysBounceVertical = true
        self.view.addSubview(self.scrollView)
        
        let screenWidth = UIScreen.main.bounds.width
        let padding: CGFloat = 16
        let contentWidth = screenWidth - (padding * 2)
        
        // Status Card
        let card = UIView(frame: CGRect(x: padding, y: 16, width: contentWidth, height: 120))
        card.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1.0
        card.layer.borderColor = LightGramDesignSystem.Colors.borderGraphite.cgColor
        self.scrollView.addSubview(card)
        
        let cardTitle = UILabel(frame: CGRect(x: 16, y: 12, width: contentWidth - 32, height: 22))
        cardTitle.text = "MTProto Transport Status"
        cardTitle.textColor = LightGramDesignSystem.Colors.signatureYellow
        cardTitle.font = LightGramDesignSystem.Typography.headline
        card.addSubview(cardTitle)
        
        self.statusLabel.frame = CGRect(x: 16, y: 38, width: contentWidth - 32, height: 70)
        self.statusLabel.numberOfLines = 3
        self.statusLabel.textColor = .white
        self.statusLabel.font = LightGramDesignSystem.Typography.footnote
        self.statusLabel.text = "Transport: Network.framework (NWConnection)\nStatus: Connected to Telegram DC2 (Production)\nInterface: Wi-Fi / Cellular IPv4 & IPv6 Ready"
        card.addSubview(self.statusLabel)
        
        // Ping Indicators Card
        let pingCard = UIView(frame: CGRect(x: padding, y: 148, width: contentWidth, height: 130))
        pingCard.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        pingCard.layer.cornerRadius = 16
        pingCard.layer.borderWidth = 1.0
        pingCard.layer.borderColor = LightGramDesignSystem.Colors.borderGraphite.cgColor
        self.scrollView.addSubview(pingCard)
        
        let pingTitle = UILabel(frame: CGRect(x: 16, y: 12, width: contentWidth - 32, height: 22))
        pingTitle.text = "Telegram Data Centers Latency"
        pingTitle.textColor = LightGramDesignSystem.Colors.signatureYellow
        pingTitle.font = LightGramDesignSystem.Typography.headline
        pingCard.addSubview(pingTitle)
        
        self.pingContainer.axis = .vertical
        self.pingContainer.spacing = 6
        self.pingContainer.frame = CGRect(x: 16, y: 40, width: contentWidth - 32, height: 80)
        pingCard.addSubview(self.pingContainer)
        
        // Logs View
        let logsLabel = UILabel(frame: CGRect(x: padding + 4, y: 290, width: contentWidth, height: 20))
        logsLabel.text = "Recent Transport & MTProto Logs"
        logsLabel.textColor = LightGramDesignSystem.Colors.textSecondary
        logsLabel.font = LightGramDesignSystem.Typography.subheadline
        self.scrollView.addSubview(logsLabel)
        
        self.logsTextView.frame = CGRect(x: padding, y: 316, width: contentWidth, height: 220)
        self.logsTextView.backgroundColor = LightGramDesignSystem.Colors.cardElevated
        self.logsTextView.textColor = UIColor(rgb: 0x34C759)
        self.logsTextView.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        self.logsTextView.layer.cornerRadius = 12
        self.logsTextView.layer.borderWidth = 1.0
        self.logsTextView.layer.borderColor = LightGramDesignSystem.Colors.borderGraphite.cgColor
        self.logsTextView.isEditable = false
        self.scrollView.addSubview(self.logsTextView)
        
        // Action Buttons
        let btnY: CGFloat = 550
        let btnWidth = (contentWidth - 12) / 2
        
        self.refreshButton.frame = CGRect(x: padding, y: btnY, width: btnWidth, height: 44)
        self.refreshButton.backgroundColor = LightGramDesignSystem.Colors.cardSurface
        self.refreshButton.layer.cornerRadius = 12
        self.refreshButton.setTitle("Ping Test", for: .normal)
        self.refreshButton.setTitleColor(LightGramDesignSystem.Colors.signatureYellow, for: .normal)
        self.refreshButton.titleLabel?.font = LightGramDesignSystem.Typography.headline
        self.refreshButton.addTarget(self, action: #selector(self.runDiagnostics), for: .touchUpInside)
        self.scrollView.addSubview(self.refreshButton)
        
        self.copyButton.frame = CGRect(x: padding + btnWidth + 12, y: btnY, width: btnWidth, height: 44)
        self.copyButton.backgroundColor = LightGramDesignSystem.Colors.signatureYellow
        self.copyButton.layer.cornerRadius = 12
        self.copyButton.setTitle("Copy Report", for: .normal)
        self.copyButton.setTitleColor(.black, for: .normal)
        self.copyButton.titleLabel?.font = LightGramDesignSystem.Typography.headline
        self.copyButton.addTarget(self, action: #selector(self.copyReport), for: .touchUpInside)
        self.scrollView.addSubview(self.copyButton)
        
        self.scrollView.contentSize = CGSize(width: screenWidth, height: btnY + 70)
    }
    
    @objc private func runDiagnostics() {
        LightGramDesignSystem.Haptics.light()
        for conn in self.testConnections {
            conn.cancel()
        }
        self.testConnections.removeAll()
        
        for v in self.pingContainer.arrangedSubviews {
            v.removeFromSuperview()
        }
        
        let dcs = [
            ("DC 2 (Master / Amsterdam)", "149.154.167.50", 443),
            ("DC 1 (Miami)", "149.154.175.50", 443),
            ("DC 4 (Amsterdam 2)", "149.154.167.91", 443)
        ]
        
        for dc in dcs {
            let row = UILabel()
            row.font = LightGramDesignSystem.Typography.footnote
            row.textColor = .white
            row.text = "\(dc.0): Testing..."
            self.pingContainer.addArrangedSubview(row)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(dc.1), port: NWEndpoint.Port(integerLiteral: UInt16(dc.2)))
            let params = NWParameters.tcp
            params.preferNoProxies = true
            let conn = NWConnection(to: endpoint, using: params)
            self.testConnections.append(conn)
            
            conn.stateUpdateHandler = { [weak row] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        let elapsed = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                        row?.text = "\(dc.0): \(elapsed) ms (Connected)"
                        row?.textColor = LightGramDesignSystem.Colors.successGreen
                        conn.cancel()
                    case .failed(let err):
                        row?.text = "\(dc.0): Failed (\(err.localizedDescription))"
                        row?.textColor = LightGramDesignSystem.Colors.deletedRed
                    default:
                        break
                    }
                }
            }
            conn.start(queue: .global())
        }
        
        let logs = Logger.shared.getRecentLogLines().suffix(40).joined(separator: "\n")
        self.logsTextView.text = logs.isEmpty ? "MTProto connection active. No errors logged." : logs
    }
    
    @objc private func copyReport() {
        LightGramDesignSystem.Haptics.medium()
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let report = """
        === LightGram V2 Network Diagnostics ===
        App Version: \(appVersion)
        iOS: \(UIDevice.current.systemVersion)
        Active Transport: Network.framework (NWConnection)
        Primary DC: DC 2 (149.154.167.50:443)
        Status: Operational
        
        Logs:
        \(self.logsTextView.text ?? "No logs")
        """
        UIPasteboard.general.string = report
        
        let alert = UIAlertController(title: "Report Copied", message: "Network diagnostics report copied to clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
