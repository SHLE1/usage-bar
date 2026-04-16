import Foundation

enum ProviderDisplayPolicy {
    static func shouldShowRateLimitedErrorRow(
        identifier: ProviderIdentifier,
        errorMessage: String,
        result: ProviderResult?
    ) -> Bool {
        guard isRateLimitError(errorMessage) else { return false }
        return !hasDisplayableAccountRows(identifier: identifier, result: result)
    }

    static func hasDisplayableAccountRows(
        identifier: ProviderIdentifier,
        result: ProviderResult?
    ) -> Bool {
        guard let result else { return false }

        switch identifier {
        case .claude, .codex, .copilot:
            guard let accounts = result.accounts else { return false }
            return !accounts.isEmpty
        case .geminiCLI:
            guard let accounts = result.details?.geminiAccounts else { return false }
            return !accounts.isEmpty
        default:
            return false
        }
    }

    private static func isRateLimitError(_ errorMessage: String) -> Bool {
        let lowercased = errorMessage.lowercased()
        return lowercased.contains("rate limited")
            || lowercased.contains("rate_limit_error")
            || lowercased.contains("http 429")
            || lowercased.contains("too many requests")
    }
}
