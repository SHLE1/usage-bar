import XCTest
@testable import UsageBar

final class AppPreferencesTests: XCTestCase {

    func testRememberedStatusBarOrderMovesDisabledProviderToTopOfDisabledGroup() {
        let providers: [ProviderIdentifier] = [.copilot, .claude, .kimi, .codex]
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
}
