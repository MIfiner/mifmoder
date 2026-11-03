import Foundation
import UIKit
import Display

public enum LightGramDesignSystem {
    // MARK: - Premium Color Tokens
    public enum Colors {
        /// Pure AMOLED / OLED deep black
        public static let amoledBlack = UIColor(rgb: 0x000000)
        public static let pureBlack = amoledBlack
        /// Deep charcoal surface background
        public static let deepGraphite = UIColor(rgb: 0x121214)
        /// Primary card surface
        public static let cardSurface = UIColor(rgb: 0x1C1C1E)
        /// Elevated card / modal surface
        public static let cardElevated = UIColor(rgb: 0x252528)
        /// Subtle borders and dividers
        public static let borderGraphite = UIColor(rgb: 0x2C2C2E)
        public static let dividerGraphite = UIColor(rgb: 0x38383A)
        public static let separator = dividerGraphite
        
        /// Signature LightGram Electric Amber / Gold Accent
        public static let signatureYellow = UIColor(rgb: 0xEDB400)
        public static let signatureYellowLight = UIColor(rgb: 0xFFC700)
        public static let signatureYellowDark = UIColor(rgb: 0xC69500)
        
        /// Spy Mode - Deleted Message Alert Red & Surfaces
        public static let deletedRed = UIColor(rgb: 0xFF3B30)
        public static let deletedRedSurface = UIColor(rgb: 0x2C1416)
        public static let deletedRedBorder = UIColor(rgb: 0xE53935)
        
        /// Spy Mode - Edited Message Previous Version Amber & Surfaces
        public static let editedYellow = UIColor(rgb: 0xFFB300)
        public static let editedYellowSurface = UIColor(rgb: 0x2B2310)
        public static let editedYellowBorder = UIColor(rgb: 0xFFC107)
        
        /// Typography & Icons
        public static let textPrimary = UIColor.white
        public static let textSecondary = UIColor(rgb: 0x8E8E93)
        public static let textTertiary = UIColor(rgb: 0x636366)
        public static let textDisabled = UIColor(rgb: 0x48484A)
        
        /// Success / Online Green
        public static let onlineGreen = UIColor(rgb: 0x34C759)
        public static let successGreen = UIColor(rgb: 0x34C759)
    }
    
    // MARK: - Corner Radii
    public enum CornerRadius {
        public static let card: CGFloat = 16.0
        public static let bubble: CGFloat = 18.0
        public static let button: CGFloat = 12.0
        public static let smallButton: CGFloat = 8.0
        public static let pill: CGFloat = 20.0
        public static let modal: CGFloat = 24.0
    }
    
    // MARK: - Typography
    public enum Typography {
        public static let hero = UIFont.systemFont(ofSize: 34, weight: .bold)
        public static let largeTitle = UIFont.systemFont(ofSize: 28, weight: .bold)
        public static let title = UIFont.systemFont(ofSize: 20, weight: .semibold)
        public static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
        public static let body = UIFont.systemFont(ofSize: 15, weight: .regular)
        public static let bodyMedium = UIFont.systemFont(ofSize: 15, weight: .medium)
        public static let subheadline = UIFont.systemFont(ofSize: 13, weight: .regular)
        public static let subheadlineMedium = UIFont.systemFont(ofSize: 13, weight: .medium)
        public static let footnote = UIFont.systemFont(ofSize: 13, weight: .regular)
        public static let caption = UIFont.systemFont(ofSize: 11, weight: .medium)
        public static let badge = UIFont.systemFont(ofSize: 11, weight: .bold)
    }
    
    // MARK: - Haptic Feedback
    public enum Haptics {
        public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
        
        public static func light() {
            impact(.light)
        }
        
        public static func medium() {
            impact(.medium)
        }
        
        public static func heavy() {
            impact(.heavy)
        }
        
        public static func selection() {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
        
        public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        }
    }
    
    // MARK: - Glassmorphism & Surface Helpers
    public static func makeBlurVisualEffectView() -> UIVisualEffectView {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.backgroundColor = UIColor(white: 0.05, alpha: 0.6)
        return view
    }
    
    public static func makeGlassCardView(frame: CGRect = .zero) -> UIView {
        let card = UIView(frame: frame)
        card.backgroundColor = Colors.cardSurface
        card.layer.cornerRadius = CornerRadius.card
        card.layer.borderWidth = 1.0
        card.layer.borderColor = Colors.borderGraphite.cgColor
        card.layer.masksToBounds = true
        return card
    }
}
