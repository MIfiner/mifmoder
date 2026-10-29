import Foundation
import UIKit
import Display

func makeLightGramNavBarData() -> NavigationBarPresentationData? {
    if let defaultNavigationBarImpl = defaultNavigationBarImpl {
        let theme = NavigationBarTheme(
            overallDarkAppearance: true,
            buttonColor: LightGramSettings.signatureYellowAccent,
            disabledButtonColor: UIColor(white: 0.4, alpha: 1.0),
            primaryTextColor: .white,
            badgeBackgroundColor: LightGramSettings.signatureYellowAccent,
            badgeTextColor: .black,
            accentButtonColor: LightGramSettings.signatureYellowAccent,
            accentDisabledButtonColor: UIColor(white: 0.4, alpha: 1.0),
            accentForegroundColor: .white
        )
        let strings = NavigationBarStrings(back: "Back", close: "Close", more: "More")
        return NavigationBarPresentationData(theme: theme, strings: strings)
    }
    return nil
}
