import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var isDarkMode: Bool = {
        if UserDefaults.standard.object(forKey: "spendly_darkmode") != nil {
            return UserDefaults.standard.bool(forKey: "spendly_darkmode")
        }
        return UITraitCollection.current.userInterfaceStyle == .dark
    }() {
        didSet { UserDefaults.standard.set(isDarkMode, forKey: "spendly_darkmode") }
    }

    @Published var language: AppLanguage = AppLanguage(rawValue: UserDefaults.standard.integer(forKey: "spendly_language")) ?? .english {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "spendly_language")
            LocalizationManager.shared.language = language
        }
    }
}
