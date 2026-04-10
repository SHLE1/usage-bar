import SwiftUI

struct StatusBarSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared

    /// Pay-as-you-go providers in stable display order.
    private static let payAsYouGoProviders: [ProviderIdentifier] = [
        .openRouter, .openCode
    ]

    /// Subscription (quota-based) providers in stable display order.
    private static let subscriptionProviders: [ProviderIdentifier] = [
        .copilot, .claude, .kimi, .minimaxCodingPlan, .codex,
        .zaiCodingPlan, .nanoGpt, .antigravity, .chutes, .synthetic, .geminiCLI
    ]

    var body: some View {
        SettingsPage(
            title: L("Status Bar"),
            subtitle: L("Choose which providers appear in UsageBar and which extra billing items stay visible.")
        ) {
            SettingsSectionCard(
                title: L("Pay-as-you-go Providers"),
                subtitle: L("These providers appear in the usage-based cost section.")
            ) {
                providerGrid(for: sortedProviders(Self.payAsYouGoProviders))
            }

            SettingsSectionCard(
                title: L("Additional Cost Items"),
                subtitle: L("Billing items that can be shown separately from the main provider list.")
            ) {
                Toggle(L("GitHub Copilot Add-on"), isOn: $prefs.copilotAddOnEnabled)
                    .toggleStyle(.checkbox)
            }

            SettingsSectionCard(
                title: L("Subscription Providers"),
                subtitle: L("Quota-based providers shown in the quota section and the status bar summary.")
            ) {
                providerGrid(for: sortedProviders(Self.subscriptionProviders))
            }
        }
    }

    @ViewBuilder
    private func providerGrid(for providers: [ProviderIdentifier]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 180), alignment: .leading),
                GridItem(.flexible(minimum: 180), alignment: .leading)
            ],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(providers, id: \.self) { identifier in
                Toggle(identifier.displayName, isOn: statusBarBinding(for: identifier))
                    .toggleStyle(.checkbox)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Sorting (enabled first, then disabled; stable order within each group)

    private func sortedProviders(_ providers: [ProviderIdentifier]) -> [ProviderIdentifier] {
        let enabled = providers.filter { prefs.isProviderEnabled($0) }
        let disabled = providers.filter { !prefs.isProviderEnabled($0) }
        return enabled + disabled
    }

    // MARK: - Unified toggle binding

    /// A single toggle that controls both the enabled state and multi-provider membership.
    private func statusBarBinding(for identifier: ProviderIdentifier) -> Binding<Bool> {
        Binding(
            get: { prefs.isProviderEnabled(identifier) },
            set: { newValue in
                prefs.setProviderEnabled(identifier, enabled: newValue)
                if newValue {
                    prefs.multiProviderProviders.insert(identifier)
                } else {
                    prefs.multiProviderProviders.remove(identifier)
                }
            }
        )
    }
}
