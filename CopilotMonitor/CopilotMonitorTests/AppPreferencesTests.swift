import XCTest
@testable import UsageBar

final class AppPreferencesTests: XCTestCase {
    func testAppAppearanceModeMapsToExpectedAppearanceNames() {
        XCTAssertNil(AppAppearanceMode.system.applicationAppearance)
        XCTAssertEqual(AppAppearanceMode.dark.applicationAppearance?.name, .darkAqua)
        XCTAssertEqual(AppAppearanceMode.light.applicationAppearance?.name, .aqua)
    }

    func testChangingAppAppearancePostsNotificationAndPersistsSelection() {
        let prefs = AppPreferences.shared
        let originalMode = prefs.appAppearanceMode
        let targetMode: AppAppearanceMode = originalMode == .dark ? .light : .dark

        let expectation = expectation(forNotification: AppPreferences.appAppearanceDidChange, object: nil)

        prefs.appAppearanceMode = targetMode

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app.appearanceMode"), targetMode.rawValue)

        prefs.appAppearanceMode = originalMode
    }

    func testRememberedStatusBarOrderMovesDisabledProviderToTopOfDisabledGroup() {
        let providers: [ProviderIdentifier] = [.copilot, .kimi, .codex, .claude]
        let enabledProviders: Set<ProviderIdentifier> = [.copilot, .kimi]

        let order = AppPreferences.rememberedStatusBarOrder(
            from: providers,
            toggled: .claude,
            enabled: false,
            allProviders: providers,
            isEnabled: { enabledProviders.contains($0) }
        )

        XCTAssertEqual(order, [.copilot, .kimi, .claude, .codex])
    }

    func testRememberedStatusBarOrderPlacesNewlyEnabledProviderAtEndOfEnabledGroup() {
        let providers: [ProviderIdentifier] = [.copilot, .kimi, .claude, .codex]
        let enabledProviders: Set<ProviderIdentifier> = [.copilot, .kimi, .codex]

        let order = AppPreferences.rememberedStatusBarOrder(
            from: providers,
            toggled: .codex,
            enabled: true,
            allProviders: providers,
            isEnabled: { enabledProviders.contains($0) }
        )

        XCTAssertEqual(order, [.copilot, .kimi, .codex, .claude])
    }

    func testRememberedItemOrderPlacesNewlyEnabledItemIntoFirstDisabledSlot() {
        let order = AppPreferences.rememberedItemOrder(
            from: ["openrouter", "copilot_add_on", "opencode"],
            toggled: "opencode",
            enabled: true,
            isEnabled: { $0 != "copilot_add_on" }
        )

        XCTAssertEqual(order, ["openrouter", "opencode", "copilot_add_on"])
    }

    func testRememberedItemOrderMovesDisabledItemToTopOfDisabledGroup() {
        let order = AppPreferences.rememberedItemOrder(
            from: ["openrouter", "opencode", "copilot_add_on"],
            toggled: "opencode",
            enabled: false,
            isEnabled: { $0 == "openrouter" }
        )

        XCTAssertEqual(order, ["openrouter", "opencode", "copilot_add_on"])
    }
}
