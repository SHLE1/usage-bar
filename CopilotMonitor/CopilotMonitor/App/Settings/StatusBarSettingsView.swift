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

    private var enabledPayAsYouGo: [ProviderIdentifier] {
        Self.payAsYouGoProviders.filter { prefs.isProviderEnabled($0) }
    }

    private var enabledSubscription: [ProviderIdentifier] {
        Self.subscriptionProviders.filter { prefs.isProviderEnabled($0) }
    }

    private var totalEnabledCount: Int {
        enabledPayAsYouGo.count + enabledSubscription.count
    }

    private var shouldShowPayAsYouGoPreview: Bool {
        !enabledPayAsYouGo.isEmpty || (prefs.copilotAddOnEnabled && prefs.isProviderEnabled(.copilot))
    }

    private var shouldShowQuotaPreview: Bool {
        !enabledSubscription.isEmpty
    }

    var body: some View {
        SettingsPage(
            title: L("Status Bar"),
            subtitle: L("Choose which providers appear in UsageBar and which extra billing items stay visible.")
        ) {
            // MARK: - Live Preview
            previewSection

            // MARK: - Pay-as-you-go Providers
            SettingsSectionCard(
                title: L("Pay-as-you-go Providers"),
                subtitle: L("These providers appear in the usage-based cost section.")
            ) {
                providerGrid(for: sortedProviders(Self.payAsYouGoProviders))
            }

            // MARK: - Subscription Providers
            SettingsSectionCard(
                title: L("Subscription Providers"),
                subtitle: L("Quota-based providers shown in the quota section and the top status bar summary.")
            ) {
                providerGrid(for: sortedProviders(Self.subscriptionProviders))
            }

            // MARK: - Additional Cost Items (de-emphasized)
            SettingsSecondaryCard(
                title: L("Additional Cost Items"),
                subtitle: L("Billing items that can be shown separately from the main provider list.")
            ) {
                Toggle(L("GitHub Copilot Add-on"), isOn: $prefs.copilotAddOnEnabled)
                    .toggleStyle(.checkbox)
            }

            SettingsSecondaryCard(
                title: L("How this appears"),
                subtitle: L("The top status bar only shows quota-based providers. Pay-as-you-go providers still appear in the dropdown cost section.")
            ) {
                Text(L("Use Advanced Providers for provider-specific overrides such as the Codex account and limit window."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Live Preview Section

    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                Text(L("Menu Preview"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(String(format: L("Showing %d provider(s)"), totalEnabledCount))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 0) {
                if shouldShowPayAsYouGoPreview {
                    previewHeader(title: L("Pay-as-you-go"))
                    ForEach(enabledPayAsYouGo, id: \.self) { provider in
                        previewRow(
                            provider: provider,
                            text: provider.displayName,
                            trailingText: "$—"
                        )
                    }
                    if prefs.copilotAddOnEnabled && prefs.isProviderEnabled(.copilot) {
                        previewRow(
                            provider: .copilot,
                            text: L("Copilot Add-on"),
                            trailingText: "$—"
                        )
                    }
                }

                if shouldShowPayAsYouGoPreview && shouldShowQuotaPreview {
                    Divider()
                        .padding(.vertical, 4)
                }

                if shouldShowQuotaPreview {
                    previewHeader(title: L("Quota Status"))
                    if enabledSubscription.contains(.copilot) {
                        previewRow(
                            provider: .copilot,
                            text: ProviderIdentifier.copilot.displayName,
                            trailingText: L("—% left")
                        )
                    }

                    let quotaOrder: [ProviderIdentifier] = [
                        .claude, .kimi, .minimaxCodingPlan, .codex,
                        .zaiCodingPlan, .nanoGpt, .antigravity, .chutes, .synthetic
                    ]
                    ForEach(quotaOrder.filter { enabledSubscription.contains($0) }, id: \.self) { provider in
                        previewRow(
                            provider: provider,
                            text: provider.displayName,
                            trailingText: L("—% left")
                        )
                    }

                    if enabledSubscription.contains(.geminiCLI) {
                        previewRow(
                            provider: .geminiCLI,
                            text: ProviderIdentifier.geminiCLI.displayName,
                            trailingText: L("—% left")
                        )
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func previewHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            .padding(.vertical, 3)
    }

    @ViewBuilder
    private func previewRow(provider: ProviderIdentifier? = nil, text: String, trailingText: String? = nil, dimmed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if let provider {
                previewIcon(for: provider, dimmed: dimmed)
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(dimmed ? .tertiary : .primary)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func previewIcon(for provider: ProviderIdentifier, dimmed: Bool) -> some View {
        Group {
            if let assetName = provider.menuIconAssetName,
               let nsImage = NSImage(named: assetName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: provider.menuIconSymbolName)
            }
        }
        .frame(width: 14, height: 14)
        .foregroundStyle(dimmed ? .quaternary : .secondary)
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
