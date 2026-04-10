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
        Form {
            // MARK: - Pay-as-you-go

            Section("Pay-as-you-go") {
                ForEach(sortedProviders(Self.payAsYouGoProviders), id: \.self) { identifier in
                    Toggle(identifier.displayName, isOn: statusBarBinding(for: identifier))
                }
                Toggle("GitHub Copilot Add-on", isOn: $prefs.copilotAddOnEnabled)
            }

            // MARK: - Subscriptions

            Section("Subscriptions") {
                ForEach(sortedProviders(Self.subscriptionProviders), id: \.self) { identifier in
                    Toggle(identifier.displayName, isOn: statusBarBinding(for: identifier))
                }
            }
        }
        .formStyle(.grouped)
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
