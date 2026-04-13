import SwiftUI
import os.log

struct StatusBarSettingsView: View {
    private enum PayAsYouGoSettingsItem: Hashable {
        case provider(ProviderIdentifier)
        case copilotAddOn

        init?(storageKey: String) {
            if storageKey == "copilot_add_on" {
                self = .copilotAddOn
                return
            }

            guard let identifier = ProviderIdentifier(rawValue: storageKey) else {
                return nil
            }

            self = .provider(identifier)
        }

        var storageKey: String {
            switch self {
            case let .provider(identifier):
                return identifier.rawValue
            case .copilotAddOn:
                return "copilot_add_on"
            }
        }
    }

    @ObservedObject private var prefs = AppPreferences.shared
    @State private var payAsYouGoItemsOrder: [PayAsYouGoSettingsItem]
    @State private var subscriptionOrder: [ProviderIdentifier]
    private let logger = Logger(subsystem: "com.opencodeproviders", category: "StatusBarSettingsView")

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

    private var shouldShowCopilotAddOnPreview: Bool {
        prefs.copilotAddOnEnabled && prefs.isProviderEnabled(.copilot)
    }

    private var visiblePreviewItemCount: Int {
        enabledPayAsYouGo.count + enabledSubscription.count + (shouldShowCopilotAddOnPreview ? 1 : 0)
    }

    private var shouldShowPayAsYouGoPreview: Bool {
        !enabledPayAsYouGo.isEmpty || shouldShowCopilotAddOnPreview
    }

    private var shouldShowQuotaPreview: Bool {
        !enabledSubscription.isEmpty
    }

    private var previewAnimationKey: String {
        let payAsYouGo = enabledPayAsYouGo.map(\.rawValue).joined(separator: ",")
        let subscription = enabledSubscription.map(\.rawValue).joined(separator: ",")
        return "\(payAsYouGo)|copilotAddOn:\(shouldShowCopilotAddOnPreview)|\(subscription)"
    }

    init() {
        let prefs = AppPreferences.shared
        _payAsYouGoItemsOrder = State(
            initialValue: prefs.payAsYouGoSettingsItemOrder(providers: Self.payAsYouGoProviders).compactMap {
                PayAsYouGoSettingsItem(storageKey: $0)
            }
        )
        _subscriptionOrder = State(
            initialValue: prefs.statusBarSettingsOrder(
                for: .subscription,
                providers: Self.subscriptionProviders
            )
        )
    }

    var body: some View {
        SettingsPage(
            title: L("Status Bar"),
            subtitle: L("Choose which providers appear in UsageBar.")
        ) {
            // MARK: - Live Preview
            previewSection

            // MARK: - Pay-as-you-go Providers
            SettingsSectionCard(
                title: L("Pay-as-you-go Providers"),
                subtitle: L("These providers appear in the usage-based cost section.")
            ) {
                payAsYouGoGrid
            }

            // MARK: - Subscription Providers
            SettingsSectionCard(
                title: L("Subscription Providers"),
                subtitle: L("Quota-based providers shown in the quota section and the top status bar summary.")
            ) {
                providerGrid(for: subscriptionOrder, section: .subscription)
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

        .onAppear {
            payAsYouGoItemsOrder = prefs.payAsYouGoSettingsItemOrder(providers: Self.payAsYouGoProviders).compactMap {
                PayAsYouGoSettingsItem(storageKey: $0)
            }
            subscriptionOrder = prefs.statusBarSettingsOrder(for: .subscription, providers: Self.subscriptionProviders)
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

                Text(String(format: L("Showing %d item(s)"), visiblePreviewItemCount))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 0) {
                if shouldShowPayAsYouGoPreview {
                    previewHeader(title: L("Pay-as-you-go"))
                        .transition(.opacity)
                    ForEach(enabledPayAsYouGo, id: \.self) { provider in
                        previewRow(
                            provider: provider,
                            text: provider.displayName,
                            trailingText: "$—"
                        )
                        .transition(.opacity)
                    }
                    if shouldShowCopilotAddOnPreview {
                        previewRow(
                            provider: .copilot,
                            text: L("Copilot Add-on"),
                            trailingText: "$—"
                        )
                        .transition(.opacity)
                    }
                }

                if shouldShowPayAsYouGoPreview && shouldShowQuotaPreview {
                    Divider()
                        .padding(.vertical, 4)
                        .transition(.opacity)
                }

                if shouldShowQuotaPreview {
                    previewHeader(title: L("Quota Status"))
                        .transition(.opacity)
                    if enabledSubscription.contains(.copilot) {
                        previewRow(
                            provider: .copilot,
                            text: ProviderIdentifier.copilot.displayName,
                            trailingText: L("—% left")
                        )
                        .transition(.opacity)
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
                        .transition(.opacity)
                    }

                    if enabledSubscription.contains(.geminiCLI) {
                        previewRow(
                            provider: .geminiCLI,
                            text: ProviderIdentifier.geminiCLI.displayName,
                            trailingText: L("—% left")
                        )
                        .transition(.opacity)
                    }
                }
            }
            .padding(12)
            .animation(.easeInOut(duration: 0.18), value: previewAnimationKey)
            .background(
                RoundedRectangle(cornerRadius: SettingsSurfaceMetrics.cardCornerRadius, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SettingsSurfaceMetrics.cardCornerRadius, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SettingsSurfaceMetrics.cardCornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SettingsSurfaceMetrics.cardCornerRadius, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var payAsYouGoGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 180), alignment: .leading),
                GridItem(.flexible(minimum: 180), alignment: .leading)
            ],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(payAsYouGoItemsOrder, id: \.self) { item in
                payAsYouGoToggle(for: item)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: payAsYouGoItemsOrder)
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
    private func payAsYouGoToggle(for item: PayAsYouGoSettingsItem) -> some View {
        switch item {
        case let .provider(identifier):
            Toggle(identifier.displayName, isOn: statusBarBinding(for: identifier, section: .payAsYouGo))
                .toggleStyle(.checkbox)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .copilotAddOn:
            Toggle(L("GitHub Copilot Add-on"), isOn: copilotAddOnBinding)
                .toggleStyle(.checkbox)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func providerGrid(
        for providers: [ProviderIdentifier],
        section: AppPreferences.StatusBarSettingsSection
    ) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 180), alignment: .leading),
                GridItem(.flexible(minimum: 180), alignment: .leading)
            ],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(providers, id: \.self) { identifier in
                Toggle(identifier.displayName, isOn: statusBarBinding(for: identifier, section: section))
                    .toggleStyle(.checkbox)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: providers)
    }

    // MARK: - Unified toggle binding

    /// A single toggle that controls both the enabled state and multi-provider membership.
    private func statusBarBinding(
        for identifier: ProviderIdentifier,
        section: AppPreferences.StatusBarSettingsSection
    ) -> Binding<Bool> {
        Binding(
            get: { prefs.isProviderEnabled(identifier) },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    prefs.setProviderEnabled(identifier, enabled: newValue)
                    if newValue {
                        prefs.multiProviderProviders.insert(identifier)
                    } else {
                        prefs.multiProviderProviders.remove(identifier)
                    }
                }

                updateRememberedOrder(for: identifier, enabled: newValue, section: section)
                logger.debug(
                    "Status bar provider visibility changed: \(identifier.rawValue, privacy: .public)=\(newValue, privacy: .public)"
                )
            }
        )
    }

    private var copilotAddOnBinding: Binding<Bool> {
        Binding(
            get: { prefs.copilotAddOnEnabled },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    prefs.copilotAddOnEnabled = newValue
                }
                payAsYouGoItemsOrder = AppPreferences.rememberedItemOrder(
                    from: payAsYouGoItemsOrder,
                    toggled: .copilotAddOn,
                    enabled: newValue,
                    isEnabled: isEnabled
                )
                prefs.setPayAsYouGoSettingsItemOrder(payAsYouGoItemsOrder.map(\.storageKey))
                logger.debug("Status bar provider visibility changed: copilot_add_on=\(newValue, privacy: .public)")
            }
        )
    }

    private func isEnabled(_ item: PayAsYouGoSettingsItem) -> Bool {
        switch item {
        case let .provider(identifier):
            return prefs.isProviderEnabled(identifier)
        case .copilotAddOn:
            return prefs.copilotAddOnEnabled
        }
    }

    private func updateRememberedOrder(
        for identifier: ProviderIdentifier,
        enabled: Bool,
        section: AppPreferences.StatusBarSettingsSection
    ) {
        switch section {
        case .payAsYouGo:
            payAsYouGoItemsOrder = AppPreferences.rememberedItemOrder(
                from: payAsYouGoItemsOrder,
                toggled: .provider(identifier),
                enabled: enabled,
                isEnabled: isEnabled
            )
            prefs.setPayAsYouGoSettingsItemOrder(payAsYouGoItemsOrder.map(\.storageKey))
        case .subscription:
            subscriptionOrder = updatedRememberedOrder(
                from: subscriptionOrder,
                toggled: identifier,
                enabled: enabled,
                section: section,
                allProviders: Self.subscriptionProviders
            )
        }
    }

    private func updatedRememberedOrder(
        from currentOrder: [ProviderIdentifier],
        toggled identifier: ProviderIdentifier,
        enabled: Bool,
        section: AppPreferences.StatusBarSettingsSection,
        allProviders: [ProviderIdentifier]
    ) -> [ProviderIdentifier] {
        let order = AppPreferences.rememberedStatusBarOrder(
            from: currentOrder,
            toggled: identifier,
            enabled: enabled,
            allProviders: allProviders,
            isEnabled: { prefs.isProviderEnabled($0) }
        )

        prefs.setStatusBarSettingsOrder(order, for: section)
        return order
    }
}
