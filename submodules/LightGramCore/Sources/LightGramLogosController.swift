import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import AppBundle
import PresentationDataUtils
import AlertUI

public func loadAppIcon(_ name: String, bundlePath: String = getAppBundle().bundlePath) -> UIImage? {
    let cleanName = (name as NSString).deletingPathExtension
    let possiblePaths = [
        bundlePath + "/\(name)",
        bundlePath + "/\(cleanName).png",
        bundlePath + "/\(cleanName).alticon/\(cleanName)@3x.png",
        bundlePath + "/\(cleanName).alticon/\(cleanName)@2x.png",
        bundlePath + "/\(cleanName).alticon/\(cleanName).png",
        "/opt/lightgram/submodules/LightGramCore/Resources/Logos/\(name)",
        "/opt/lightgram/submodules/LightGramCore/Resources/Logos/\(cleanName).png",
        "/opt/lightgram/avatars/\(name)",
        "/opt/lightgram/avatars/\(cleanName).png"
    ]
    for p in possiblePaths {
        if let img = UIImage(contentsOfFile: p) {
            return img
        }
    }
    return UIImage(named: cleanName, in: getAppBundle(), compatibleWith: nil)
}

public struct LightGramLogoOption {
    public let id: String
    public let iconName: String
    public let titleKey: String
    public let descKey: String
    public let accentColor: UIColor
    public let imageFileName: String
    
    public init(id: String, iconName: String, titleKey: String, descKey: String, accentColor: UIColor, imageFileName: String) {
        self.id = id
        self.iconName = iconName
        self.titleKey = titleKey
        self.descKey = descKey
        self.accentColor = accentColor
        self.imageFileName = imageFileName
    }
}

public final class LightGramLogosController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var disposable: Disposable?
    
    public static let availableLogos: [LightGramLogoOption] = [
        LightGramLogoOption(
            id: "PinkIcon",
            iconName: "PinkIcon",
            titleKey: "Logos_Pink",
            descKey: "Logos_Pink_Desc",
            accentColor: UIColor(rgb: 0xFF2D55),
            imageFileName: "01-pink.png"
        ),
        LightGramLogoOption(
            id: "RedIcon",
            iconName: "RedIcon",
            titleKey: "Logos_Red",
            descKey: "Logos_Red_Desc",
            accentColor: UIColor(rgb: 0xFF3B30),
            imageFileName: "02-red.png"
        ),
        LightGramLogoOption(
            id: "PurpleIcon",
            iconName: "PurpleIcon",
            titleKey: "Logos_Purple",
            descKey: "Logos_Purple_Desc",
            accentColor: UIColor(rgb: 0xAF52DE),
            imageFileName: "03-purple.png"
        ),
        LightGramLogoOption(
            id: "VioletIcon",
            iconName: "VioletIcon",
            titleKey: "Logos_Violet",
            descKey: "Logos_Violet_Desc",
            accentColor: UIColor(rgb: 0x5856D6),
            imageFileName: "04-violet.png"
        ),
        LightGramLogoOption(
            id: "AmberIcon",
            iconName: "AmberIcon",
            titleKey: "Logos_Amber",
            descKey: "Logos_Amber_Desc",
            accentColor: UIColor(rgb: 0xEDB400),
            imageFileName: "01_LightGram_Amber.png"
        ),
        LightGramLogoOption(
            id: "IceIcon",
            iconName: "IceIcon",
            titleKey: "Logos_Ice",
            descKey: "Logos_Ice_Desc",
            accentColor: UIColor(rgb: 0x00C7BE),
            imageFileName: "02_LightGram_Ice.png"
        ),
        LightGramLogoOption(
            id: "EmeraldIcon",
            iconName: "EmeraldIcon",
            titleKey: "Logos_Emerald",
            descKey: "Logos_Emerald_Desc",
            accentColor: UIColor(rgb: 0x34C759),
            imageFileName: "04_LightGram_Emerald.png"
        )
    ]
    
    private let scrollView = UIScrollView()
    private var cardViews: [LightGramLogoCardView] = []
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.title = LightGramStrings.tr("Logos_Title")
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.disposable?.dispose()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = LightGramDesignSystem.Colors.amoledBlack
        self.scrollView.alwaysBounceVertical = true
        self.view.addSubview(self.scrollView)
        
        self.setupCards()
    }
    
    private func setupCards() {
        for card in self.cardViews {
            card.removeFromSuperview()
        }
        self.cardViews.removeAll()
        
        let activeLogo = LightGramSettings.shared.activeLogoTheme
        
        for option in LightGramLogosController.availableLogos {
            let isSelected = (option.id == activeLogo)
            let card = LightGramLogoCardView(option: option, isSelected: isSelected) { [weak self] selectedOption in
                self?.selectLogo(selectedOption)
            }
            self.scrollView.addSubview(card)
            self.cardViews.append(card)
        }
        
        self.view.setNeedsLayout()
    }
    
    private func selectLogo(_ option: LightGramLogoOption) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        LightGramSettings.shared.activeLogoTheme = option.id
        
        self.context.sharedContext.applicationBindings.requestSetAlternateIconName(option.iconName) { _ in }
        
        for card in self.cardViews {
            card.setSelected(card.option.id == option.id)
        }
        
        let alert = textAlertController(
            context: self.context,
            title: LightGramStrings.tr(option.titleKey),
            text: LightGramStrings.tr("Logos_AppliedNotice"),
            actions: [
                TextAlertAction(type: .defaultAction, title: LightGramStrings.tr("OK"), action: {})
            ]
        )
        self.present(alert, in: .window(.root))
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        let navigationBarHeight = self.navigationLayout(layout: layout).navigationFrame.maxY
        self.scrollView.frame = CGRect(x: 0, y: navigationBarHeight, width: layout.size.width, height: layout.size.height - navigationBarHeight)
        
        let sideInset: CGFloat = 16.0
        let spacing: CGFloat = 14.0
        let cardWidth = layout.size.width - sideInset * 2.0
        let cardHeight: CGFloat = 100.0
        
        var curY: CGFloat = 16.0
        
        for card in self.cardViews {
            card.frame = CGRect(x: sideInset, y: curY, width: cardWidth, height: cardHeight)
            curY += cardHeight + spacing
        }
        
        self.scrollView.contentSize = CGSize(width: layout.size.width, height: curY + 24.0)
    }
}

private final class LightGramLogoCardView: UIControl {
    let option: LightGramLogoOption
    private var isCurrentlySelected: Bool
    private let onSelect: (LightGramLogoOption) -> Void
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let checkIndicator = UIView()
    private let checkmarkLayer = CAShapeLayer()
    
    init(option: LightGramLogoOption, isSelected: Bool, onSelect: @escaping (LightGramLogoOption) -> Void) {
        self.option = option
        self.isCurrentlySelected = isSelected
        self.onSelect = onSelect
        
        super.init(frame: .zero)
        
        self.backgroundColor = LightGramDesignSystem.Colors.deepGraphite
        self.layer.cornerRadius = 16.0
        self.layer.masksToBounds = true
        self.layer.borderWidth = isSelected ? 2.0 : 1.0
        self.layer.borderColor = isSelected ? option.accentColor.cgColor : LightGramDesignSystem.Colors.borderGraphite.cgColor
        
        self.iconImageView.layer.cornerRadius = 14.0
        self.iconImageView.layer.masksToBounds = true
        self.iconImageView.contentMode = .scaleAspectFill
        
        // Load logo master asset
        var loadedImage: UIImage? = loadAppIcon(option.imageFileName)
        if loadedImage == nil {
            loadedImage = loadAppIcon(option.iconName)
        }
        self.iconImageView.image = loadedImage
        self.addSubview(self.iconImageView)
        
        self.titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
        self.titleLabel.textColor = LightGramDesignSystem.Colors.textPrimary
        self.titleLabel.text = LightGramStrings.tr(option.titleKey)
        self.addSubview(self.titleLabel)
        
        self.descLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        self.descLabel.textColor = LightGramDesignSystem.Colors.textSecondary
        self.descLabel.text = LightGramStrings.tr(option.descKey)
        self.addSubview(self.descLabel)
        
        self.checkIndicator.layer.cornerRadius = 13.0
        self.checkIndicator.layer.masksToBounds = true
        self.checkIndicator.backgroundColor = isSelected ? option.accentColor : UIColor.clear
        self.checkIndicator.layer.borderWidth = isSelected ? 0.0 : 2.0
        self.checkIndicator.layer.borderColor = LightGramDesignSystem.Colors.textTertiary.cgColor
        self.addSubview(self.checkIndicator)
        
        self.addTarget(self, action: #selector(self.cardTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func cardTapped() {
        self.onSelect(self.option)
    }
    
    func setSelected(_ selected: Bool) {
        self.isCurrentlySelected = selected
        UIView.animate(withDuration: 0.2) {
            self.layer.borderWidth = selected ? 2.0 : 1.0
            self.layer.borderColor = selected ? self.option.accentColor.cgColor : LightGramDesignSystem.Colors.borderGraphite.cgColor
            self.checkIndicator.backgroundColor = selected ? self.option.accentColor : UIColor.clear
            self.checkIndicator.layer.borderWidth = selected ? 0.0 : 2.0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconSize: CGFloat = 72.0
        self.iconImageView.frame = CGRect(x: 14.0, y: (self.bounds.height - iconSize) * 0.5, width: iconSize, height: iconSize)
        
        let indicatorSize: CGFloat = 26.0
        self.checkIndicator.frame = CGRect(x: self.bounds.width - indicatorSize - 16.0, y: (self.bounds.height - indicatorSize) * 0.5, width: indicatorSize, height: indicatorSize)
        
        let textX = self.iconImageView.frame.maxX + 14.0
        let maxTextW = self.checkIndicator.frame.minX - textX - 10.0
        
        self.titleLabel.frame = CGRect(x: textX, y: 26.0, width: maxTextW, height: 22.0)
        self.descLabel.frame = CGRect(x: textX, y: 50.0, width: maxTextW, height: 18.0)
    }
}
