import AppKit
import SwiftUI
import os.log

private let subscriptionSettingsLogger = Logger(subsystem: "com.opencodeproviders", category: "SubscriptionSettingsView")

/// Manages subscription cost settings for all quota-based providers.
/// Pay-as-you-go providers (OpenRouter, OpenCode, etc.) are intentionally excluded.
struct SubscriptionSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var rows: [SubscriptionRow] = []
    @State private var totalCost: Double = 0

    private struct DetectedSubscriptionAccount {
        let key: String
        let displayName: String
    }

    /// Providers that support subscription presets (quota-based only).
    private static let subscribableProviders: [ProviderIdentifier] = {
        ProviderIdentifier.allCases.filter { !ProviderSubscriptionPresets.presets(for: $0).isEmpty }
    }()

    var body: some View {
        SettingsPage {
            SettingsSectionCard(
                title: L("Monthly Total")
            ) {
                SettingsSummaryRow(
                    title: L("Configured subscription cost")
                ) {
                    Text(String(format: "$%.2f/m", totalCost))
                        .font(.body.monospaced())
                }
            }

            SettingsSectionCard(
                title: L("Provider Plans")
            ) {
                VStack(spacing: 0) {
                    ForEach(Array($rows.enumerated()), id: \.offset) { index, $row in
                        SubscriptionRowView(row: $row, onChanged: recalculate)

                        if index < rows.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: AppPreferences.enabledProvidersDidChange)) { _ in
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppPreferences.codexStatusBarAccountDidChange)) { _ in
            reload()
        }
    }

    // MARK: - Data Loading

    private func reload() {
        let manager = SubscriptionSettingsManager.shared
        let allSavedKeys = Set(manager.getAllSubscriptionKeys())

        subscriptionSettingsLogger.debug("Reloading subscription settings for \(allSavedKeys.count) saved keys")

        var seen = Set<String>()
        var result: [SubscriptionRow] = []

        // 1) Enumerate subscribable providers — prefer currently detected accounts when available
        for provider in Self.subscribableProviders {
            let baseKey = manager.subscriptionKey(for: provider)

            // Collect all saved keys that belong to this provider
            let providerKeys = allSavedKeys.filter { keyBelongsToProvider($0, provider: provider) }
            let detectedAccounts = detectedSubscriptionAccounts(for: provider)

            if !detectedAccounts.isEmpty {
                subscriptionSettingsLogger.debug(
                    "Detected \(detectedAccounts.count) live subscription account(s) for provider \(provider.rawValue, privacy: .public)"
                )
                for detected in detectedAccounts {
                    let plan = manager.getPlan(forKey: detected.key)
                    result.append(SubscriptionRow(
                        key: detected.key,
                        provider: provider,
                        plan: plan,
                        presets: ProviderSubscriptionPresets.presets(for: provider),
                        displayNameOverride: detected.displayName
                    ))
                    seen.insert(detected.key)
                }
                continue
            }

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

            return a.displayName.localizedStandardCompare(b.displayName) == .orderedAscending
        })

        recalculate()
        subscriptionSettingsLogger.debug("Prepared \(rows.count) subscription rows for settings display")
    }

    private func recalculate() {
        // Persist all current row plans and recompute total
        let manager = SubscriptionSettingsManager.shared
        var sum: Double = 0
        for row in rows {
            if row.plan.isSet {
                manager.setPlan(row.plan, forKey: row.key)
            } else {
                manager.removePlan(forKey: row.key)
            }
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

    private func detectedSubscriptionAccounts(for provider: ProviderIdentifier) -> [DetectedSubscriptionAccount] {
        switch provider {
        case .codex:
            return detectedCodexSubscriptionAccounts()
        case .claude:
            return detectedClaudeSubscriptionAccounts()
        case .copilot:
            return detectedCopilotSubscriptionAccounts()
        case .geminiCLI:
            return detectedGeminiSubscriptionAccounts()
        default:
            return []
        }
    }

    private func detectedCodexSubscriptionAccounts() -> [DetectedSubscriptionAccount] {
        let accounts = TokenManager.shared.getOpenAIAccounts()
        let emailCounts = normalizedEmailCounts(accounts.map { $0.email })
        return deduplicatedDetectedSubscriptionAccounts(
            accounts.enumerated().compactMap { index, account in
                let subscriptionId = normalizedSubscriptionIdentity(email: account.email, fallback: account.accountId)
                guard let subscriptionId else { return nil }
                let label = detectedAccountLabel(
                    preferredEmail: account.email,
                    fallbackId: account.accountId,
                    sourceLabels: account.sourceLabels,
                    fallbackIndex: index,
                    duplicateEmailCounts: emailCounts
                )
                return DetectedSubscriptionAccount(
                    key: SubscriptionSettingsManager.shared.subscriptionKey(for: .codex, accountId: subscriptionId),
                    displayName: "\(ProviderIdentifier.codex.displayName) (\(label))"
                )
            }
        )
    }

    private func detectedClaudeSubscriptionAccounts() -> [DetectedSubscriptionAccount] {
        let accounts = TokenManager.shared.getClaudeAccounts()
        let emailCounts = normalizedEmailCounts(accounts.map { $0.email })
        return deduplicatedDetectedSubscriptionAccounts(
            accounts.enumerated().compactMap { index, account in
                let subscriptionId = normalizedSubscriptionIdentity(email: account.email, fallback: account.accountId)
                guard let subscriptionId else { return nil }
                let label = detectedAccountLabel(
                    preferredEmail: account.email,
                    fallbackId: account.accountId,
                    sourceLabels: account.sourceLabels,
                    fallbackIndex: index,
                    duplicateEmailCounts: emailCounts
                )
                return DetectedSubscriptionAccount(
                    key: SubscriptionSettingsManager.shared.subscriptionKey(for: .claude, accountId: subscriptionId),
                    displayName: "\(ProviderIdentifier.claude.displayName) (\(label))"
                )
            }
        )
    }

    private func detectedCopilotSubscriptionAccounts() -> [DetectedSubscriptionAccount] {
        let accounts = TokenManager.shared.getGitHubCopilotAccounts()
        return deduplicatedDetectedSubscriptionAccounts(
            accounts.enumerated().compactMap { index, account in
                let normalizedLogin = normalizedNonEmpty(account.login)?.lowercased()
                let normalizedAccountId = normalizedNonEmpty(account.accountId)
                let subscriptionId = normalizedLogin ?? normalizedAccountId
                guard let subscriptionId else { return nil }
                let label = normalizedLogin
                    ?? normalizedAccountId
                    ?? "Account #\(index + 1)"
                return DetectedSubscriptionAccount(
                    key: SubscriptionSettingsManager.shared.subscriptionKey(for: .copilot, accountId: subscriptionId),
                    displayName: "\(ProviderIdentifier.copilot.displayName) (\(label))"
                )
            }
        )
    }

    private func detectedGeminiSubscriptionAccounts() -> [DetectedSubscriptionAccount] {
        let accounts = TokenManager.shared.getAllGeminiAccounts()
        let emailCounts = normalizedEmailCounts(accounts.map { $0.email })
        return deduplicatedDetectedSubscriptionAccounts(
            accounts.enumerated().compactMap { index, account in
                let subscriptionId = normalizedSubscriptionIdentity(email: account.email, fallback: account.accountId)
                guard let subscriptionId else { return nil }
                let label = detectedAccountLabel(
                    preferredEmail: account.email,
                    fallbackId: account.accountId,
                    sourceLabels: account.sourceLabels,
                    fallbackIndex: index,
                    duplicateEmailCounts: emailCounts
                )
                return DetectedSubscriptionAccount(
                    key: SubscriptionSettingsManager.shared.subscriptionKey(for: .geminiCLI, accountId: subscriptionId),
                    displayName: "\(ProviderIdentifier.geminiCLI.displayName) (\(label))"
                )
            }
        )
    }

    private func deduplicatedDetectedSubscriptionAccounts(_ accounts: [DetectedSubscriptionAccount]) -> [DetectedSubscriptionAccount] {
        var ordered: [DetectedSubscriptionAccount] = []
        var seen = Set<String>()
        for account in accounts {
            guard seen.insert(account.key).inserted else { continue }
            ordered.append(account)
        }
        return ordered
    }

    private func normalizedSubscriptionIdentity(email: String?, fallback: String?) -> String? {
        if let normalizedEmail = normalizedNonEmpty(email)?.lowercased() {
            return normalizedEmail
        }
        return normalizedNonEmpty(fallback)
    }

    private func normalizedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalizedEmailCounts(_ emails: [String?]) -> [String: Int] {
        emails.reduce(into: [String: Int]()) { counts, email in
            guard let normalizedEmail = normalizedNonEmpty(email)?.lowercased() else { return }
            counts[normalizedEmail, default: 0] += 1
        }
    }

    private func detectedAccountLabel(
        preferredEmail: String?,
        fallbackId: String?,
        sourceLabels: [String],
        fallbackIndex: Int,
        duplicateEmailCounts: [String: Int]
    ) -> String {
        let trimmedEmail = normalizedNonEmpty(preferredEmail)
        let normalizedEmail = trimmedEmail?.lowercased() ?? ""

        if let trimmedEmail {
            if duplicateEmailCounts[normalizedEmail, default: 0] > 1 {
                if let accountId = normalizedNonEmpty(fallbackId) {
                    return "\(trimmedEmail) (\(accountId))"
                }

                if let sourceLabel = sourceLabels
                    .compactMap({ normalizedNonEmpty($0) })
                    .first {
                    return "\(trimmedEmail) (\(sourceLabel))"
                }
            }
            return trimmedEmail
        }

        if let fallbackId = normalizedNonEmpty(fallbackId) {
            return fallbackId
        }

        if let sourceLabel = sourceLabels
            .compactMap({ normalizedNonEmpty($0) })
            .first {
            return sourceLabel
        }

        return "Account #\(fallbackIndex + 1)"
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
    let displayNameOverride: String?

    init(
        key: String,
        provider: ProviderIdentifier?,
        plan: SubscriptionPlan,
        presets: [SubscriptionPreset],
        isOrphaned: Bool = false,
        displayNameOverride: String? = nil
    ) {
        self.id = key
        self.key = key
        self.provider = provider
        self.plan = plan
        self.presets = presets
        self.isOrphaned = isOrphaned
        self.displayNameOverride = displayNameOverride
    }

    var displayName: String {
        if let displayNameOverride, !displayNameOverride.isEmpty {
            return displayNameOverride
        }
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

private enum SubscriptionPlanPickerSelection: Hashable {
    case none
    case preset(Int)
    case custom
}

private struct SubscriptionPlanPickerOption: Hashable {
    let selection: SubscriptionPlanPickerSelection
    let title: String
}

private struct SubscriptionRowView: View {
    @Binding var row: SubscriptionRow
    var onChanged: () -> Void

    @State private var customAmountText: String = ""
    @State private var showCustomField: Bool = false
    @State private var pickerSelection: SubscriptionPlanPickerSelection = .none

    var body: some View {
        VStack(alignment: .leading, spacing: showCustomField ? 6 : 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.displayName)
                        .font(.body)
                        .lineLimit(1)

                    if row.isOrphaned {
                        Text(L("Saved setting without a detected account"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                subscriptionPlanPicker
            }

            if showCustomField {
                HStack(alignment: .center, spacing: 8) {
                    Text(L("Custom monthly cost"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        TextField("0.00", text: $customAmountText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 72)
                            .multilineTextAlignment(.trailing)
                            .controlSize(.small)
                            .onSubmit { applyCustomAmount() }

                        Text(verbatim: "/m")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button(L("Apply")) {
                        applyCustomAmount()
                    }
                    .controlSize(.small)
                }
                .padding(.leading, 2)
            }
        }
        .onAppear {
            syncFromPlan()
            subscriptionSettingsLogger.debug("Using adaptive-width native subscription plan picker for \(row.key, privacy: .public)")
        }
        .onChange(of: row.plan) { _ in
            syncFromPlan()
        }
    }

    private var subscriptionPlanPicker: some View {
        AdaptiveWidthPopupPicker(
            options: pickerOptions,
            selection: pickerSelectionBinding,
            accessibilityLabel: row.displayName,
            accessibilityValue: displaySelectionTitle
        )
        .fixedSize()
    }

    private var pickerOptions: [SubscriptionPlanPickerOption] {
        var options: [SubscriptionPlanPickerOption] = [
            SubscriptionPlanPickerOption(selection: .none, title: L("None"))
        ]

        options.append(contentsOf: row.presets.enumerated().map { index, preset in
            SubscriptionPlanPickerOption(
                selection: .preset(index),
                title: "\(preset.name) \(currencyText(for: preset.cost))"
            )
        })

        options.append(SubscriptionPlanPickerOption(selection: .custom, title: customSelectionTitle))
        return options
    }

    private var pickerSelectionBinding: Binding<SubscriptionPlanPickerSelection> {
        Binding(
            get: { pickerSelection },
            set: { newValue in
                pickerSelection = newValue
                applyPickerSelection(newValue)
            }
        )
    }

    private var customSelectionTitle: String {
        if let amount = currentCustomAmount, amount > 0 {
            return String(format: L("Custom %@"), currencyText(for: amount))
        }
        return L("Custom")
    }

    private var displaySelectionTitle: String {
        switch pickerSelection {
        case .none:
            return L("None")
        case .preset(let index):
            guard row.presets.indices.contains(index) else {
                return L("None")
            }
            let preset = row.presets[index]
            return "\(preset.name) \(currencyText(for: preset.cost))"
        case .custom:
            return customSelectionTitle
        }
    }

    private var currentCustomAmount: Double? {
        if let typedAmount = Double(customAmountText), typedAmount > 0 {
            return typedAmount
        }

        switch row.plan {
        case .custom(let amount):
            return amount
        case .preset(_, let amount) where pickerSelection == .custom:
            return amount
        default:
            return nil
        }
    }

    private func applyPickerSelection(_ selection: SubscriptionPlanPickerSelection) {
        switch selection {
        case .none:
            row.plan = .none
            showCustomField = false
            subscriptionSettingsLogger.debug("Selected no subscription plan for \(row.key, privacy: .public)")
            onChanged()

        case .preset(let index):
            guard row.presets.indices.contains(index) else { return }
            let preset = row.presets[index]
            row.plan = .preset(preset.name, preset.cost)
            showCustomField = false
            subscriptionSettingsLogger.debug(
                "Selected preset subscription plan \(preset.name, privacy: .public) for \(row.key, privacy: .public)"
            )
            onChanged()

        case .custom:
            if case .custom(let amount) = row.plan {
                customAmountText = String(format: "%.2f", amount)
            } else if case .preset(_, let amount) = row.plan {
                customAmountText = String(format: "%.2f", amount)
            }
            showCustomField = true
            subscriptionSettingsLogger.debug("Selected custom subscription plan for \(row.key, privacy: .public)")
        }
    }

    private func matchedPresetIndex(for plan: SubscriptionPlan) -> Int? {
        guard case .preset(let name, let cost) = plan else { return nil }
        return row.presets.firstIndex(where: { preset in
            preset.name == name && abs(preset.cost - cost) < 0.01
        })
    }

    private func syncFromPlan() {
        switch row.plan {
        case .none:
            pickerSelection = .none
            showCustomField = false

        case .custom(let amount):
            pickerSelection = .custom
            showCustomField = true
            customAmountText = String(format: "%.2f", amount)

        case .preset(_, let cost):
            if let index = matchedPresetIndex(for: row.plan) {
                pickerSelection = .preset(index)
                showCustomField = false
            } else {
                pickerSelection = .custom
                showCustomField = true
                customAmountText = String(format: "%.2f", cost)
            }
        }
    }

    private func applyCustomAmount() {
        guard let amount = Double(customAmountText), amount > 0 else {
            row.plan = .none
            pickerSelection = .none
            showCustomField = false
            onChanged()
            return
        }
        row.plan = .custom(amount)
        pickerSelection = .custom
        onChanged()
    }

    private func currencyText(for amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}

private struct AdaptiveWidthPopupPicker: NSViewRepresentable {
    let options: [SubscriptionPlanPickerOption]
    let selection: Binding<SubscriptionPlanPickerSelection>
    let accessibilityLabel: String
    let accessibilityValue: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> AdaptiveWidthPopUpButton {
        let button = AdaptiveWidthPopUpButton(frame: .zero, pullsDown: false)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        updateButton(button, coordinator: context.coordinator)
        return button
    }

    func updateNSView(_ nsView: AdaptiveWidthPopUpButton, context: Context) {
        context.coordinator.parent = self
        updateButton(nsView, coordinator: context.coordinator)
    }

    private func updateButton(_ button: AdaptiveWidthPopUpButton, coordinator: Coordinator) {
        coordinator.options = options

        let selectedIndex = options.firstIndex(where: { $0.selection == selection.wrappedValue }) ?? 0
        let existingTitles = button.itemTitles
        let newTitles = options.map { $0.title }

        if existingTitles != newTitles {
            button.removeAllItems()
            button.addItems(withTitles: newTitles)
        }

        if button.indexOfSelectedItem != selectedIndex {
            button.selectItem(at: selectedIndex)
        }

        button.invalidateIntrinsicContentSize()
        button.setAccessibilityLabel(accessibilityLabel)
        button.setAccessibilityValue(accessibilityValue)
        button.toolTip = accessibilityValue
    }

    final class Coordinator: NSObject {
        var parent: AdaptiveWidthPopupPicker
        var options: [SubscriptionPlanPickerOption] = []

        init(parent: AdaptiveWidthPopupPicker) {
            self.parent = parent
        }

        @objc func selectionChanged(_ sender: NSPopUpButton) {
            let selectedIndex = sender.indexOfSelectedItem
            guard options.indices.contains(selectedIndex) else { return }
            parent.selection.wrappedValue = options[selectedIndex].selection
        }
    }
}

private final class AdaptiveWidthPopUpButton: NSPopUpButton {
    override var intrinsicContentSize: NSSize {
        let fallback = super.intrinsicContentSize
        let selectedTitle = titleOfSelectedItem?.isEmpty == false ? titleOfSelectedItem! : " "

        let probe = NSPopUpButton(frame: .zero, pullsDown: false)
        probe.bezelStyle = bezelStyle
        probe.controlSize = controlSize
        probe.font = font
        probe.addItem(withTitle: selectedTitle)
        probe.sizeToFit()

        let width = ceil(max(probe.frame.width, 72))
        let height = ceil(max(fallback.height, probe.frame.height))
        return NSSize(width: width, height: height)
    }
}
