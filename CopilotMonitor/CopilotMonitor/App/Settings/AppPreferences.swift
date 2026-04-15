import AppKit
import Foundation
import Combine
import ServiceManagement

/// Lightweight ObservableObject bridge over UserDefaults.
/// Both SwiftUI Settings views and StatusBarController read/write through this singleton
/// so that changes propagate immediately.
enum AppAppearanceMode: String, CaseIterable {
    case system
    case dark
    case light

    var title: String {
        switch self {
        case .system:
            return L("Follow System")
        case .dark:
            return L("Dark")
        case .light:
            return L("Light")
        }
    }

    var applicationAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .dark:
            return NSAppearance(named: .darkAqua)
        case .light:
            return NSAppearance(named: .aqua)
        }
    }
}

final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    enum StatusBarSettingsSection {
        case payAsYouGo
        case subscription

        fileprivate var orderStorageKey: String {
            switch self {
            case .payAsYouGo:
                return "statusBarSettings.payAsYouGo.order"
            case .subscription:
                return "statusBarSettings.subscription.order"
            }
        }
    }

    static let statusBarPayAsYouGoProviders: [ProviderIdentifier] = [
        .openRouter, .openCode
    ]

    static let statusBarSubscriptionProviders: [ProviderIdentifier] = [
        .copilot, .claude, .kimi, .minimaxCodingPlan, .codex,
        .zaiCodingPlan, .nanoGpt, .antigravity, .chutes, .synthetic, .geminiCLI
    ]

    private static let payAsYouGoItemsOrderStorageKey = "statusBarSettings.payAsYouGo.itemsOrder"
    static let copilotAddOnStorageKey = "copilot_add_on"

    // MARK: - Notification names (StatusBarController listens for these)

    static let refreshIntervalDidChange = Notification.Name("AppPreferences.refreshIntervalDidChange")
    static let predictionPeriodDidChange = Notification.Name("AppPreferences.predictionPeriodDidChange")
    static let enabledProvidersDidChange = Notification.Name("AppPreferences.enabledProvidersDidChange")
    static let criticalBadgeDidChange = Notification.Name("AppPreferences.criticalBadgeDidChange")
    static let showProviderIconDidChange = Notification.Name("AppPreferences.showProviderIconDidChange")
    static let multiProviderProvidersDidChange = Notification.Name("AppPreferences.multiProviderProvidersDidChange")
    static let codexStatusBarAccountDidChange = Notification.Name("AppPreferences.codexStatusBarAccountDidChange")
    static let codexStatusBarWindowDidChange = Notification.Name("AppPreferences.codexStatusBarWindowDidChange")
    static let appLanguageDidChange = Notification.Name("AppPreferences.appLanguageDidChange")
    static let appAppearanceDidChange = Notification.Name("AppPreferences.appAppearanceDidChange")
    static let subscriptionDidChange = Notification.Name("AppPreferences.subscriptionDidChange")
    static let copilotAddOnDidChange = Notification.Name("AppPreferences.copilotAddOnDidChange")
    static let statusBarOrderDidChange = Notification.Name("AppPreferences.statusBarOrderDidChange")
    static let payAsYouGoOrderDidChange = Notification.Name("AppPreferences.payAsYouGoOrderDidChange")

    private let defaults = UserDefaults.standard

    // MARK: - General

    @Published var refreshInterval: RefreshInterval {
        didSet {
            defaults.set(refreshInterval.rawValue, forKey: "refreshInterval")
            NotificationCenter.default.post(name: Self.refreshIntervalDidChange, object: nil)
        }
    }

    @Published var predictionPeriod: PredictionPeriod {
        didSet {
            defaults.set(predictionPeriod.rawValue, forKey: "predictionPeriod")
            NotificationCenter.default.post(name: Self.predictionPeriodDidChange, object: nil)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            let service = SMAppService.mainApp
            do {
                if launchAtLogin {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                // Revert on failure
                _launchAtLogin = Published(wrappedValue: service.status == .enabled)
            }
        }
    }

    @Published var appLanguageMode: AppLanguageMode {
        didSet {
            defaults.set(appLanguageMode.rawValue, forKey: "app.languageMode")
            NotificationCenter.default.post(name: Self.appLanguageDidChange, object: nil)
        }
    }

    @Published var appAppearanceMode: AppAppearanceMode {
        didSet {
            defaults.set(appAppearanceMode.rawValue, forKey: "app.appearanceMode")
            NotificationCenter.default.post(name: Self.appAppearanceDidChange, object: nil)
        }
    }

    // MARK: - Status Bar

    @Published var criticalBadge: Bool {
        didSet {
            defaults.set(criticalBadge, forKey: StatusBarDisplayPreferences.criticalBadgeKey)
            NotificationCenter.default.post(name: Self.criticalBadgeDidChange, object: nil)
        }
    }

    @Published var showProviderIcon: Bool {
        didSet {
            defaults.set(showProviderIcon, forKey: StatusBarDisplayPreferences.showProviderNameKey)
            NotificationCenter.default.post(name: Self.showProviderIconDidChange, object: nil)
        }
    }

    @Published var multiProviderProviders: Set<ProviderIdentifier> {
        didSet {
            let rawValues = multiProviderProviders.map { $0.rawValue }
            defaults.set(rawValues, forKey: StatusBarDisplayPreferences.multiProviderProvidersKey)
            NotificationCenter.default.post(name: Self.multiProviderProvidersDidChange, object: nil)
        }
    }

    @Published var codexStatusBarAccountSelectionKey: String? {
        didSet {
            defaults.set(codexStatusBarAccountSelectionKey, forKey: "provider.codex.statusBarAccountSelectionKey")
            NotificationCenter.default.post(name: Self.codexStatusBarAccountDidChange, object: nil)
        }
    }

    @Published var codexStatusBarWindowMode: CodexStatusBarWindowMode {
        didSet {
            defaults.set(codexStatusBarWindowMode.rawValue, forKey: "provider.codex.statusBarWindowMode")
            NotificationCenter.default.post(name: Self.codexStatusBarWindowDidChange, object: nil)
        }
    }

    // MARK: - Copilot Add-on

    @Published var copilotAddOnEnabled: Bool {
        didSet {
            defaults.set(copilotAddOnEnabled, forKey: "provider.copilot_add_on.enabled")
            NotificationCenter.default.post(name: Self.copilotAddOnDidChange, object: nil)
        }
    }

    // MARK: - Provider Enabled/Disabled

    func isProviderEnabled(_ identifier: ProviderIdentifier) -> Bool {
        let key = "provider.\(identifier.rawValue).enabled"
        if defaults.object(forKey: key) == nil {
            return true
        }
        return defaults.bool(forKey: key)
    }

    func setProviderEnabled(_ identifier: ProviderIdentifier, enabled: Bool) {
        let key = "provider.\(identifier.rawValue).enabled"
        defaults.set(enabled, forKey: key)
        objectWillChange.send()
        NotificationCenter.default.post(name: Self.enabledProvidersDidChange, object: nil)
    }

    func statusBarSettingsOrder(
        for section: StatusBarSettingsSection,
        providers: [ProviderIdentifier]
    ) -> [ProviderIdentifier] {
        let storedRawValues = defaults.array(forKey: section.orderStorageKey) as? [String] ?? []
        let storedProviders = storedRawValues.compactMap(ProviderIdentifier.init(rawValue:))
        let baseline = storedProviders.isEmpty ? providers : storedProviders
        return normalizedStatusBarOrder(baseline, allProviders: providers)
    }

    func setStatusBarSettingsOrder(
        _ providers: [ProviderIdentifier],
        for section: StatusBarSettingsSection
    ) {
        let normalized = normalizedStatusBarOrder(providers, allProviders: providersForStatusBarSection(section))
        defaults.set(normalized.map(\.rawValue), forKey: section.orderStorageKey)
        NotificationCenter.default.post(name: Self.statusBarOrderDidChange, object: nil)
    }

    func payAsYouGoSettingsItemOrder(providers: [ProviderIdentifier]) -> [String] {
        let storedRawValues = defaults.array(forKey: Self.payAsYouGoItemsOrderStorageKey) as? [String] ?? []

        let baseline: [String]
        if storedRawValues.isEmpty {
            baseline = providers.map(\.rawValue) + [Self.copilotAddOnStorageKey]
        } else {
            baseline = storedRawValues
        }

        return normalizedPayAsYouGoSettingsItemOrder(baseline, providers: providers)
    }

    func setPayAsYouGoSettingsItemOrder(_ items: [String]) {
        let normalized = normalizedPayAsYouGoSettingsItemOrder(items, providers: Self.statusBarPayAsYouGoProviders)
        defaults.set(normalized, forKey: Self.payAsYouGoItemsOrderStorageKey)
        NotificationCenter.default.post(name: Self.payAsYouGoOrderDidChange, object: nil)
    }

    static func rememberedStatusBarOrder(
        from currentOrder: [ProviderIdentifier],
        toggled identifier: ProviderIdentifier,
        enabled: Bool,
        allProviders: [ProviderIdentifier],
        isEnabled: (ProviderIdentifier) -> Bool
    ) -> [ProviderIdentifier] {
        let order = sanitizedStatusBarOrder(currentOrder, allProviders: allProviders)
        let currentEnabled = order.filter { isEnabled($0) && $0 != identifier }
        let currentDisabled = order.filter { !isEnabled($0) && $0 != identifier }

        if enabled {
            return currentEnabled + [identifier] + currentDisabled
        }

        return currentEnabled + [identifier] + currentDisabled
    }

    static func rememberedItemOrder<Item: Hashable>(
        from currentOrder: [Item],
        toggled item: Item,
        enabled: Bool,
        isEnabled: (Item) -> Bool
    ) -> [Item] {
        var uniqueOrder: [Item] = []
        for current in currentOrder where !uniqueOrder.contains(current) {
            uniqueOrder.append(current)
        }

        let withoutItem = uniqueOrder.filter { $0 != item }

        let insertIndex = withoutItem.firstIndex(where: { !isEnabled($0) }) ?? withoutItem.endIndex
        var updated = withoutItem
        updated.insert(item, at: insertIndex)
        return updated
    }

    static func sanitizedStatusBarOrder(
        _ order: [ProviderIdentifier],
        allProviders: [ProviderIdentifier]
    ) -> [ProviderIdentifier] {
        var sanitized: [ProviderIdentifier] = []

        for provider in order where allProviders.contains(provider) && !sanitized.contains(provider) {
            sanitized.append(provider)
        }

        for provider in allProviders where !sanitized.contains(provider) {
            sanitized.append(provider)
        }

        return sanitized
    }

    func normalizedStatusBarOrder(
        _ order: [ProviderIdentifier],
        allProviders: [ProviderIdentifier]
    ) -> [ProviderIdentifier] {
        let sanitized = Self.sanitizedStatusBarOrder(order, allProviders: allProviders)
        let enabled = sanitized.filter { isProviderEnabled($0) }
        let disabled = sanitized.filter { !isProviderEnabled($0) }
        return enabled + disabled
    }

    func normalizedPayAsYouGoSettingsItemOrder(
        _ order: [String],
        providers: [ProviderIdentifier]
    ) -> [String] {
        let allowed = providers.map(\.rawValue) + [Self.copilotAddOnStorageKey]
        let sanitized = Self.sanitizedRawOrder(order, allowed: allowed)
        let enabled = sanitized.filter { isPayAsYouGoSettingsItemEnabled(storageKey: $0) }
        let disabled = sanitized.filter { !isPayAsYouGoSettingsItemEnabled(storageKey: $0) }
        return enabled + disabled
    }

    func isPayAsYouGoSettingsItemEnabled(storageKey: String) -> Bool {
        if storageKey == Self.copilotAddOnStorageKey {
            return copilotAddOnEnabled
        }

        guard let identifier = ProviderIdentifier(rawValue: storageKey) else {
            return false
        }

        return isProviderEnabled(identifier)
    }

    func providersForStatusBarSection(_ section: StatusBarSettingsSection) -> [ProviderIdentifier] {
        switch section {
        case .payAsYouGo:
            return Self.statusBarPayAsYouGoProviders
        case .subscription:
            return Self.statusBarSubscriptionProviders
        }
    }

    private static func sanitizedRawOrder(_ order: [String], allowed: [String]) -> [String] {
        var sanitized: [String] = []

        for item in order where allowed.contains(item) && !sanitized.contains(item) {
            sanitized.append(item)
        }

        for item in allowed where !sanitized.contains(item) {
            sanitized.append(item)
        }

        return sanitized
    }

    // MARK: - Init (read current values from UserDefaults)

    private init() {
        let rawRefresh = UserDefaults.standard.integer(forKey: "refreshInterval")
        self.refreshInterval = RefreshInterval(rawValue: rawRefresh) ?? .defaultInterval

        let rawPrediction = UserDefaults.standard.integer(forKey: "predictionPeriod")
        self.predictionPeriod = PredictionPeriod(rawValue: rawPrediction) ?? .defaultPeriod

        self.launchAtLogin = SMAppService.mainApp.status == .enabled

        if let rawLanguageMode = UserDefaults.standard.string(forKey: "app.languageMode"),
           let appLanguageMode = AppLanguageMode(rawValue: rawLanguageMode) {
            self.appLanguageMode = appLanguageMode
        } else {
            self.appLanguageMode = .system
        }

        if let rawAppearanceMode = UserDefaults.standard.string(forKey: "app.appearanceMode"),
           let appAppearanceMode = AppAppearanceMode(rawValue: rawAppearanceMode) {
            self.appAppearanceMode = appAppearanceMode
        } else {
            self.appAppearanceMode = .system
        }

        if UserDefaults.standard.object(forKey: StatusBarDisplayPreferences.criticalBadgeKey) != nil {
            self.criticalBadge = UserDefaults.standard.bool(forKey: StatusBarDisplayPreferences.criticalBadgeKey)
        } else {
            self.criticalBadge = true // default
        }

        if UserDefaults.standard.object(forKey: StatusBarDisplayPreferences.showProviderNameKey) != nil {
            self.showProviderIcon = UserDefaults.standard.bool(forKey: StatusBarDisplayPreferences.showProviderNameKey)
        } else {
            self.showProviderIcon = false // default
        }

        if let rawProviders = UserDefaults.standard.array(forKey: StatusBarDisplayPreferences.multiProviderProvidersKey) as? [String] {
            self.multiProviderProviders = Set(rawProviders.compactMap { ProviderIdentifier(rawValue: $0) })
        } else {
            self.multiProviderProviders = Set(ProviderIdentifier.allCases)
        }

        self.codexStatusBarAccountSelectionKey = UserDefaults.standard.string(
            forKey: "provider.codex.statusBarAccountSelectionKey"
        )

        if UserDefaults.standard.object(forKey: "provider.codex.statusBarWindowMode") != nil {
            let rawCodexStatusBarWindowMode = UserDefaults.standard.integer(
                forKey: "provider.codex.statusBarWindowMode"
            )
            self.codexStatusBarWindowMode = CodexStatusBarWindowMode(rawValue: rawCodexStatusBarWindowMode)
                ?? .defaultMode
        } else {
            self.codexStatusBarWindowMode = .defaultMode
        }

        if UserDefaults.standard.object(forKey: "provider.copilot_add_on.enabled") != nil {
            self.copilotAddOnEnabled = UserDefaults.standard.bool(forKey: "provider.copilot_add_on.enabled")
        } else {
            self.copilotAddOnEnabled = true // default
        }
    }

    /// Refresh launch-at-login state from the system (call after external changes)
    func refreshLaunchAtLoginState() {
        let current = SMAppService.mainApp.status == .enabled
        if launchAtLogin != current {
            launchAtLogin = current
        }
    }
}
