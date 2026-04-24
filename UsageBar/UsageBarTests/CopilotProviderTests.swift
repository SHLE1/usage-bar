import XCTest
@testable import UsageBar

final class CopilotProviderTests: XCTestCase {
    
    func testCopilotUsageDecoding() throws {
        let fixtureData = loadFixture(named: "copilot_response.json")
        let response = try JSONDecoder().decode(CopilotInternalUserResponse.self, from: fixtureData)

        XCTAssertEqual(response.resolvedPlan, "individual_pro")

        let premiumInteractions = try XCTUnwrap(response.quotaSnapshots?["premium_interactions"])
        XCTAssertEqual(premiumInteractions.entitlement, 1500)
        XCTAssertEqual(premiumInteractions.remaining, -3821)
        XCTAssertEqual(premiumInteractions.overagePermitted, true)
    }
    
    func testCopilotUsageModelDecoding() throws {
        let json = """
        {
            "netBilledAmount": 382.1,
            "netQuantity": 5321.0,
            "discountQuantity": 5321.0,
            "userPremiumRequestEntitlement": 1500,
            "filteredUserPremiumRequestEntitlement": 1500
        }
        """
        
        let decoder = JSONDecoder()
        let usage = try decoder.decode(CopilotUsage.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(usage.netBilledAmount, 382.1)
        XCTAssertEqual(usage.usedRequests, 5321)
        XCTAssertEqual(usage.limitRequests, 1500)
    }
    
    func testCopilotUsageWithinLimit() throws {
        let json = """
        {
            "netBilledAmount": 0.0,
            "netQuantity": 500.0,
            "discountQuantity": 500.0,
            "userPremiumRequestEntitlement": 1500,
            "filteredUserPremiumRequestEntitlement": 1500
        }
        """
        
        let decoder = JSONDecoder()
        let usage = try decoder.decode(CopilotUsage.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(usage.usedRequests, 500)
        XCTAssertEqual(usage.limitRequests, 1500)
        XCTAssertEqual(usage.usagePercentage, 33.333333333333336, accuracy: 0.01)
    }
    
    func testCopilotUsageOverageCalculation() throws {
        let json = """
        {
            "netBilledAmount": 382.1,
            "netQuantity": 5321.0,
            "discountQuantity": 5321.0,
            "userPremiumRequestEntitlement": 1500,
            "filteredUserPremiumRequestEntitlement": 1500
        }
        """
        
        let decoder = JSONDecoder()
        let usage = try decoder.decode(CopilotUsage.self, from: json.data(using: .utf8)!)
        
        let overage = usage.usedRequests - usage.limitRequests
        let expectedCost = Double(overage) * 0.10
        
        XCTAssertEqual(overage, 3821)
        XCTAssertEqual(expectedCost, 382.1, accuracy: 0.01)
        XCTAssertEqual(usage.netBilledAmount, expectedCost, accuracy: 0.01)
    }
    
    func testCopilotUsageMissingFields() throws {
        let json = """
        {
            "netBilledAmount": 0.0
        }
        """
        
        let decoder = JSONDecoder()
        let usage = try decoder.decode(CopilotUsage.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(usage.netBilledAmount, 0.0)
        XCTAssertEqual(usage.usedRequests, 0)
        XCTAssertEqual(usage.limitRequests, 0)
    }
    
    // MARK: - CopilotAuthSource Tests

    func testCopilotAuthSourceAllCasesExist() {
        // Verify all expected auth source cases exist and have distinct descriptions
        let descriptions: Set<String> = [
            CopilotAuthSource.opencodeAuth.description,
            CopilotAuthSource.copilotCliKeychain.description,
            CopilotAuthSource.githubCliKeychain.description,
            CopilotAuthSource.vscodeHosts.description,
            CopilotAuthSource.vscodeApps.description
        ]
        XCTAssertEqual(descriptions.count, 5, "Each CopilotAuthSource case must have a unique description")
    }

    func testCopilotAuthSourceDescriptions() {
        XCTAssertEqual(CopilotAuthSource.opencodeAuth.description, "opencodeAuth")
        XCTAssertEqual(CopilotAuthSource.copilotCliKeychain.description, "copilotCliKeychain")
        XCTAssertEqual(CopilotAuthSource.githubCliKeychain.description, "githubCliKeychain")
        XCTAssertEqual(CopilotAuthSource.vscodeHosts.description, "vscodeHosts")
        XCTAssertEqual(CopilotAuthSource.vscodeApps.description, "vscodeApps")
    }

    // MARK: - CopilotAuthSource.priority

    func testSourcePriorityOrdering() {
        XCTAssertGreaterThan(
            CopilotAuthSource.opencodeAuth.priority,
            CopilotAuthSource.copilotCliKeychain.priority,
            "opencodeAuth must outrank copilotCliKeychain"
        )
        XCTAssertGreaterThan(
            CopilotAuthSource.copilotCliKeychain.priority,
            CopilotAuthSource.githubCliKeychain.priority,
            "copilotCliKeychain must outrank githubCliKeychain"
        )
        XCTAssertGreaterThan(
            CopilotAuthSource.githubCliKeychain.priority,
            CopilotAuthSource.vscodeHosts.priority,
            "githubCliKeychain must outrank vscodeHosts"
        )
        XCTAssertGreaterThan(
            CopilotAuthSource.vscodeHosts.priority,
            CopilotAuthSource.vscodeApps.priority,
            "vscodeHosts must outrank vscodeApps"
        )
    }

    func testSourcePriorityAbsoluteValues() {
        XCTAssertEqual(CopilotAuthSource.opencodeAuth.priority, 4)
        XCTAssertEqual(CopilotAuthSource.copilotCliKeychain.priority, 3)
        XCTAssertEqual(CopilotAuthSource.githubCliKeychain.priority, 2)
        XCTAssertEqual(CopilotAuthSource.vscodeHosts.priority, 1)
        XCTAssertEqual(CopilotAuthSource.vscodeApps.priority, 0)
    }

    // MARK: - CopilotPlanInfo Premium Interactions Tests

    func testCopilotPlanInfoWithPremiumInteractions() {
        let info = CopilotPlanInfo(
            plan: "individual_pro",
            quotaResetDateUTC: Date(),
            quotaLimit: 1500,
            quotaRemaining: 800,
            userId: "12345",
            premiumEntitlement: 1500,
            premiumRemaining: 800,
            premiumUnlimited: false,
            premiumOverageCount: 0,
            premiumOveragePermitted: true
        )

        XCTAssertEqual(info.premiumEntitlement, 1500)
        XCTAssertEqual(info.premiumRemaining, 800)
        XCTAssertFalse(info.premiumUnlimited)
        XCTAssertEqual(info.premiumOverageCount, 0)
        XCTAssertEqual(info.premiumOveragePermitted, true)
    }

    func testCopilotPlanInfoUnlimited() {
        let info = CopilotPlanInfo(
            plan: "enterprise",
            quotaResetDateUTC: nil,
            quotaLimit: nil,
            quotaRemaining: nil,
            userId: "99999",
            premiumEntitlement: nil,
            premiumRemaining: nil,
            premiumUnlimited: true,
            premiumOverageCount: nil,
            premiumOveragePermitted: nil
        )

        XCTAssertTrue(info.premiumUnlimited)
        XCTAssertNil(info.premiumEntitlement)
        XCTAssertNil(info.premiumRemaining)
    }

    func testCopilotPlanInfoNoPremiumInteractions() {
        let info = CopilotPlanInfo(
            plan: "individual_free",
            quotaResetDateUTC: nil,
            quotaLimit: 50,
            quotaRemaining: 30,
            userId: "11111",
            premiumEntitlement: nil,
            premiumRemaining: nil,
            premiumUnlimited: false,
            premiumOverageCount: nil,
            premiumOveragePermitted: nil
        )

        XCTAssertNil(info.premiumEntitlement)
        XCTAssertNil(info.premiumRemaining)
        XCTAssertFalse(info.premiumUnlimited)
        // Legacy fields should still be usable
        XCTAssertEqual(info.quotaLimit, 50)
        XCTAssertEqual(info.quotaRemaining, 30)
    }

    func testCopilotPlanInfoOverageScenario() {
        // User has used more than entitlement (remaining is negative)
        let info = CopilotPlanInfo(
            plan: "individual_pro",
            quotaResetDateUTC: Date(),
            quotaLimit: 1500,
            quotaRemaining: -3821,
            userId: "12345",
            premiumEntitlement: 1500,
            premiumRemaining: -3821,
            premiumUnlimited: false,
            premiumOverageCount: 3821,
            premiumOveragePermitted: true
        )

        XCTAssertEqual(info.premiumEntitlement, 1500)
        XCTAssertEqual(info.premiumRemaining, -3821)
        XCTAssertEqual(info.premiumOverageCount, 3821)
        XCTAssertEqual(info.premiumOveragePermitted, true)
    }

    // MARK: - Internal API Fixture Parsing Tests

    func testFixturePremiumInteractionsExtraction() throws {
        let fixtureData = loadFixture(named: "copilot_response.json")
        let response = try JSONDecoder().decode(CopilotInternalUserResponse.self, from: fixtureData)
        let premium = try XCTUnwrap(response.quotaSnapshots?["premium_interactions"])

        // Verify premium_interactions fields match expected values
        XCTAssertEqual(premium.entitlement, 1500)
        XCTAssertEqual(premium.remaining, -3821)
        XCTAssertEqual(premium.overagePermitted, true)

        // Verify used = entitlement - remaining (clamped to 0)
        let entitlement = premium.entitlement ?? 0
        let remaining = premium.remaining ?? 0
        let used = max(0, entitlement - remaining)
        XCTAssertEqual(used, 5321)
    }

    private func loadFixture(named: String) -> Data {
        do {
            return try TestFixtures.data(named: named)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
