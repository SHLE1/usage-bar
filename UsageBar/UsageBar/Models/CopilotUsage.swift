import Foundation

struct GitHubUserProfileResponse: Decodable {
    let login: String?
}

struct CopilotQuotaBucket: Decodable {
    let completions: Int?
    let chat: Int?

    private enum CodingKeys: String, CodingKey {
        case completions
        case chat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completions = FlexibleDecoder.decodeInt(container, forKey: .completions)
        chat = FlexibleDecoder.decodeInt(container, forKey: .chat)
    }
}

struct CopilotQuotaSnapshot: Decodable {
    let entitlement: Int?
    let remaining: Int?
    let unlimited: Bool
    let overageCount: Int?
    let overagePermitted: Bool?

    private enum CodingKeys: String, CodingKey {
        case entitlement
        case remaining
        case unlimited
        case overageCount = "overage_count"
        case overagePermitted = "overage_permitted"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entitlement = FlexibleDecoder.decodeInt(container, forKey: .entitlement)
        remaining = FlexibleDecoder.decodeInt(container, forKey: .remaining)
        unlimited = (try? container.decodeIfPresent(Bool.self, forKey: .unlimited)) ?? false
        overageCount = FlexibleDecoder.decodeInt(container, forKey: .overageCount)
        overagePermitted = try? container.decodeIfPresent(Bool.self, forKey: .overagePermitted)
    }
}

struct CopilotInternalUserResponse: Decodable {
    let copilotPlan: String?
    let plan: String?
    let userIdText: String?
    let userIdNumber: Int?
    let quotaResetDateUTCText: String?
    let quotaResetDateText: String?
    let limitedUserResetDateText: String?
    let limitedUserQuotas: CopilotQuotaBucket?
    let monthlyQuotas: CopilotQuotaBucket?
    let quotaSnapshots: [String: CopilotQuotaSnapshot]?

    private enum CodingKeys: String, CodingKey {
        case copilotPlan = "copilot_plan"
        case plan
        case userId = "user_id"
        case id
        case quotaResetDateUTC = "quota_reset_date_utc"
        case quotaResetDate = "quota_reset_date"
        case limitedUserResetDate = "limited_user_reset_date"
        case limitedUserQuotas = "limited_user_quotas"
        case monthlyQuotas = "monthly_quotas"
        case quotaSnapshots = "quota_snapshots"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        copilotPlan = FlexibleDecoder.decodeString(container, forKey: .copilotPlan)
        plan = FlexibleDecoder.decodeString(container, forKey: .plan)
        userIdText = FlexibleDecoder.decodeString(container, forKey: .userId)
        userIdNumber = FlexibleDecoder.decodeInt(container, forKeys: [.userId, .id])
        quotaResetDateUTCText = FlexibleDecoder.decodeString(container, forKey: .quotaResetDateUTC)
        quotaResetDateText = FlexibleDecoder.decodeString(container, forKey: .quotaResetDate)
        limitedUserResetDateText = FlexibleDecoder.decodeString(container, forKey: .limitedUserResetDate)
        limitedUserQuotas = try? container.decodeIfPresent(CopilotQuotaBucket.self, forKey: .limitedUserQuotas)
        monthlyQuotas = try? container.decodeIfPresent(CopilotQuotaBucket.self, forKey: .monthlyQuotas)
        quotaSnapshots = try? container.decodeIfPresent([String: CopilotQuotaSnapshot].self, forKey: .quotaSnapshots)
    }

    var resolvedPlan: String? {
        copilotPlan ?? plan
    }

    var resolvedUserId: String? {
        userIdText ?? userIdNumber.map(String.init)
    }

    var resolvedResetDate: Date? {
        if let quotaResetDateUTCText {
            return ISO8601DateParsing.parse(quotaResetDateUTCText)
        }
        if let quotaResetDateText {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.date(from: quotaResetDateText)
        }
        if let limitedUserResetDateText {
            return ISO8601DateParsing.parse(limitedUserResetDateText)
        }
        return nil
    }
}

struct CopilotUsage: Codable {
    let netBilledAmount: Double
    let netQuantity: Double
    let discountQuantity: Double
    let userPremiumRequestEntitlement: Int
    let filteredUserPremiumRequestEntitlement: Int

    // Plan and reset date info (from /copilot_internal/user API)
    let copilotPlan: String?
    let quotaResetDateUTC: Date?

    init(
        netBilledAmount: Double,
        netQuantity: Double,
        discountQuantity: Double,
        userPremiumRequestEntitlement: Int,
        filteredUserPremiumRequestEntitlement: Int,
        copilotPlan: String? = nil,
        quotaResetDateUTC: Date? = nil
    ) {
        self.netBilledAmount = netBilledAmount
        self.netQuantity = netQuantity
        self.discountQuantity = discountQuantity
        self.userPremiumRequestEntitlement = userPremiumRequestEntitlement
        self.filteredUserPremiumRequestEntitlement = filteredUserPremiumRequestEntitlement
        self.copilotPlan = copilotPlan
        self.quotaResetDateUTC = quotaResetDateUTC
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        netBilledAmount = FlexibleDecoder.decodeDouble(container, forKeys: [.netBilledAmount, .netBilledAmountSnake]) ?? 0
        netQuantity = FlexibleDecoder.decodeDouble(container, forKeys: [.netQuantity, .netQuantitySnake]) ?? 0
        discountQuantity = FlexibleDecoder.decodeDouble(container, forKeys: [.discountQuantity, .discountQuantitySnake]) ?? 0
        userPremiumRequestEntitlement = FlexibleDecoder.decodeInt(
            container,
            forKeys: [.userPremiumRequestEntitlement, .userPremiumRequestEntitlementSnake, .quantity]
        ) ?? 0
        filteredUserPremiumRequestEntitlement = FlexibleDecoder.decodeInt(
            container,
            forKeys: [.filteredUserPremiumRequestEntitlement, .filteredUserPremiumRequestEntitlementSnake]
        ) ?? 0
        copilotPlan = FlexibleDecoder.decodeString(container, forKey: .copilotPlan)
        quotaResetDateUTC = try? container.decodeIfPresent(Date.self, forKey: .quotaResetDateUTC)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(netBilledAmount, forKey: .netBilledAmount)
        try container.encode(netQuantity, forKey: .netQuantity)
        try container.encode(discountQuantity, forKey: .discountQuantity)
        try container.encode(userPremiumRequestEntitlement, forKey: .userPremiumRequestEntitlement)
        try container.encode(filteredUserPremiumRequestEntitlement, forKey: .filteredUserPremiumRequestEntitlement)
        try container.encodeIfPresent(copilotPlan, forKey: .copilotPlan)
        try container.encodeIfPresent(quotaResetDateUTC, forKey: .quotaResetDateUTC)
    }

    var usedRequests: Int { Int(discountQuantity) }
    var limitRequests: Int { userPremiumRequestEntitlement }

    var usagePercentage: Double {
        guard limitRequests > 0 else { return 0 }
        return (Double(usedRequests) / Double(limitRequests)) * 100
    }

    /// Human-readable plan name from API response (e.g., "individual_pro" -> "Pro")
    var planDisplayName: String? {
        guard let plan = copilotPlan else { return nil }
        switch plan.lowercased() {
        case "individual_pro":
            return "Pro"
        case "individual_free":
            return "Free"
        case "business":
            return "Business"
        case "enterprise":
            return "Enterprise"
        default:
            return plan.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var hasDecodedFields: Bool {
        netBilledAmount != 0
            || netQuantity != 0
            || discountQuantity != 0
            || userPremiumRequestEntitlement != 0
            || filteredUserPremiumRequestEntitlement != 0
            || copilotPlan != nil
            || quotaResetDateUTC != nil
    }

    private enum CodingKeys: String, CodingKey {
        case netBilledAmount
        case netBilledAmountSnake = "net_billed_amount"
        case netQuantity
        case netQuantitySnake = "net_quantity"
        case discountQuantity
        case discountQuantitySnake = "discount_quantity"
        case userPremiumRequestEntitlement
        case userPremiumRequestEntitlementSnake = "user_premium_request_entitlement"
        case filteredUserPremiumRequestEntitlement
        case filteredUserPremiumRequestEntitlementSnake = "filtered_user_premium_request_entitlement"
        case quantity
        case copilotPlan
        case quotaResetDateUTC
    }
}

struct CopilotBillingUsageEnvelope: Decodable {
    let payload: CopilotUsage?
    let data: CopilotUsage?
    let directUsage: CopilotUsage?

    private enum CodingKeys: String, CodingKey {
        case payload
        case data
        case netBilledAmount
        case netBilledAmountSnake = "net_billed_amount"
        case netQuantity
        case netQuantitySnake = "net_quantity"
        case discountQuantity
        case discountQuantitySnake = "discount_quantity"
        case userPremiumRequestEntitlement
        case userPremiumRequestEntitlementSnake = "user_premium_request_entitlement"
        case filteredUserPremiumRequestEntitlement
        case filteredUserPremiumRequestEntitlementSnake = "filtered_user_premium_request_entitlement"
        case quantity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        payload = try? container.decodeIfPresent(CopilotUsage.self, forKey: .payload)
        data = try? container.decodeIfPresent(CopilotUsage.self, forKey: .data)

        let directKeys: [CodingKeys] = [
            .netBilledAmount,
            .netBilledAmountSnake,
            .netQuantity,
            .netQuantitySnake,
            .discountQuantity,
            .discountQuantitySnake,
            .userPremiumRequestEntitlement,
            .userPremiumRequestEntitlementSnake,
            .filteredUserPremiumRequestEntitlement,
            .filteredUserPremiumRequestEntitlementSnake,
            .quantity
        ]

        if directKeys.contains(where: container.contains) {
            let decoded = try CopilotUsage(from: decoder)
            directUsage = decoded.hasDecodedFields ? decoded : nil
        } else {
            directUsage = nil
        }
    }

    var usage: CopilotUsage? {
        payload ?? data ?? directUsage
    }
}

struct CopilotBillingTableResponse: Decodable {
    let table: CopilotBillingTable?
}

struct CopilotBillingTable: Decodable {
    let rows: [CopilotBillingRow]?
}

struct CopilotBillingRow: Decodable {
    let cells: [CopilotBillingCell]
}

struct CopilotBillingCell: Decodable {
    let value: CopilotBillingCellValue
}

enum CopilotBillingCellValue: Decodable {
    case string(String)
    case number(Double)
    case integer(Int)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported Copilot billing cell value")
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return String(value)
        case .number(let value):
            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .integer(let value):
            return Double(value)
        case .number(let value):
            return value
        case .string(let value):
            let cleaned = value
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(cleaned)
        case .bool, .null:
            return nil
        }
    }
}

struct CachedUsage: Codable {
    let usage: CopilotUsage
    let timestamp: Date
}
