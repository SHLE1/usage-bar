import Foundation

enum AppLanguageMode: String, CaseIterable {
    case system
    case english
    case simplifiedChinese

    var title: String {
        switch self {
        case .system:
            return L("Follow System")
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }

    var localizationCode: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        }
    }
}

final class LocalizationManager {
    static let shared = LocalizationManager()

    private init() {}

    func localizedString(for key: String) -> String {
        let bundle = localizedBundle(for: AppPreferences.shared.appLanguageMode)
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    private func localizedBundle(for mode: AppLanguageMode) -> Bundle {
        guard let code = mode.localizationCode,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

func L(_ key: String) -> String {
    LocalizationManager.shared.localizedString(for: key)
}
