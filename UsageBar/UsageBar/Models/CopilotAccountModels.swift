import Foundation

/// Shared Copilot account snapshot used by both app and CLI providers.
struct CopilotTokenInfo {
    let accountId: String?
    let login: String?
    let planInfo: CopilotPlanInfo?
    let authSource: String
    let source: CopilotAuthSource

    var quotaLimit: Int? { planInfo?.quotaLimit }
    var quotaRemaining: Int? { planInfo?.quotaRemaining }
    var plan: String? { planInfo?.plan }
    var resetDate: Date? { planInfo?.quotaResetDateUTC }
}

/// Shared Copilot account candidate used by both app and CLI providers.
struct CopilotAccountCandidate {
    let accountId: String?
    let usage: ProviderUsage
    let details: DetailedUsage
    let sourcePriority: Int
}
