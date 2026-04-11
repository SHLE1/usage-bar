import SwiftUI

struct CodexSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared

    @State private var accountOptions: [CodexStatusBarAccountOption] = []

    var body: some View {
        SettingsPage(
            title: L("Codex"),
            subtitle: L("Manage which Codex account and limit window UsageBar shows in the status bar.")
        ) {
            SettingsSectionCard(
                title: L("Status Bar Account"),
                subtitle: L("Choose which detected Codex account the status bar should follow.")
            ) {
                if accountOptions.isEmpty {
                    Text(L("No Codex accounts detected yet."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if accountOptions.count == 1, let option = accountOptions.first {
                    SettingsRow(
                        title: L("Selected Account"),
                        description: L("The only detected Codex account on this Mac.")
                    ) {
                        Text(option.displayName)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    SettingsRow(
                        title: L("Selected Account"),
                        description: L("Switch which Codex account drives the status bar.")
                    ) {
                        Menu {
                            ForEach(accountOptions) { option in
                                Button(option.displayName) {
                                    prefs.codexStatusBarAccountSelectionKey = option.selectionKey
                                }
                            }
                        } label: {
                            CompactSettingsMenuLabel(title: selectedAccountTitle)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }
                }
            }

            SettingsSectionCard(
                title: L("Status Bar Window"),
                subtitle: L("Choose which Codex limit window stays visible in the status bar.")
            ) {
                SettingsRow(
                    title: L("Display Mode"),
                    description: L("Single-provider mode shows percentages. Multi-provider mode uses a compact Codex format.")
                ) {
                    Menu {
                        ForEach(statusBarWindowModes, id: \.self) { mode in
                            Button(mode.title) {
                                prefs.codexStatusBarWindowMode = mode
                            }
                        }
                    } label: {
                        CompactSettingsMenuLabel(title: prefs.codexStatusBarWindowMode.title)
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }
            }
        }
        .onAppear {
            reloadAccounts()
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
