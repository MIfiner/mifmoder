import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import Network

public final class LightGramDiagnosticsController: ViewController {
    private let presentationData: PresentationData
    private var textView: UITextView?
    private var statusLabel: UILabel?
    private var pingStatusLabel: UILabel?
    private var testButton: UIButton?
    private var shareButton: UIButton?
    private var testConnections: [NWConnection] = []
    
    public init(presentationData: PresentationData) {
        self.presentationData = presentationData
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(theme: AuthorizationSequenceController.navigationBarTheme(presentationData.theme), strings: NavigationBarStrings(presentationStrings: presentationData.strings)))
        
        self.title = "Network Diagnostics"
        self.statusBar.statusBarStyle = presentationData.theme.intro.statusBarStyle.style
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: presentationData.strings.Common_Close, style: .plain, target: self, action: #selector(self.closePressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Copy", style: .done, target: self, action: #selector(self.copyPressed))
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        for conn in self.testConnections {
            conn.cancel()
        }
    }
    
    @objc private func closePressed() {
        self.dismiss()
    }
    
    @objc private func copyPressed() {
        let fullReport = self.generateFullReport()
        UIPasteboard.general.string = fullReport
        
        let alert = UIAlertController(title: "Copied", message: "Network diagnostics copied to clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func sharePressed() {
        let fullReport = self.generateFullReport()
        let activityController = UIActivityViewController(activityItems: [fullReport], applicationActivities: nil)
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        self.present(activityController, animated: true, completion: nil)
    }
    
    private func generateFullReport() -> String {
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let bundleId = Bundle.main.bundleIdentifier ?? "site.lightgram.ios"
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let model = device.model
        let logLines = Logger.shared.getRecentLogLines()
        
        var report = """
        === LightGram V1 Network Diagnostic Report ===
        App Version: \(appVersion)
        Bundle ID: \(bundleId)
        Device: \(model) (iOS \(systemVersion))
        Timestamp: \(Date())
        
        === Telegram Endpoints ===
        Active DC: DC 2 (149.154.167.50:443)
        Seed DC 1: 149.154.175.50:443
        Seed DC 4: 149.154.167.91:443
        Seed DC 5: 91.108.56.130:443
        Transport: Network.framework (NWConnection) - Active
        
        === Connectivity Test Results ===
        \(self.pingStatusLabel?.text ?? "Not run yet")
        
        === Recent Network Logs (Total: \(logLines.count) lines) ===
        \(logLines.joined(separator: "\n"))
        """
        return report
    }
    
    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        
        super.loadDisplayNode()
        
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        self.view.addSubview(scrollView)
        
        let container = UIView()
        scrollView.addSubview(container)
        
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = self.presentationData.theme.list.itemPrimaryTextColor
        statusLabel.text = """
        LightGram V1 (\(appVersion)) | iOS \(UIDevice.current.systemVersion)
        Transport: Network.framework (NWConnection)
        Target: Telegram DC 2 (149.154.167.50:443)
        Seeds: DC1 (149.154.175.50), DC4 (149.154.167.91)
        """
        container.addSubview(statusLabel)
        self.statusLabel = statusLabel
        
        let pingStatusLabel = UILabel()
        pingStatusLabel.numberOfLines = 0
        pingStatusLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        pingStatusLabel.textColor = self.presentationData.theme.list.itemSecondaryTextColor
        pingStatusLabel.text = "Testing connectivity to Telegram..."
        container.addSubview(pingStatusLabel)
        self.pingStatusLabel = pingStatusLabel
        
        let testButton = UIButton(type: .system)
        testButton.setTitle("Retest Connection", for: .normal)
        testButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        testButton.addTarget(self, action: #selector(self.runPingTest), for: .touchUpInside)
        container.addSubview(testButton)
        self.testButton = testButton
        
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share Logs", for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        shareButton.addTarget(self, action: #selector(self.sharePressed), for: .touchUpInside)
        container.addSubview(shareButton)
        self.shareButton = shareButton
        
        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textColor = self.presentationData.theme.list.itemPrimaryTextColor
        textView.backgroundColor = self.presentationData.theme.list.itemBlocksBackgroundColor
        textView.layer.cornerRadius = 8.0
        textView.layer.masksToBounds = true
        let recentLogs = Logger.shared.getRecentLogLines()
        textView.text = recentLogs.isEmpty ? "No recent log events captured yet." : recentLogs.joined(separator: "\n")
        container.addSubview(textView)
        self.textView = textView
        
        self.runPingTest()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        let bounds = CGRect(origin: CGPoint(), size: layout.size)
        if let scrollView = self.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.frame = bounds
            
            let contentWidth = layout.size.width - 32.0
            let insets = layout.insets(options: [.statusBar, .navBar, .input])
            let topInset = insets.top + 16.0
            
            self.statusLabel?.frame = CGRect(x: 16.0, y: topInset, width: contentWidth, height: 75.0)
            self.pingStatusLabel?.frame = CGRect(x: 16.0, y: topInset + 80.0, width: contentWidth, height: 60.0)
            
            self.testButton?.frame = CGRect(x: 16.0, y: topInset + 145.0, width: 140.0, height: 36.0)
            self.shareButton?.frame = CGRect(x: 16.0 + 150.0, y: topInset + 145.0, width: 100.0, height: 36.0)
            
            let textViewHeight = max(200.0, layout.size.height - (topInset + 195.0) - insets.bottom - 16.0)
            self.textView?.frame = CGRect(x: 16.0, y: topInset + 190.0, width: contentWidth, height: textViewHeight)
            
            scrollView.contentSize = CGSize(width: layout.size.width, height: topInset + 190.0 + textViewHeight + 20.0)
        }
    }
    
    @objc private func runPingTest() {
        for conn in self.testConnections {
            conn.cancel()
        }
        self.testConnections.removeAll()
        self.pingStatusLabel?.text = "Testing connectivity to Telegram DCs..."
        
        let targets: [(String, String, UInt16)] = [
            ("DC2", "149.154.167.50", 443),
            ("DC1", "149.154.175.50", 443),
            ("DC4", "149.154.167.91", 443)
        ]
        
        var results: [String: String] = [:]
        let lock = NSLock()
        
        let updateUI: () -> Void = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                var text = ""
                for target in targets {
                    let res = results[target.0] ?? "Testing..."
                    text += "\(target.0) (\(target.1):443): \(res)\n"
                }
                self.pingStatusLabel?.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        for target in targets {
            let host = NWEndpoint.Host(target.1)
            let port = NWEndpoint.Port(rawValue: target.2)!
            let tcpOptions = NWProtocolTCP.Options()
            tcpOptions.enableFastOpen = false
            let params = NWParameters(tls: nil, tcp: tcpOptions)
            params.preferNoProxies = true
            let conn = NWConnection(host: host, port: port, using: params)
            self.testConnections.append(conn)
            
            let startTime = CACurrentMediaTime()
            conn.stateUpdateHandler = { [weak conn] state in
                let elapsedMs = Int((CACurrentMediaTime() - startTime) * 1000)
                switch state {
                case .ready:
                    lock.lock()
                    results[target.0] = "CONNECTED (\(elapsedMs) ms)"
                    lock.unlock()
                    updateUI()
                    conn?.cancel()
                case let .failed(error):
                    lock.lock()
                    results[target.0] = "FAILED (\(error.localizedDescription))"
                    lock.unlock()
                    updateUI()
                    conn?.cancel()
                case let .waiting(error):
                    lock.lock()
                    results[target.0] = "WAITING (\(error.localizedDescription))"
                    lock.unlock()
                    updateUI()
                default:
                    break
                }
            }
            conn.start(queue: .global(qos: .userInitiated))
        }
    }
}
