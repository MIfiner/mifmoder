import Foundation
import UIKit
import Display
import TelegramPresentationData
import AccountContext
import SwiftSignalKit
import LocalAuthentication
import AVFoundation
import AVKit

public final class LightGramMediaVaultController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private var items: [MediaVaultItem] = []
    private var selectedFilter: String = "all"
    private var searchQuery: String = ""
    private var isUnlocked: Bool = false
    
    private var searchBar: UISearchBar!
    private var filterScrollView: UIScrollView!
    private var filterButtons: [UIButton] = []
    private var collectionView: UICollectionView!
    private var emptyLabel: UILabel!
    private var storageHeaderView: UIView!
    private var storageSizeLabel: UILabel!
    
    private var lockOverlayView: UIView?
    
    private let filterOptions: [(key: String, titleKey: String)] = [
        ("all", "MediaVault_All"),
        ("photo", "MediaVault_Photos"),
        ("video", "MediaVault_Videos"),
        ("circle", "MediaVault_Circles"),
        ("voice", "MediaVault_Voice"),
        ("file", "MediaVault_Files"),
        ("favorites", "MediaVault_Favorites")
    ]
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.title = LightGramStrings.tr("MediaVault_Title")
        self.navigationItem.title = LightGramStrings.tr("MediaVault_Title")
        
        self.isUnlocked = !LightGramSettings.shared.biometricLockMediaVault
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = LightGramSettings.oledBlackBackground
        
        let trashItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(self.clearVaultTapped))
        trashItem.tintColor = LightGramSettings.signatureYellowAccent
        self.navigationItem.rightBarButtonItem = trashItem
        
        self.setupViews()
        
        if !self.isUnlocked {
            self.showLockOverlay()
            self.authenticateBiometrics()
        } else {
            self.loadItems()
        }
    }
    
    private func setupViews() {
        let topBar = UIView()
        topBar.backgroundColor = LightGramSettings.oledBlackBackground
        self.view.addSubview(topBar)
        
        // Storage Header
        self.storageHeaderView = UIView()
        self.storageHeaderView.backgroundColor = LightGramSettings.deepGraphiteBackground
        self.storageHeaderView.layer.cornerRadius = 12
        self.storageHeaderView.layer.borderWidth = 1.0
        self.storageHeaderView.layer.borderColor = LightGramSettings.borderGraphiteColor.cgColor
        self.view.addSubview(self.storageHeaderView)
        
        let vaultIcon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        vaultIcon.tintColor = LightGramSettings.signatureYellowAccent
        vaultIcon.frame = CGRect(x: 12, y: 10, width: 20, height: 20)
        self.storageHeaderView.addSubview(vaultIcon)
        
        self.storageSizeLabel = UILabel(frame: CGRect(x: 40, y: 8, width: 220, height: 24))
        self.storageSizeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        self.storageSizeLabel.textColor = .white
        self.storageHeaderView.addSubview(self.storageSizeLabel)
        
        // Search Bar
        self.searchBar = UISearchBar()
        self.searchBar.searchBarStyle = .minimal
        self.searchBar.placeholder = LightGramStrings.tr("Search")
        self.searchBar.delegate = self
        self.searchBar.barStyle = .black
        self.searchBar.tintColor = LightGramSettings.signatureYellowAccent
        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white
            textField.backgroundColor = LightGramSettings.cardSurfaceColor
        }
        self.view.addSubview(self.searchBar)
        
        // Horizontal Filter Tabs
        self.filterScrollView = UIScrollView()
        self.filterScrollView.showsHorizontalScrollIndicator = false
        self.filterScrollView.alwaysBounceHorizontal = true
        self.view.addSubview(self.filterScrollView)
        
        var xOffset: CGFloat = 16.0
        for opt in self.filterOptions {
            let btn = UIButton(type: .system)
            btn.setTitle(LightGramStrings.tr(opt.titleKey), for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            btn.tag = self.filterButtons.count
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            btn.addTarget(self, action: #selector(self.filterTapped(_:)), for: .touchUpInside)
            
            if opt.key == self.selectedFilter {
                btn.backgroundColor = LightGramSettings.signatureYellowAccent
                btn.setTitleColor(.black, for: .normal)
            } else {
                btn.backgroundColor = LightGramSettings.deepGraphiteBackground
                btn.setTitleColor(.white, for: .normal)
            }
            
            btn.sizeToFit()
            btn.frame = CGRect(x: xOffset, y: 0, width: btn.frame.width + 10, height: 32)
            self.filterScrollView.addSubview(btn)
            self.filterButtons.append(btn)
            xOffset += btn.frame.width + 8.0
        }
        self.filterScrollView.contentSize = CGSize(width: xOffset + 16.0, height: 32)
        
        // Collection View Grid
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = LightGramSettings.oledBlackBackground
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.register(MediaVaultCell.self, forCellWithReuseIdentifier: "MediaVaultCell")
        self.view.addSubview(self.collectionView)
        
        // Empty State Label
        self.emptyLabel = UILabel()
        self.emptyLabel.text = LightGramStrings.tr("MediaVault_Empty")
        self.emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.emptyLabel.textColor = UIColor(white: 0.5, alpha: 1.0)
        self.emptyLabel.textAlignment = .center
        self.emptyLabel.numberOfLines = 0
        self.emptyLabel.isHidden = true
        self.view.addSubview(self.emptyLabel)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = self.navigationLayout(layout: layout)
        let topInset = (self.navigationBar != nil ? navLayout.navigationFrame.maxY : (layout.statusBarHeight ?? 0)) + 8.0
        let width = layout.size.width
        let height = layout.size.height
        let padding: CGFloat = 16.0
        
        self.storageHeaderView.frame = CGRect(x: padding, y: topInset, width: width - padding * 2, height: 40)
        self.searchBar.frame = CGRect(x: 8, y: topInset + 44, width: width - 16, height: 44)
        self.filterScrollView.frame = CGRect(x: 0, y: topInset + 92, width: width, height: 36)
        
        let gridY = topInset + 134
        self.collectionView.frame = CGRect(x: padding, y: gridY, width: width - padding * 2, height: max(0, height - gridY))
        self.emptyLabel.frame = CGRect(x: 32, y: gridY + 80, width: width - 64, height: 60)
        
        self.lockOverlayView?.frame = CGRect(origin: .zero, size: layout.size)
    }
    
    @objc private func filterTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < self.filterOptions.count else { return }
        self.selectedFilter = self.filterOptions[index].key
        
        for (i, btn) in self.filterButtons.enumerated() {
            if i == index {
                btn.backgroundColor = LightGramSettings.signatureYellowAccent
                btn.setTitleColor(.black, for: .normal)
            } else {
                btn.backgroundColor = LightGramSettings.deepGraphiteBackground
                btn.setTitleColor(.white, for: .normal)
            }
        }
        self.loadItems()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchQuery = searchText
        self.loadItems()
    }
    
    private func loadItems() {
        let favs = self.selectedFilter == "favorites"
        let type = favs ? nil : (self.selectedFilter == "all" ? nil : self.selectedFilter)
        self.items = LightGramMediaVaultManager.shared.getItems(
            typeFilter: type,
            searchQuery: self.searchQuery,
            favoritesOnly: favs
        )
        self.emptyLabel.isHidden = !self.items.isEmpty
        self.storageSizeLabel.text = "\(LightGramStrings.tr("MediaVault_StorageUsed")): \(LightGramMediaVaultManager.shared.formattedStorageSize()) (\(self.items.count))"
        self.collectionView.reloadData()
    }
    
    // MARK: - Biometric Lock Gate
    private func showLockOverlay() {
        let overlay = UIView(frame: self.view.bounds)
        overlay.backgroundColor = LightGramSettings.oledBlackBackground
        
        let lockIcon = UIImageView(image: UIImage(systemName: "faceid"))
        lockIcon.tintColor = LightGramSettings.signatureYellowAccent
        lockIcon.frame = CGRect(x: (self.view.bounds.width - 64) / 2, y: self.view.bounds.height / 2 - 100, width: 64, height: 64)
        overlay.addSubview(lockIcon)
        
        let titleLabel = UILabel(frame: CGRect(x: 32, y: lockIcon.frame.maxY + 20, width: self.view.bounds.width - 64, height: 26))
        titleLabel.text = LightGramStrings.tr("MediaVault_FaceIDRequired")
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        overlay.addSubview(titleLabel)
        
        let unlockBtn = UIButton(type: .system)
        unlockBtn.frame = CGRect(x: 48, y: titleLabel.frame.maxY + 30, width: self.view.bounds.width - 96, height: 48)
        unlockBtn.backgroundColor = LightGramSettings.signatureYellowAccent
        unlockBtn.setTitle(LightGramStrings.tr("MediaVault_UnlockButton"), for: .normal)
        unlockBtn.setTitleColor(.black, for: .normal)
        unlockBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        unlockBtn.layer.cornerRadius = 24
        unlockBtn.addTarget(self, action: #selector(self.authenticateBiometrics), for: .touchUpInside)
        overlay.addSubview(unlockBtn)
        
        self.view.addSubview(overlay)
        self.lockOverlayView = overlay
    }
    
    @objc private func authenticateBiometrics() {
        let context = LAContext()
        var error: NSError?
        let reason = LightGramStrings.tr("MediaVault_FaceIDPrompt")
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockVault()
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockVault()
                    }
                }
            }
        } else {
            self.unlockVault()
        }
    }
    
    private func unlockVault() {
        self.isUnlocked = true
        UIView.animate(withDuration: 0.25, animations: {
            self.lockOverlayView?.alpha = 0.0
        }) { _ in
            self.lockOverlayView?.removeFromSuperview()
            self.lockOverlayView = nil
            self.loadItems()
        }
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 12) / 2
        return CGSize(width: width, height: width * 1.15)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaVaultCell", for: indexPath) as? MediaVaultCell else {
            return UICollectionViewCell()
        }
        let item = self.items[indexPath.item]
        cell.configure(with: item)
        cell.onFavoriteToggled = { [weak self] in
            let _ = LightGramMediaVaultManager.shared.toggleFavorite(id: item.id)
            self?.loadItems()
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.items[indexPath.item]
        self.presentItemActions(item: item)
    }
    
    private func presentItemActions(item: MediaVaultItem) {
        let sheet = UIAlertController(title: item.fileName, message: "\(item.chatTitle) · \(item.authorName)", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: LightGramStrings.tr("MediaVault_SaveToGallery"), style: .default, handler: { [weak self] _ in
            LightGramMediaVaultManager.shared.exportToCameraRoll(item: item) { success, msg in
                let title = success ? LightGramStrings.tr("MediaVault_GallerySavedNotice") : (msg ?? "Error")
                let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: LightGramStrings.tr("OK"), style: .default))
                self?.present(alert, animated: true)
            }
        }))
        
        sheet.addAction(UIAlertAction(title: item.isFavorite ? "★ Unfavorite" : "★ Favorite", style: .default, handler: { [weak self] _ in
            let _ = LightGramMediaVaultManager.shared.toggleFavorite(id: item.id)
            self?.loadItems()
        }))
        
        sheet.addAction(UIAlertAction(title: "Share", style: .default, handler: { [weak self] _ in
            let url = LightGramMediaVaultManager.shared.resolveItemURL(item: item)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            self?.present(activity, animated: true)
        }))
        
        sheet.addAction(UIAlertAction(title: LightGramStrings.tr("Delete"), style: .destructive, handler: { [weak self] _ in
            LightGramMediaVaultManager.shared.deleteItem(id: item.id) { _ in
                self?.loadItems()
            }
        }))
        
        sheet.addAction(UIAlertAction(title: LightGramStrings.tr("Cancel"), style: .cancel))
        self.present(sheet, animated: true)
    }
    
    @objc private func clearVaultTapped() {
        let alert = UIAlertController(title: LightGramStrings.tr("MediaVault_Title"), message: LightGramStrings.tr("MediaVault_ClearConfirm"), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: LightGramStrings.tr("Clear"), style: .destructive, handler: { [weak self] _ in
            LightGramMediaVaultManager.shared.clearVault(keepFavorites: true) {
                self?.loadItems()
            }
        }))
        alert.addAction(UIAlertAction(title: LightGramStrings.tr("Cancel"), style: .cancel))
        self.present(alert, animated: true)
    }
}

// MARK: - MediaVaultCell
final class MediaVaultCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let chatLabel = UILabel()
    private let sizeBadge = UILabel()
    private let oneTimeBadge = UILabel()
    private let favoriteButton = UIButton(type: .system)
    
    var onFavoriteToggled: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = LightGramSettings.cardSurfaceColor
        self.layer.cornerRadius = 14
        self.layer.borderWidth = 1.0
        self.layer.borderColor = LightGramSettings.borderGraphiteColor.cgColor
        self.clipsToBounds = true
        
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.backgroundColor = LightGramSettings.deepGraphiteBackground
        self.contentView.addSubview(self.imageView)
        
        self.oneTimeBadge.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
        self.oneTimeBadge.textColor = LightGramSettings.signatureYellowAccent
        self.oneTimeBadge.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        self.oneTimeBadge.layer.cornerRadius = 6
        self.oneTimeBadge.clipsToBounds = true
        self.oneTimeBadge.textAlignment = .center
        self.contentView.addSubview(self.oneTimeBadge)
        
        self.sizeBadge.backgroundColor = UIColor(white: 0.0, alpha: 0.65)
        self.sizeBadge.textColor = .white
        self.sizeBadge.font = UIFont.systemFont(ofSize: 9, weight: .medium)
        self.sizeBadge.layer.cornerRadius = 4
        self.sizeBadge.clipsToBounds = true
        self.sizeBadge.textAlignment = .center
        self.contentView.addSubview(self.sizeBadge)
        
        self.favoriteButton.tintColor = LightGramSettings.signatureYellowAccent
        self.favoriteButton.addTarget(self, action: #selector(self.favTapped), for: .touchUpInside)
        self.contentView.addSubview(self.favoriteButton)
        
        self.titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        self.titleLabel.textColor = .white
        self.contentView.addSubview(self.titleLabel)
        
        self.chatLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        self.chatLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        self.contentView.addSubview(self.chatLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = self.bounds.width
        let h = self.bounds.height
        let imgH = h - 46
        
        self.imageView.frame = CGRect(x: 0, y: 0, width: w, height: imgH)
        self.oneTimeBadge.frame = CGRect(x: 8, y: 8, width: 80, height: 18)
        self.sizeBadge.frame = CGRect(x: 8, y: imgH - 22, width: 55, height: 16)
        self.favoriteButton.frame = CGRect(x: w - 32, y: 6, width: 26, height: 26)
        
        self.titleLabel.frame = CGRect(x: 8, y: imgH + 6, width: w - 16, height: 16)
        self.chatLabel.frame = CGRect(x: 8, y: imgH + 24, width: w - 16, height: 14)
    }
    
    @objc private func favTapped() {
        self.onFavoriteToggled?()
    }
    
    func configure(with item: MediaVaultItem) {
        self.titleLabel.text = item.fileName
        self.chatLabel.text = item.chatTitle
        
        let sizeKB = Double(item.fileSize) / 1024.0
        if sizeKB > 1024.0 {
            self.sizeBadge.text = String(format: "%.1f MB", sizeKB / 1024.0)
        } else {
            self.sizeBadge.text = String(format: "%.0f KB", sizeKB)
        }
        
        self.oneTimeBadge.isHidden = !item.isOneTime
        self.oneTimeBadge.text = "👁️ View Once"
        
        let favIcon = item.isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        self.favoriteButton.setImage(favIcon, for: .normal)
        
        let fileURL = LightGramMediaVaultManager.shared.resolveItemURL(item: item)
        if item.mediaType == "photo" {
            self.imageView.image = UIImage(contentsOfFile: fileURL.path)
        } else if item.mediaType == "circle" {
            self.imageView.image = UIImage(systemName: "record.circle.fill")
            self.imageView.tintColor = LightGramSettings.signatureYellowAccent
            self.imageView.contentMode = .center
        } else if item.mediaType == "video" {
            self.imageView.image = UIImage(systemName: "play.rectangle.fill")
            self.imageView.tintColor = UIColor(rgb: 0x0A84FF)
            self.imageView.contentMode = .center
        } else if item.mediaType == "voice" {
            self.imageView.image = UIImage(systemName: "waveform")
            self.imageView.tintColor = UIColor(rgb: 0xBF5AF2)
            self.imageView.contentMode = .center
        } else {
            self.imageView.image = UIImage(systemName: "doc.fill")
            self.imageView.tintColor = UIColor(rgb: 0xFF9F0A)
            self.imageView.contentMode = .center
        }
    }
}
