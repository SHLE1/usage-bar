import Foundation

// MARK: - Refresh Interval
enum RefreshInterval: Int, CaseIterable {
    case oneMinute = 60
    case threeMinutes = 180
    case fiveMinutes = 300
    case tenMinutes = 600
    case thirtyMinutes = 1800
    case oneHour = 3600

    var title: String {
        switch self {
        case .oneMinute: return L("1m")
        case .threeMinutes: return L("3m")
        case .fiveMinutes: return L("5m")
        case .tenMinutes: return L("10m")
        case .thirtyMinutes: return L("30m")
        case .oneHour: return L("1h")
        }
    }

    static var defaultInterval: RefreshInterval { .fiveMinutes }
}

// MARK: - Prediction Period
enum PredictionPeriod: Int, CaseIterable {
    case oneWeek = 7
    case twoWeeks = 14
    case threeWeeks = 21

    var title: String {
        switch self {
        case .oneWeek: return L("7 days")
        case .twoWeeks: return L("14 days")
        case .threeWeeks: return L("21 days")
        }
    }

    var weights: [Double] {
        switch self {
        case .oneWeek:
            return [1.5, 1.5, 1.2, 1.2, 1.2, 1.0, 1.0]
        case .twoWeeks:
            return [1.5, 1.5, 1.4, 1.4, 1.3, 1.3, 1.2, 1.2, 1.1, 1.1, 1.0, 1.0, 1.0, 1.0]
        case .threeWeeks:
            return [1.5, 1.5, 1.4, 1.4, 1.3, 1.3, 1.2, 1.2, 1.2, 1.1, 1.1, 1.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        }
    }

    static var defaultPeriod: PredictionPeriod { .oneWeek }
}

// MARK: - Menu Bar Display
enum MenuBarDisplayMode: Int, CaseIterable {
    case totalCost = 0
    case iconOnly = 1
    case onlyShow = 2
    case multiProvider = 3

    var title: String {
        switch self {
        case .totalCost: return L("Total Cost")
        case .iconOnly: return L("Icon Only")
        case .onlyShow: return L("Only Show")
        case .multiProvider: return L("Multi-Provider Bar")
        }
    }

    static var defaultMode: MenuBarDisplayMode { .totalCost }
}

enum OnlyShowMode: Int, CaseIterable {
    case pinnedProvider = 0
    case alertFirst = 1
    case recentChange = 2

    var title: String {
        switch self {
        case .pinnedProvider: return L("Pinned Provider")
        case .alertFirst: return L("Alert First")
        case .recentChange: return L("Recent Quota Change Only")
        }
    }

    static var defaultMode: OnlyShowMode { .pinnedProvider }
}

enum StatusBarDisplayPreferences {
    static let modeKey = "statusBarDisplay.mode"
    static let onlyShowModeKey = "statusBarDisplay.onlyShowMode"
    static let providerKey = "statusBarDisplay.provider"
    // Legacy key kept for migration from old toggle-based UI.
    static let showAlertFirstKey = "statusBarDisplay.showAlertFirst"
    static let criticalBadgeKey = "statusBarDisplay.criticalBadge"
    static let showProviderNameKey = "statusBarDisplay.showProviderName"
    static let multiProviderProvidersKey = "statusBarDisplay.multiProviderProviders"
}

enum CodexStatusBarWindowMode: Int, CaseIterable {
    case fiveHourOnly = 0
    case fiveHourAndWeekly = 1
    case weeklyOnly = 2

    var title: String {
        switch self {
        case .fiveHourOnly:
            return L("5h Only")
        case .fiveHourAndWeekly:
            return L("5h + Weekly")
        case .weeklyOnly:
            return L("Weekly Only")
        }
    }

    static var defaultMode: CodexStatusBarWindowMode { .fiveHourAndWeekly }
}
