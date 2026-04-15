import AppKit
import SwiftUI
import os.log

private let advancedProviderSettingsLogger = Logger(subsystem: "com.opencodeproviders", category: "AdvancedProviderSettingsView")

struct AdvancedProviderSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared

    @State private var accountOptions: [CodexStatusBarAccountOption] = []

    var body: some View {
        SettingsPage {
            SettingsSectionCard(
                title: L("Codex")
            ) {
                VStack(spacing: 0) {
                    if accountOptions.isEmpty {
                        SettingsRow(
                            title: L("Status Bar Account")
                        ) {
                            Text(L("No Codex accounts detected yet."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if accountOptions.count == 1, let option = accountOptions.first {
                        SettingsRow(
                            title: L("Selected Account")
                        ) {
                            Text(option.displayName)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        SettingsRow(
                            title: L("Selected Account")
                        ) {
                            AdaptiveWidthSettingsPopupPicker(
                                options: accountOptions.map {
                                    AdaptiveWidthSettingsPopupOption(value: $0.selectionKey, title: $0.displayName)
                                },
                                selection: Binding(
                                    get: { prefs.codexStatusBarAccountSelectionKey ?? accountOptions.first?.selectionKey ?? "" },
                                    set: { prefs.codexStatusBarAccountSelectionKey = $0 }
                                ),
                                accessibilityLabel: L("Selected Account"),
                                accessibilityValue: selectedAccountTitle
                            )
                            .fixedSize()
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    SettingsRow(
                        title: L("Status Bar Window")
                    ) {
                        AdaptiveWidthSettingsPopupPicker(
                            options: statusBarWindowModes.map {
                                AdaptiveWidthSettingsPopupOption(value: $0, title: $0.title)
                            },
                            selection: $prefs.codexStatusBarWindowMode,
                            accessibilityLabel: L("Status Bar Window"),
                            accessibilityValue: prefs.codexStatusBarWindowMode.title
                        )
                        .fixedSize()
                    }
                }
            }
        }
        .onAppear {
            reloadAccounts()
            advancedProviderSettingsLogger.debug("Rendering advanced provider settings with \(accountOptions.count) Codex account option(s)")
        }
        .onReceive(NotificationCenter.default.publisher(for: AppPreferences.codexStatusBarAccountDidChange)) { _ in
            reloadAccounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppPreferences.enabledProvidersDidChange)) { _ in
            reloadAccounts()
        }
        .onChange(of: prefs.codexStatusBarAccountSelectionKey) { newValue in
            advancedProviderSettingsLogger.debug(
                "Selected Codex status bar account \(newValue ?? "none", privacy: .public)"
            )
        }
        .onChange(of: prefs.codexStatusBarWindowMode) { newValue in
            advancedProviderSettingsLogger.debug(
                "Refreshing Codex window menu width for current selection \(newValue.title, privacy: .public)"
            )
        }
    }

    private var statusBarWindowModes: [CodexStatusBarWindowMode] {
        [.fiveHourOnly, .weeklyOnly, .fiveHourAndWeekly]
    }

    private var selectedAccountTitle: String {
        resolvedSelectedAccount?.displayName ?? accountOptions.first?.displayName ?? L("No Codex accounts detected")
    }

    private var resolvedSelectedAccount: CodexStatusBarAccountOption? {
        let savedSelectionKey = prefs.codexStatusBarAccountSelectionKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let savedSelectionKey, let selected = accountOptions.first(where: { $0.selectionKey == savedSelectionKey }) {
            return selected
        }
        return accountOptions.first
    }

    private func reloadAccounts() {
        let discoveredAccounts = TokenManager.shared.getOpenAIAccounts()
        accountOptions = Self.makeAccountOptions(from: discoveredAccounts)
        advancedProviderSettingsLogger.debug("Reloaded \(accountOptions.count) Codex account option(s) for advanced settings")
        normalizeSelectedAccountIfNeeded()
    }

    private func normalizeSelectedAccountIfNeeded() {
        guard !accountOptions.isEmpty else {
            if prefs.codexStatusBarAccountSelectionKey != nil {
                prefs.codexStatusBarAccountSelectionKey = nil
            }
            return
        }

        let savedSelectionKey = prefs.codexStatusBarAccountSelectionKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let savedSelectionKey,
           accountOptions.contains(where: { $0.selectionKey == savedSelectionKey }) {
            return
        }

        prefs.codexStatusBarAccountSelectionKey = accountOptions[0].selectionKey
    }

    private static func makeAccountOptions(from accounts: [OpenAIAuthAccount]) -> [CodexStatusBarAccountOption] {
        let emailCounts = accounts.reduce(into: [String: Int]()) { counts, account in
            let normalizedEmail = account.email?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
            guard !normalizedEmail.isEmpty else { return }
            counts[normalizedEmail, default: 0] += 1
        }

        return accounts.enumerated().map { index, account in
            let selectionKey = TokenManager.shared.codexStatusBarSelectionKey(for: account, index: index)
            let displayName = displayName(for: account, emailCounts: emailCounts, fallbackIndex: index)
            return CodexStatusBarAccountOption(
                selectionKey: selectionKey,
                displayName: displayName
            )
        }
    }

    private static func displayName(
        for account: OpenAIAuthAccount,
        emailCounts: [String: Int],
        fallbackIndex: Int
    ) -> String {
        let trimmedEmail = account.email?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = trimmedEmail?.lowercased() ?? ""

        if let trimmedEmail, !trimmedEmail.isEmpty {
            if emailCounts[normalizedEmail, default: 0] > 1 {
                if let accountId = account.accountId?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !accountId.isEmpty {
                    return "\(trimmedEmail) (\(accountId))"
                }

                if let sourceLabel = account.sourceLabels.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !sourceLabel.isEmpty {
                    return "\(trimmedEmail) (\(sourceLabel))"
                }
            }

            return trimmedEmail
        }

        if let accountId = account.accountId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !accountId.isEmpty {
            return String(format: L("Account %@"), accountId)
        }

        if let sourceLabel = account.sourceLabels.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           !sourceLabel.isEmpty {
            return sourceLabel
        }

        return String(format: L("Account #%d"), fallbackIndex + 1)
    }
}

private struct CodexStatusBarAccountOption: Identifiable, Equatable {
    let selectionKey: String
    let displayName: String

    var id: String { selectionKey }
}

private struct AdaptiveWidthSettingsPopupOption<Value: Hashable>: Hashable {
    let value: Value
    let title: String
}

private struct AdaptiveWidthSettingsPopupPicker<Value: Hashable>: NSViewRepresentable {
    let options: [AdaptiveWidthSettingsPopupOption<Value>]
    let selection: Binding<Value>
    let accessibilityLabel: String
    let accessibilityValue: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> AdaptiveWidthSettingsPopUpButton {
        let button = AdaptiveWidthSettingsPopUpButton(frame: .zero, pullsDown: false)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        updateButton(button, coordinator: context.coordinator)
        return button
    }

    func updateNSView(_ nsView: AdaptiveWidthSettingsPopUpButton, context: Context) {
        context.coordinator.parent = self
        updateButton(nsView, coordinator: context.coordinator)
    }

    private func updateButton(_ button: AdaptiveWidthSettingsPopUpButton, coordinator: Coordinator) {
        coordinator.options = options

        let selectedIndex = options.firstIndex(where: { $0.value == selection.wrappedValue }) ?? 0
        let newTitles = options.map(\.title)

        if button.itemTitles != newTitles {
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
        var parent: AdaptiveWidthSettingsPopupPicker
        var options: [AdaptiveWidthSettingsPopupOption<Value>] = []

        init(parent: AdaptiveWidthSettingsPopupPicker) {
            self.parent = parent
        }

        @objc func selectionChanged(_ sender: NSPopUpButton) {
            let selectedIndex = sender.indexOfSelectedItem
            guard options.indices.contains(selectedIndex) else { return }
            parent.selection.wrappedValue = options[selectedIndex].value
        }
    }
}

private final class AdaptiveWidthSettingsPopUpButton: NSPopUpButton {
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
