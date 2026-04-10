import SwiftUI
import os.log

private let subscriptionSettingsLogger = Logger(subsystem: "com.opencodeproviders", category: "SubscriptionSettingsView")

/// Manages subscription cost settings for all quota-based providers.
/// Pay-as-you-go providers (OpenRouter, OpenCode, etc.) are intentionally excluded.
struct SubscriptionSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var rows: [SubscriptionRow] = []
    @State private var totalCost: Double = 0

    /// Providers that support subscription presets (quota-based only).
    private static let subscribableProviders: [ProviderIdentifier] = {
        ProviderIdentifier.allCases.filter { !ProviderSubscriptionPresets.presets(for: $0).isEmpty }
    }()

    var body: some View {
        SettingsPage(
            title: L("Subscriptions"),
            subtitle: L("Set monthly plan costs for quota-based providers and any detected accounts.")
        ) {
            SettingsSectionCard(
                title: L("Monthly Total"),
                subtitle: L("This total is used for the quota subscription summary.")
            ) {
                HStack {
                    Text(L("Configured subscription cost"))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(String(format: "$%.2f/m", totalCost))
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                }
            }

            SettingsSectionCard(
                title: L("Provider Plans"),
                subtitle: L("Choose a preset or enter a custom monthly amount for each provider.")
            ) {
                LazyVStack(spacing: 0) {
                    ForEach(Array($rows.enumerated()), id: \.offset) { index, $row in
                        SubscriptionRowView(row: $row, onChanged: recalculate)

                        if index < rows.count - 1 {
                            Divider()
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .onAppear { reload() }
    }

    // MARK: - Data Loading

    private func reload() {
        let manager = SubscriptionSettingsManager.shared
        let allSavedKeys = Set(manager.getAllSubscriptionKeys())

        subscriptionSettingsLogger.debug("Reloading subscription settings for \(allSavedKeys.count) saved keys")

        var seen = Set<String>()
        var result: [SubscriptionRow] = []

        // 1) Enumerate subscribable providers — one row per provider (or per account if saved)
        for provider in Self.subscribableProviders {
            let baseKey = manager.subscriptionKey(for: provider)

            // Collect all saved keys that belong to this provider
            let providerKeys = allSavedKeys.filter { keyBelongsToProvider($0, provider: provider) }

            if providerKeys.isEmpty {
                // No saved subscription yet — show a single row for the provider
                let plan = manager.getPlan(forKey: baseKey)
                result.append(SubscriptionRow(
                    key: baseKey,
                    provider: provider,
                    plan: plan,
                    presets: ProviderSubscriptionPresets.presets(for: provider)
                ))
                seen.insert(baseKey)
            } else {
                for key in providerKeys.sorted() {
                    let plan = manager.getPlan(forKey: key)
                    result.append(SubscriptionRow(
                        key: key,
                        provider: provider,
                        plan: plan,
                        presets: ProviderSubscriptionPresets.presets(for: provider)
                    ))
                    seen.insert(key)
                }
            }
        }

        // 2) Orphaned keys (saved but provider not in subscribable list or account changed)
        for key in allSavedKeys.sorted() where !seen.contains(key) {
            let provider = providerFromKey(key)
            let presets = provider.map { ProviderSubscriptionPresets.presets(for: $0) } ?? []
            // Skip orphaned keys for pay-as-you-go providers
            if let prov = provider, ProviderSubscriptionPresets.presets(for: prov).isEmpty {
                continue
            }
            let plan = manager.getPlan(forKey: key)
            result.append(SubscriptionRow(
                key: key,
                provider: provider,
                plan: plan,
                presets: presets,
                isOrphaned: true
            ))
        }

        // 3) Sort: enabled first, disabled second, orphaned last (stable within each group)
        rows = result.sorted(by: { a, b in
            let aOrphaned = a.isOrphaned
            let bOrphaned = b.isOrphaned
            if aOrphaned != bOrphaned { return !aOrphaned }

            let aEnabled = a.provider.map { prefs.isProviderEnabled($0) } ?? false
            let bEnabled = b.provider.map { prefs.isProviderEnabled($0) } ?? false
            if aEnabled != bEnabled { return aEnabled }

            return false // preserve business order within same group
        })

        recalculate()
        subscriptionSettingsLogger.debug("Prepared \(rows.count) subscription rows for settings display")
    }

    private func recalculate() {
        // Persist all current row plans and recompute total
        let manager = SubscriptionSettingsManager.shared
        var sum: Double = 0
        for row in rows {
            manager.setPlan(row.plan, forKey: row.key)
            sum += row.plan.cost
        }
        totalCost = sum
        subscriptionSettingsLogger.debug("Updated monthly subscription total to \(String(format: "$%.2f", sum), privacy: .public)")
        NotificationCenter.default.post(name: AppPreferences.subscriptionDidChange, object: nil)
    }

    // MARK: - Helpers

    private func keyBelongsToProvider(_ key: String, provider: ProviderIdentifier) -> Bool {
        return key == provider.rawValue || key.hasPrefix("\(provider.rawValue).")
    }

    private func providerFromKey(_ key: String) -> ProviderIdentifier? {
        let prefix = key.split(separator: ".", maxSplits: 1).first.map(String.init) ?? key
        return ProviderIdentifier(rawValue: prefix)
    }
}

// MARK: - Row Model

struct SubscriptionRow: Identifiable {
    let id: String // same as key
    let key: String
    let provider: ProviderIdentifier?
    var plan: SubscriptionPlan
    let presets: [SubscriptionPreset]
    let isOrphaned: Bool

    init(key: String, provider: ProviderIdentifier?, plan: SubscriptionPlan, presets: [SubscriptionPreset], isOrphaned: Bool = false) {
        self.id = key
        self.key = key
        self.provider = provider
        self.plan = plan
        self.presets = presets
        self.isOrphaned = isOrphaned
    }

    var displayName: String {
        guard let provider = provider else { return key }
        let base = provider.displayName
        // If key has an account suffix, show it
        let providerRaw = provider.rawValue
        if key.count > providerRaw.count + 1 && key.hasPrefix(providerRaw + ".") {
            let account = String(key.dropFirst(providerRaw.count + 1))
            return "\(base) (\(account))"
        }
        return base
    }
}

// MARK: - Row View

private struct SubscriptionRowView: View {
    @Binding var row: SubscriptionRow
    var onChanged: () -> Void

    @State private var customAmountText: String = ""
    @State private var showCustomField: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: showCustomField ? 10 : 0) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.displayName)
                        .font(.body)
                        .lineLimit(1)

                    if row.isOrphaned {
                        Text(LocalizedStringKey("Saved setting without a detected account"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                subscriptionPlanMenu
            }

            if showCustomField {
                HStack(alignment: .center, spacing: 12) {
                    Text(L("Custom monthly cost"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    TextField("0.00", text: $customAmountText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 96)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { applyCustomAmount() }

                    Text(verbatim: L("/m"))
                        .foregroundStyle(.secondary)

                    Button(L("Apply")) {
                        applyCustomAmount()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 14)
        .onAppear {
            syncFromPlan()
            subscriptionSettingsLogger.debug("Using compact subscription plan control for \(row.key, privacy: .public)")
        }
    }

    private var subscriptionPlanMenu: some View {
        Menu {
            Button(L("None")) {
                row.plan = .none
                showCustomField = false
                subscriptionSettingsLogger.debug("Selected no subscription plan for \(row.key, privacy: .public)")
                onChanged()
            }

            if !row.presets.isEmpty {
                Divider()

                ForEach(Array(row.presets.enumerated()), id: \.offset) { _, preset in
                    Button("\(preset.name) \(currencyText(for: preset.cost))") {
                        row.plan = .preset(preset.name, preset.cost)
                        showCustomField = false
                        subscriptionSettingsLogger.debug("Selected preset subscription plan \(preset.name, privacy: .public) for \(row.key, privacy: .public)")
                        onChanged()
                    }
                }
            }

            Divider()

            Button(selectionTitle(for: .custom(0))) {
                if case .custom(let amount) = row.plan {
                    customAmountText = String(format: "%.2f", amount)
                } else if case .preset(_, let amount) = row.plan {
                    customAmountText = String(format: "%.2f", amount)
                }
                showCustomField = true
                subscriptionSettingsLogger.debug("Selected custom subscription plan for \(row.key, privacy: .public)")
            }
        } label: {
            CompactSettingsMenuLabel(title: selectionTitle(for: row.plan))
        }
        .controlSize(.regular)
        .buttonStyle(.plain)
        .fixedSize()
    }

    private func selectionTitle(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .none:
            return L("None")
        case .preset(let name, let cost):
            return "\(name) \(currencyText(for: cost))"
        case .custom:
            let amount: Double
            switch row.plan {
            case .custom(let currentAmount):
                amount = currentAmount
            case .preset(_, let currentAmount):
                amount = currentAmount
            default:
                amount = Double(customAmountText) ?? 0
            }
            if amount > 0 {
                return String(format: L("Custom %@"), currencyText(for: amount))
            }
            return L("Custom")
        }
    }

    private func syncFromPlan() {
        switch row.plan {
        case .custom(let amount):
            showCustomField = true
            customAmountText = String(format: "%.2f", amount)
        case .preset(_, let cost):
            // If preset cost doesn't match any known option, treat as custom
            if !row.presets.contains(where: { abs($0.cost - cost) < 0.01 }) {
                showCustomField = true
                customAmountText = String(format: "%.2f", cost)
            }
        default:
            break
        }
    }

    private func applyCustomAmount() {
        guard let amount = Double(customAmountText), amount > 0 else {
            row.plan = .none
            showCustomField = false
            onChanged()
            return
        }
        row.plan = .custom(amount)
        onChanged()
    }

    private func currencyText(for amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
