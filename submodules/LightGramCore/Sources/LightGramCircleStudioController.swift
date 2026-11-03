import Foundation
import UIKit
import Display
import TelegramPresentationData
import AccountContext
import SwiftSignalKit
import AVFoundation
import AVKit

public final class LightGramCircleStudioController: ViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private var savedCircles: [MediaVaultItem] = []
    private var activePlayer: AVPlayer?
    private var activePlayerLayer: AVPlayerLayer?
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    private var previewContainer: UIView!
    private var playButton: UIButton!
    private var studioCard: UIView!
    private var convertButton: UIButton!
    private var statusLabel: UILabel!
    private var progressView: UIActivityIndicatorView!
    
    private var circlesCollectionView: UICollectionView!
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.title = LightGramStrings.tr("CircleStudio_Title")
        self.navigationItem.title = LightGramStrings.tr("CircleStudio_Title")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.activePlayer?.pause()
        self.activePlayer = nil
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = LightGramSettings.oledBlackBackground
        
        self.setupViews()
        self.loadSavedCircles()
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
        
        // 1. Circular Preview
        self.previewContainer = UIView()
        self.previewContainer.backgroundColor = LightGramSettings.cardSurfaceColor
        self.previewContainer.layer.borderColor = LightGramSettings.signatureYellowAccent.cgColor
        self.previewContainer.layer.borderWidth = 3.0
        self.previewContainer.clipsToBounds = true
        self.contentView.addSubview(self.previewContainer)
        
        self.playButton = UIButton(type: .system)
        self.playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        self.playButton.tintColor = LightGramSettings.signatureYellowAccent
        self.playButton.addTarget(self, action: #selector(self.togglePlay), for: .touchUpInside)
        self.previewContainer.addSubview(self.playButton)
        
        // 2. Studio Action Card
        self.studioCard = UIView()
        self.studioCard.backgroundColor = LightGramSettings.cardSurfaceColor
        self.studioCard.layer.cornerRadius = 16
        self.studioCard.layer.borderWidth = 1.0
        self.studioCard.layer.borderColor = LightGramSettings.borderGraphiteColor.cgColor
        self.contentView.addSubview(self.studioCard)
        
        let cardHeader = UILabel()
        cardHeader.text = LightGramStrings.tr("CircleStudio_Header")
        cardHeader.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        cardHeader.textColor = LightGramSettings.signatureYellowAccent
        self.studioCard.addSubview(cardHeader)
        
        let cardDesc = UILabel()
        cardDesc.text = LightGramStrings.tr("CircleStudio_ConvertDesc")
        cardDesc.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        cardDesc.textColor = UIColor(white: 0.7, alpha: 1.0)
        cardDesc.numberOfLines = 0
        self.studioCard.addSubview(cardDesc)
        
        self.convertButton = UIButton(type: .system)
        self.convertButton.backgroundColor = LightGramSettings.signatureYellowAccent
        self.convertButton.setTitle(LightGramStrings.tr("CircleStudio_Convert"), for: .normal)
        self.convertButton.setTitleColor(.black, for: .normal)
        self.convertButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        self.convertButton.layer.cornerRadius = 20
        self.convertButton.addTarget(self, action: #selector(self.selectVideoForCircle), for: .touchUpInside)
        self.studioCard.addSubview(self.convertButton)
        
        self.progressView = UIActivityIndicatorView(style: .medium)
        self.progressView.color = LightGramSettings.signatureYellowAccent
        self.progressView.hidesWhenStopped = true
        self.studioCard.addSubview(self.progressView)
        
        self.statusLabel = UILabel()
        self.statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.statusLabel.textColor = LightGramSettings.signatureYellowAccent
        self.statusLabel.textAlignment = .center
        self.studioCard.addSubview(self.statusLabel)
        
        // 3. Saved Circles Section
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        self.circlesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.circlesCollectionView.backgroundColor = .clear
        self.circlesCollectionView.delegate = self
        self.circlesCollectionView.dataSource = self
        self.circlesCollectionView.showsHorizontalScrollIndicator = false
        self.circlesCollectionView.register(CircleThumbnailCell.self, forCellWithReuseIdentifier: "CircleThumbnailCell")
        self.contentView.addSubview(self.circlesCollectionView)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topInset = (self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)) + 10.0
        let width = layout.size.width
        let padding: CGFloat = 16.0
        
        // Circular Preview (200x200)
        let circleSize: CGFloat = 200.0
        self.previewContainer.frame = CGRect(x: (width - circleSize) / 2, y: topInset, width: circleSize, height: circleSize)
        self.previewContainer.layer.cornerRadius = circleSize / 2
        self.activePlayerLayer?.frame = self.previewContainer.bounds
        self.playButton.frame = CGRect(x: (circleSize - 60) / 2, y: (circleSize - 60) / 2, width: 60, height: 60)
        
        // Studio Card
        let cardY = self.previewContainer.frame.maxY + 20.0
        let cardW = width - padding * 2
        self.studioCard.frame = CGRect(x: padding, y: cardY, width: cardW, height: 165)
        
        if let header = self.studioCard.subviews.first as? UILabel {
            header.frame = CGRect(x: 16, y: 14, width: cardW - 32, height: 18)
        }
        if self.studioCard.subviews.count > 1, let desc = self.studioCard.subviews[1] as? UILabel {
            desc.frame = CGRect(x: 16, y: 38, width: cardW - 32, height: 36)
        }
        self.convertButton.frame = CGRect(x: 16, y: 84, width: cardW - 32, height: 42)
        self.progressView.center = CGPoint(x: cardW / 2, y: 142)
        self.statusLabel.frame = CGRect(x: 16, y: 132, width: cardW - 32, height: 20)
        
        // Saved Circles Section
        let galleryY = self.studioCard.frame.maxY + 24.0
        self.circlesCollectionView.frame = CGRect(x: 0, y: galleryY, width: width, height: 90)
        
        let totalH = galleryY + 110.0
        self.contentView.frame = CGRect(x: 0, y: 0, width: width, height: totalH)
        self.scrollView.contentSize = CGSize(width: width, height: totalH)
    }
    
    private func loadSavedCircles() {
        self.savedCircles = LightGramMediaVaultManager.shared.getItems(typeFilter: "circle")
        self.circlesCollectionView.reloadData()
        
        if let first = self.savedCircles.first, self.activePlayer == nil {
            self.loadCircleIntoPlayer(item: first)
        }
    }
    
    private func loadCircleIntoPlayer(item: MediaVaultItem) {
        let fileURL = LightGramMediaVaultManager.shared.resolveItemURL(item: item)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        self.activePlayer?.pause()
        self.activePlayerLayer?.removeFromSuperlayer()
        
        let player = AVPlayer(url: fileURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = self.previewContainer.bounds
        self.previewContainer.layer.insertSublayer(playerLayer, below: self.playButton.layer)
        
        self.activePlayer = player
        self.activePlayerLayer = playerLayer
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
            self?.activePlayer?.seek(to: .zero)
            self?.playButton.isHidden = false
        }
    }
    
    @objc private func togglePlay() {
        guard let p = self.activePlayer else { return }
        if p.timeControlStatus == .playing {
            p.pause()
            self.playButton.isHidden = false
        } else {
            p.play()
            self.playButton.isHidden = true
        }
    }
    
    // MARK: - Video Selection & 1:1 Circular Crop
    @objc private func selectVideoForCircle() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = self
        picker.videoMaximumDuration = 60.0
        self.present(picker, animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let videoURL = info[.mediaURL] as? URL else { return }
        self.processAndCropVideo(url: videoURL)
    }
    
    private func processAndCropVideo(url: URL) {
        self.progressView.startAnimating()
        self.convertButton.isEnabled = false
        self.statusLabel.text = LightGramStrings.tr("CircleStudio_Processing")
        
        let asset = AVAsset(url: url)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            self.finishProcessing(success: false, message: "No video track found")
            return
        }
        
        let duration = min(CMTimeGetSeconds(asset.duration), 60.0)
        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))
        
        let naturalSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let cropSide = min(abs(naturalSize.width), abs(naturalSize.height))
        let targetSize = CGSize(width: cropSide, height: cropSide)
        
        let composition = AVMutableComposition()
        guard let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            self.finishProcessing(success: false, message: "Export composition error")
            return
        }
        
        try? compTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        
        // Add Audio track if available
        if let audioTrack = asset.tracks(withMediaType: .audio).first,
           let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compAudio.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = targetSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
        let tx = (cropSide - abs(naturalSize.width)) / 2.0
        let ty = (cropSide - abs(naturalSize.height)) / 2.0
        let transform = videoTrack.preferredTransform.concatenating(CGAffineTransform(translationX: tx, y: ty))
        layerInstruction.setTransform(transform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        let tempExportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("circle_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: tempExportURL)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            self.finishProcessing(success: false, message: "Export session failed")
            return
        }
        
        exportSession.outputURL = tempExportURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    LightGramMediaVaultManager.shared.saveDirectFile(
                        sourceURL: tempExportURL,
                        fileName: "Circle_\(Int(Date().timeIntervalSince1970)).mp4",
                        mediaType: "circle",
                        chatTitle: "Circle Studio",
                        authorName: "Self",
                        isOneTime: false,
                        duration: duration,
                        dimensions: "\(Int(cropSide))x\(Int(cropSide))"
                    ) { success, _ in
                        self?.finishProcessing(success: success, message: LightGramStrings.tr("CircleStudio_Success"))
                        self?.loadSavedCircles()
                    }
                } else {
                    self?.finishProcessing(success: false, message: exportSession.error?.localizedDescription ?? "Crop failed")
                }
            }
        }
    }
    
    private func finishProcessing(success: Bool, message: String) {
        self.progressView.stopAnimating()
        self.convertButton.isEnabled = true
        self.statusLabel.text = message
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.savedCircles.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CircleThumbnailCell", for: indexPath) as? CircleThumbnailCell else {
            return UICollectionViewCell()
        }
        let item = self.savedCircles[indexPath.item]
        cell.configure(with: item)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.savedCircles[indexPath.item]
        self.loadCircleIntoPlayer(item: item)
        self.activePlayer?.play()
        self.playButton.isHidden = true
    }
}

// MARK: - CircleThumbnailCell
final class CircleThumbnailCell: UICollectionViewCell {
    private let circleView = UIView()
    private let iconView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.circleView.frame = self.bounds
        self.circleView.backgroundColor = LightGramSettings.cardSurfaceColor
        self.circleView.layer.cornerRadius = self.bounds.width / 2
        self.circleView.layer.borderColor = LightGramSettings.signatureYellowAccent.cgColor
        self.circleView.layer.borderWidth = 1.5
        self.circleView.clipsToBounds = true
        self.contentView.addSubview(self.circleView)
        
        self.iconView.image = UIImage(systemName: "record.circle.fill")
        self.iconView.tintColor = LightGramSettings.signatureYellowAccent
        self.iconView.frame = CGRect(x: (self.bounds.width - 32) / 2, y: (self.bounds.height - 32) / 2, width: 32, height: 32)
        self.circleView.addSubview(self.iconView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: MediaVaultItem) {
        // Can render video thumbnail if available
    }
}
