import XCTest
@testable import UsageBar

final class CodexProviderTests: XCTestCase {
    
    var provider: CodexProvider!
    
    override func setUp() {
        super.setUp()
        provider = CodexProvider()
    }
    
    override func tearDown() {
        provider = nil
        super.tearDown()
    }
    
    func testProviderIdentifier() {
        XCTAssertEqual(provider.identifier, .codex)
    }
    
    func testProviderType() {
        XCTAssertEqual(provider.type, .quotaBased)
    }
    
    func testCodexFixtureDecoding() throws {
        let fixture = try loadFixture(named: "codex_response")
        
        guard let dict = fixture as? [String: Any] else {
            XCTFail("Fixture should be a dictionary")
            return
        }
        
        XCTAssertNotNil(dict["plan_type"])
        XCTAssertNotNil(dict["rate_limit"])
        
        guard let rateLimit = dict["rate_limit"] as? [String: Any] else {
            XCTFail("rate_limit should be a dictionary")
            return
        }
        
        guard let primaryWindow = rateLimit["primary_window"] as? [String: Any] else {
            XCTFail("primary_window should be a dictionary")
            return
        }
        
        let usedPercent = primaryWindow["used_percent"] as? Double
        let resetAfterSeconds = primaryWindow["reset_after_seconds"] as? Int

        guard let additionalRateLimits = dict["additional_rate_limits"] as? [[String: Any]],
              let sparkLimit = additionalRateLimits.first,
              let sparkLimitName = sparkLimit["limit_name"] as? String,
              let sparkRateLimit = sparkLimit["rate_limit"] as? [String: Any],
              let sparkPrimary = sparkRateLimit["primary_window"] as? [String: Any],
              let sparkSecondary = sparkRateLimit["secondary_window"] as? [String: Any] else {
            XCTFail("additional_rate_limits[0].rate_limit.{primary_window,secondary_window} should exist")
            return
        }

        let sparkUsedPercent = sparkPrimary["used_percent"] as? Double ?? (sparkPrimary["used_percent"] as? Int).flatMap { Double($0) }
        let sparkResetAfterSeconds = sparkPrimary["reset_after_seconds"] as? Int
        let sparkSecondaryUsedPercent = sparkSecondary["used_percent"] as? Double ?? (sparkSecondary["used_percent"] as? Int).flatMap { Double($0) }
        let sparkSecondaryResetAfterSeconds = sparkSecondary["reset_after_seconds"] as? Int
        
        XCTAssertNotNil(usedPercent)
        XCTAssertNotNil(resetAfterSeconds)
        XCTAssertEqual(usedPercent, 9.0)
        XCTAssertEqual(resetAfterSeconds, 7252)
        XCTAssertEqual(sparkLimitName, "GPT-5.3-Codex-Spark")
        XCTAssertNotNil(sparkUsedPercent)
        XCTAssertNotNil(sparkResetAfterSeconds)
        XCTAssertEqual(sparkUsedPercent, 16.0)
        XCTAssertEqual(sparkResetAfterSeconds, 16711)
        XCTAssertNotNil(sparkSecondaryUsedPercent)
        XCTAssertNotNil(sparkSecondaryResetAfterSeconds)
        XCTAssertEqual(sparkSecondaryUsedPercent, 5.0)
        XCTAssertEqual(sparkSecondaryResetAfterSeconds, 603511)
    }
    
    func testProviderUsageQuotaBasedModel() {
        let usage = ProviderUsage.quotaBased(remaining: 91, entitlement: 100, overagePermitted: false)
        
        XCTAssertEqual(usage.usagePercentage, 9.0)
        XCTAssertTrue(usage.isWithinLimit)
        XCTAssertEqual(usage.remainingQuota, 91)
        XCTAssertEqual(usage.totalEntitlement, 100)
        XCTAssertNil(usage.resetTime)
    }
    
    func testProviderUsageStatusMessage() {
        let usage = ProviderUsage.quotaBased(remaining: 91, entitlement: 100, overagePermitted: false)
        
        let message = usage.statusMessage
        XCTAssertTrue(message.contains("91"))
        XCTAssertTrue(message.contains("remaining"))
    }
    
    // MARK: - CodexAuth Struct Decoding Tests

    /// Verify that ~/.codex/auth.json native format with tokens and null API key can be parsed
    func testCodexNativeAuthDecoding() throws {
        let json = """
        {
            "OPENAI_API_KEY": null,
            "tokens": {
                "access_token": "test-access-token",
                "account_id": "test-account-id",
                "id_token": "test-id-token",
                "refresh_token": "test-refresh-token"
            },
            "last_refresh": "2026-01-28T13:20:36.123Z"
        }
        """
        let data = json.data(using: .utf8)!
        let auth = try JSONDecoder().decode(CodexAuth.self, from: data)
        XCTAssertEqual(auth.tokens?.accessToken, "test-access-token")
        XCTAssertEqual(auth.tokens?.accountId, "test-account-id")
        XCTAssertEqual(auth.tokens?.idToken, "test-id-token")
        XCTAssertEqual(auth.tokens?.refreshToken, "test-refresh-token")
        XCTAssertEqual(auth.lastRefresh, "2026-01-28T13:20:36.123Z")
        XCTAssertNil(auth.openaiAPIKey)
    }

    /// Verify that CodexAuth correctly parses when OPENAI_API_KEY is set (non-null)
    func testCodexNativeAuthWithAPIKey() throws {
        let json = """
        {
            "OPENAI_API_KEY": "sk-test-key",
            "tokens": {
                "access_token": "test-access-token",
                "account_id": "test-account-id",
                "id_token": "test-id-token",
                "refresh_token": "test-refresh-token"
            },
            "last_refresh": "2026-01-28T13:20:36.123Z"
        }
        """
        let data = json.data(using: .utf8)!
        let auth = try JSONDecoder().decode(CodexAuth.self, from: data)
        XCTAssertEqual(auth.openaiAPIKey, "sk-test-key")
        XCTAssertEqual(auth.tokens?.accessToken, "test-access-token")
    }

    /// Verify that CodexAuth can parse with only the minimal required fields (tokens with access_token and account_id)
    func testCodexNativeAuthMinimalFields() throws {
        let json = """
        {
            "tokens": {
                "access_token": "test-token",
                "account_id": "test-id"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let auth = try JSONDecoder().decode(CodexAuth.self, from: data)
        XCTAssertEqual(auth.tokens?.accessToken, "test-token")
        XCTAssertEqual(auth.tokens?.accountId, "test-id")
        XCTAssertNil(auth.tokens?.idToken)
        XCTAssertNil(auth.tokens?.refreshToken)
        XCTAssertNil(auth.openaiAPIKey)
        XCTAssertNil(auth.lastRefresh)
    }

    /// Verify that CodexAuth handles empty tokens object gracefully
    func testCodexNativeAuthEmptyTokens() throws {
        let json = """
        {
            "tokens": {}
        }
        """
        let data = json.data(using: .utf8)!
        let auth = try JSONDecoder().decode(CodexAuth.self, from: data)
        XCTAssertNil(auth.tokens?.accessToken)
        XCTAssertNil(auth.tokens?.accountId)
    }

    /// Verify that CodexAuth handles missing tokens key (no tokens at all)
    func testCodexNativeAuthNoTokens() throws {
        let json = """
        {
            "OPENAI_API_KEY": "sk-only-key"
        }
        """
        let data = json.data(using: .utf8)!
        let auth = try JSONDecoder().decode(CodexAuth.self, from: data)
        XCTAssertNil(auth.tokens)
        XCTAssertEqual(auth.openaiAPIKey, "sk-only-key")
    }

    func testCodexUsageURLUsesSelfServiceEndpointForExternalAPIKey() throws {
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: nil,
            externalUsageAccountId: nil,
            email: nil,
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )
        let configuration = CodexEndpointConfiguration(
            mode: .external(usageURL: URL(string: "https://codex.example.com/api/codex/usage")!),
            source: "test",
            usesOpenAIProviderBaseURL: true
        )

        let url = try provider.codexUsageURL(for: configuration, account: account)

        XCTAssertEqual(url.absoluteString, "https://codex.example.com/v1/usage")
    }

    func testCodexUsageURLPreservesURLPrefixForSelfServiceEndpoint() throws {
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: nil,
            externalUsageAccountId: nil,
            email: nil,
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )
        let configuration = CodexEndpointConfiguration(
            mode: .external(usageURL: URL(string: "https://codex.example.com/proxy/api/codex/usage")!),
            source: "test",
            usesOpenAIProviderBaseURL: false
        )

        let url = try provider.codexUsageURL(for: configuration, account: account)

        XCTAssertEqual(url.absoluteString, "https://codex.example.com/proxy/v1/usage")
    }

    func testCodexUsageURLDoesNotDoubleInjectV1ForAlreadyVersionedPath() throws {
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: nil,
            externalUsageAccountId: nil,
            email: nil,
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )
        // URL whose path ends in /v1/usage but has an extra prefix segment.
        // The old code would strip just "/usage" and append "/v1/usage", producing
        // the incorrect "/api/v1/v1/usage". The fix preserves the path as-is because
        // it already terminates with /v1/usage.
        let configuration = CodexEndpointConfiguration(
            mode: .external(usageURL: URL(string: "https://codex.example.com/api/v1/usage")!),
            source: "test",
            usesOpenAIProviderBaseURL: true
        )

        let url = try provider.codexUsageURL(for: configuration, account: account)

        XCTAssertEqual(url.absoluteString, "https://codex.example.com/api/v1/usage")
        XCTAssertFalse(url.path.contains("/v1/v1"), "Path must not contain a double /v1 injection")
    }

    func testCodexUsageURLPreservesAlreadySelfServiceEndpoint() throws {
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: nil,
            externalUsageAccountId: nil,
            email: nil,
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )
        let configuration = CodexEndpointConfiguration(
            mode: .external(usageURL: URL(string: "https://codex.example.com/v1/usage")!),
            source: "test",
            usesOpenAIProviderBaseURL: true
        )

        let url = try provider.codexUsageURL(for: configuration, account: account)

        XCTAssertEqual(url.absoluteString, "https://codex.example.com/v1/usage")
    }

    func testCodexUsageURLRejectsDirectChatGPTModeForAPIKey() {
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: nil,
            externalUsageAccountId: nil,
            email: nil,
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )
        let configuration = CodexEndpointConfiguration(
            mode: .directChatGPT,
            source: "test",
            usesOpenAIProviderBaseURL: false
        )

        XCTAssertThrowsError(try provider.codexUsageURL(for: configuration, account: account)) { error in
            guard case let ProviderError.authenticationFailed(message) = error else {
                return XCTFail("Expected authenticationFailed, got \(error)")
            }
            XCTAssertEqual(message, "Codex API key requires an external codex-lb endpoint")
        }
    }

    func testCodexRequestAccountIDOmittedForAPIKeySelfService() {
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: "should-not-be-used",
            externalUsageAccountId: "chatgpt-account-id",
            email: nil,
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )

        let accountID = provider.codexRequestAccountID(
            for: account,
            endpointMode: .external(usageURL: URL(string: "https://codex.example.com/api/codex/usage")!)
        )

        XCTAssertNil(accountID)
    }

    func testDecodeUsagePayloadMapsSelfServiceLimitsToCodexWindows() throws {
        let json = """
        {
          "request_count": 321,
          "total_tokens": 654321,
          "cached_input_tokens": 12345,
          "total_cost_usd": 11.75,
          "limits": [
            {
              "limit_type": "requests",
              "limit_window": "5h",
              "max_value": 200,
              "current_value": 50,
              "remaining_value": 150,
              "model_filter": null,
              "reset_at": "2026-04-02T12:00:00Z"
            },
            {
              "limit_type": "requests",
              "limit_window": "7d",
              "max_value": 1000,
              "current_value": 300,
              "remaining_value": 700,
              "model_filter": null,
              "reset_at": "2026-04-09T12:00:00Z"
            },
            {
              "limit_type": "requests",
              "limit_window": "5h",
              "max_value": 400,
              "current_value": 40,
              "remaining_value": 360,
              "model_filter": "gpt-5.3-codex-spark",
              "reset_at": "2026-04-02T13:00:00Z"
            },
            {
              "limit_type": "requests",
              "limit_window": "7d",
              "max_value": 1400,
              "current_value": 140,
              "remaining_value": 1260,
              "model_filter": "gpt-5.3-codex-spark",
              "reset_at": "2026-04-09T13:00:00Z"
            }
          ]
        }
        """
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: nil,
            externalUsageAccountId: nil,
            email: "user@example.com",
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )
        let configuration = CodexEndpointConfiguration(
            mode: .external(usageURL: URL(string: "https://codex.example.com/api/codex/usage")!),
            source: "test",
            usesOpenAIProviderBaseURL: true
        )

        let payload = try provider.decodeUsagePayload(
            data: XCTUnwrap(json.data(using: .utf8)),
            account: account,
            endpointConfiguration: configuration
        )

        XCTAssertEqual(payload.usage.usagePercentage, 25.0, accuracy: 0.001)
        XCTAssertEqual(payload.details.dailyUsage ?? 0, 25.0, accuracy: 0.001)
        XCTAssertEqual(payload.details.secondaryUsage ?? 0, 30.0, accuracy: 0.001)
        XCTAssertEqual(payload.details.codexPrimaryWindowLabel, "5h")
        XCTAssertEqual(payload.details.codexSecondaryWindowLabel, "Weekly")
        XCTAssertEqual(payload.details.codexPrimaryWindowHours, 5)
        XCTAssertEqual(payload.details.codexSecondaryWindowHours, 168)
        XCTAssertEqual(payload.details.sparkUsage ?? 0, 10.0, accuracy: 0.001)
        XCTAssertEqual(payload.details.sparkSecondaryUsage ?? 0, 10.0, accuracy: 0.001)
        XCTAssertEqual(payload.details.sparkWindowLabel, "Gpt 5.3 Codex Spark")
        XCTAssertEqual(payload.details.sparkPrimaryWindowLabel, "5h")
        XCTAssertEqual(payload.details.sparkSecondaryWindowLabel, "Weekly")
        XCTAssertEqual(payload.details.monthlyCost ?? 0, 11.75, accuracy: 0.001)
    }

    func testDecodeUsagePayloadDerivesStandardWindowLabelsFromLimitSeconds() throws {
        let json = """
        {
          "plan_type": "plus",
          "rate_limit": {
            "primary_window": {
              "used_percent": 20,
              "limit_window_seconds": 21600,
              "reset_after_seconds": 3600
            },
            "secondary_window": {
              "used_percent": 35,
              "limit_window_seconds": 1209600,
              "reset_after_seconds": 86400
            },
            "spark_primary_window": {
              "used_percent": 10,
              "limit_window_seconds": 43200,
              "reset_after_seconds": 1800
            },
            "spark_secondary_window": {
              "used_percent": 12,
              "limit_window_seconds": 2419200,
              "reset_after_seconds": 7200
            }
          }
        }
        """
        let account = OpenAIAuthAccount(
            accessToken: "oauth-token",
            accountId: "account-id",
            externalUsageAccountId: nil,
            email: "user@example.com",
            authSource: "auth.json",
            sourceLabels: ["Codex Auth"],
            source: .codexAuth,
            credentialType: .oauthBearer
        )
        let configuration = CodexEndpointConfiguration(
            mode: .directChatGPT,
            source: "test",
            usesOpenAIProviderBaseURL: false
        )

        let payload = try provider.decodeUsagePayload(
            data: XCTUnwrap(json.data(using: .utf8)),
            account: account,
            endpointConfiguration: configuration
        )

        XCTAssertEqual(payload.details.codexPrimaryWindowLabel, "6h")
        XCTAssertEqual(payload.details.codexPrimaryWindowHours, 6)
        XCTAssertEqual(payload.details.codexSecondaryWindowLabel, "14d")
        XCTAssertEqual(payload.details.codexSecondaryWindowHours, 336)
        XCTAssertEqual(payload.details.sparkPrimaryWindowLabel, "12h")
        XCTAssertEqual(payload.details.sparkPrimaryWindowHours, 12)
        XCTAssertEqual(payload.details.sparkSecondaryWindowLabel, "28d")
        XCTAssertEqual(payload.details.sparkSecondaryWindowHours, 672)
    }

    func testDecodeUsagePayloadKeepsThirtyDayWindowAsThirtyDays() throws {
        let json = """
        {
          "plan_type": "plus",
          "rate_limit": {
            "secondary_window": {
              "used_percent": 35,
              "limit_window_seconds": 2592000,
              "reset_after_seconds": 86400
            }
          }
        }
        """
        let account = OpenAIAuthAccount(
            accessToken: "oauth-token",
            accountId: "account-id",
            externalUsageAccountId: nil,
            email: "user@example.com",
            authSource: "auth.json",
            sourceLabels: ["Codex Auth"],
            source: .codexAuth,
            credentialType: .oauthBearer
        )
        let configuration = CodexEndpointConfiguration(
            mode: .directChatGPT,
            source: "test",
            usesOpenAIProviderBaseURL: false
        )

        let payload = try provider.decodeUsagePayload(
            data: XCTUnwrap(json.data(using: .utf8)),
            account: account,
            endpointConfiguration: configuration
        )

        XCTAssertEqual(payload.details.codexPrimaryWindowLabel, "30d")
        XCTAssertEqual(payload.details.codexPrimaryWindowHours, 720)
    }

    func testDecodeUsagePayloadKeepsTwentyNineDayWindowAsTwentyNineDays() throws {
        let json = """
        {
          "plan_type": "plus",
          "rate_limit": {
            "secondary_window": {
              "used_percent": 35,
              "limit_window_seconds": 2505600,
              "reset_after_seconds": 86400
            }
          }
        }
        """
        let account = OpenAIAuthAccount(
            accessToken: "oauth-token",
            accountId: "account-id",
            externalUsageAccountId: nil,
            email: "user@example.com",
            authSource: "auth.json",
            sourceLabels: ["Codex Auth"],
            source: .codexAuth,
            credentialType: .oauthBearer
        )
        let configuration = CodexEndpointConfiguration(
            mode: .directChatGPT,
            source: "test",
            usesOpenAIProviderBaseURL: false
        )

        let payload = try provider.decodeUsagePayload(
            data: XCTUnwrap(json.data(using: .utf8)),
            account: account,
            endpointConfiguration: configuration
        )

        XCTAssertEqual(payload.details.codexPrimaryWindowLabel, "29d")
        XCTAssertEqual(payload.details.codexPrimaryWindowHours, 696)
    }

    func testDecodeUsagePayloadHandlesMissingLimitsKeyGracefully() throws {
        let json = """
        {
          "request_count": 100,
          "total_cost_usd": 5.0
        }
        """
        let account = OpenAIAuthAccount(
            accessToken: "sk-clb-test",
            accountId: nil,
            externalUsageAccountId: nil,
            email: "user@example.com",
            authSource: "auth.json",
            sourceLabels: ["OpenCode (API Key)"],
            source: .opencodeAuth,
            credentialType: .apiKey
        )
        let configuration = CodexEndpointConfiguration(
            mode: .external(usageURL: URL(string: "https://codex.example.com/api/codex/usage")!),
            source: "test",
            usesOpenAIProviderBaseURL: true
        )

        let payload = try provider.decodeUsagePayload(
            data: XCTUnwrap(json.data(using: .utf8)),
            account: account,
            endpointConfiguration: configuration
        )

        // No limits → no used percentage; provider shows 0% used (100 remaining)
        XCTAssertEqual(payload.usage.remainingQuota, 100)
        XCTAssertEqual(payload.details.monthlyCost ?? 0, 5.0, accuracy: 0.001)
    }

    private func loadFixture(named: String) throws -> Any {
        let testBundle = Bundle(for: type(of: self))
        
        guard let url = testBundle.url(forResource: named, withExtension: "json") else {
            throw NSError(domain: "FixtureError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fixture file not found: \(named)"])
        }
        
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        return json
    }

    // MARK: - UsageBar Codex Account Store Tests

    func testStoredCodexAccountMetadataRoundTripsAndSortsByAddedAt() throws {
        let (store, backend, cleanup) = makeCodexAccountStore()
        defer { cleanup() }

        let olderDate = Date(timeIntervalSince1970: 1_700_000_000)
        let newerDate = olderDate.addingTimeInterval(60)

        _ = try store.upsert(
            email: "later@example.com",
            accountId: "acc-later",
            authSourceSnapshot: "~/.codex/auth.json",
            secrets: StoredCodexAccountSecrets(
                accessToken: "access-later",
                refreshToken: "refresh-later",
                idToken: "id-later",
                expiresAt: newerDate
            )
        )
        Thread.sleep(forTimeInterval: 1.1)
        _ = try store.upsert(
            email: "earlier@example.com",
            accountId: "acc-earlier",
            authSourceSnapshot: "~/.codex/auth.json",
            secrets: StoredCodexAccountSecrets(
                accessToken: "access-earlier",
                refreshToken: "refresh-earlier",
                idToken: "id-earlier",
                expiresAt: olderDate
            )
        )

        let records = store.loadRecords()
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0].metadata.email, "later@example.com")
        XCTAssertEqual(records[1].metadata.email, "earlier@example.com")
        XCTAssertEqual(backend.savedAccountIDs.count, 2)
    }

    func testStoredCodexAccountUpsertUpdatesExistingRecordInsteadOfDuplicating() throws {
        let (store, _, cleanup) = makeCodexAccountStore()
        defer { cleanup() }

        let firstMetadata = try store.upsert(
            email: "user@example.com",
            accountId: "acc-1",
            authSourceSnapshot: "~/.codex/auth.json",
            secrets: StoredCodexAccountSecrets(
                accessToken: "access-1",
                refreshToken: "refresh-1",
                idToken: "id-1",
                expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )

        let secondMetadata = try store.upsert(
            email: "user@example.com",
            accountId: "acc-1",
            authSourceSnapshot: "~/.codex/auth.json",
            secrets: StoredCodexAccountSecrets(
                accessToken: "access-2",
                refreshToken: "refresh-2",
                idToken: "id-2",
                expiresAt: Date(timeIntervalSince1970: 1_700_000_100)
            )
        )

        let records = store.loadRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(firstMetadata.id, secondMetadata.id)
        XCTAssertEqual(records[0].secrets.accessToken, "access-2")
        XCTAssertEqual(records[0].secrets.refreshToken, "refresh-2")
    }

    func testStoredCodexAccountRemovalDeletesMetadataAndSecrets() throws {
        let (store, backend, cleanup) = makeCodexAccountStore()
        defer { cleanup() }

        let metadata = try store.upsert(
            email: "remove@example.com",
            accountId: "acc-remove",
            authSourceSnapshot: "~/.codex/auth.json",
            secrets: StoredCodexAccountSecrets(
                accessToken: "access-remove",
                refreshToken: "refresh-remove",
                idToken: "id-remove",
                expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )

        XCTAssertNotNil(backend.storage[metadata.id])

        try store.remove(accountID: metadata.id)

        XCTAssertTrue(store.loadRecords().isEmpty)
        XCTAssertNil(backend.storage[metadata.id])
    }

    func testStoredCodexAccountRefreshFailureIsPersisted() throws {
        let (store, _, cleanup) = makeCodexAccountStore()
        defer { cleanup() }

        let metadata = try store.upsert(
            email: "failure@example.com",
            accountId: "acc-failure",
            authSourceSnapshot: "~/.codex/auth.json",
            secrets: StoredCodexAccountSecrets(
                accessToken: "access-failure",
                refreshToken: "refresh-failure",
                idToken: "id-failure",
                expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )

        store.markRefreshFailure(accountID: metadata.id, reason: "HTTP 401 during preflight")

        let record = try XCTUnwrap(store.loadRecords().first)
        XCTAssertNotNil(record.metadata.lastRefreshFailureAt)
        XCTAssertEqual(record.metadata.lastRefreshFailureReason, "HTTP 401 during preflight")
    }

    func testStoredCodexSourcePriorityHigherThanNativeCodex() {
        let storedAccount = OpenAIAuthAccount(
            accessToken: "token-stored",
            accountId: "shared-id",
            externalUsageAccountId: nil,
            email: "user@example.com",
            authSource: "UsageBar Codex Accounts",
            sourceLabels: ["UsageBar Codex Accounts"],
            source: .usageBarCodexAccounts,
            credentialType: .oauthBearer,
            storedCodexAccountID: "stored-1"
        )
        let nativeAccount = OpenAIAuthAccount(
            accessToken: "token-native",
            accountId: "shared-id",
            externalUsageAccountId: nil,
            email: "user@example.com",
            authSource: "~/.codex/auth.json",
            sourceLabels: ["Codex"],
            source: .codexAuth,
            credentialType: .oauthBearer
        )

        let storedSelectionKey = TokenManager.shared.codexStatusBarSelectionKey(for: storedAccount, index: 0)
        let nativeSelectionKey = TokenManager.shared.codexStatusBarSelectionKey(for: nativeAccount, index: 1)

        XCTAssertEqual(storedSelectionKey, nativeSelectionKey)
        XCTAssertEqual(storedAccount.source, .usageBarCodexAccounts)
        XCTAssertEqual(nativeAccount.source, .codexAuth)
    }

    func testExpiredStoredCodexAccountRefreshesBeforeUsageRequest() async throws {
        let session = makeMockSession()
        let previousSession = TokenManager.shared.codexOAuthSession
        TokenManager.shared.codexOAuthSession = session
        defer {
            TokenManager.shared.codexOAuthSession = previousSession
            MockURLProtocol.requestHandler = nil
        }

        var refreshRequests = 0
        var usageRequests = 0
        MockURLProtocol.requestHandler = { request in
            if request.url?.host == "auth.openai.com" {
                refreshRequests += 1
                let response = HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                let body = """
                {
                  "access_token": "refreshed-access-token",
                  "refresh_token": "refreshed-refresh-token",
                  "expires_in": 3600,
                  "id_token": "refreshed-id-token"
                }
                """
                return (response, Data(body.utf8))
            }

            usageRequests += 1
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-access-token")
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {
              "plan_type": "plus",
              "rate_limit": {
                "primary_window": {
                  "used_percent": 20,
                  "limit_window_seconds": 18000,
                  "reset_after_seconds": 60
                }
              }
            }
            """
            return (response, Data(body.utf8))
        }

        let provider = CodexProvider(session: session)
        let account = OpenAIAuthAccount(
            accessToken: "expired-access-token",
            accountId: "account-id",
            externalUsageAccountId: nil,
            email: "user@example.com",
            refreshToken: "refresh-token",
            idToken: "id-token",
            expiresAt: Date().addingTimeInterval(-60),
            authSource: "UsageBar Codex Accounts",
            sourceLabels: ["UsageBar Codex Accounts"],
            source: .usageBarCodexAccounts,
            credentialType: .oauthBearer,
            storedCodexAccountID: "stored-account-id"
        )

        let candidate = try await provider.fetchUsageForAccount(account, index: 0)

        XCTAssertEqual(refreshRequests, 1)
        XCTAssertEqual(usageRequests, 1)
        XCTAssertEqual(candidate.details.authUsageSummary, "UsageBar Codex Accounts")
        XCTAssertEqual(candidate.usage.remainingQuota, 80)
    }

    func testStoredCodexAccountUsage401RetriesRefreshOnlyOnce() async throws {
        let session = makeMockSession()
        let previousSession = TokenManager.shared.codexOAuthSession
        TokenManager.shared.codexOAuthSession = session
        defer {
            TokenManager.shared.codexOAuthSession = previousSession
            MockURLProtocol.requestHandler = nil
        }

        var refreshRequests = 0
        var usageRequests = 0
        MockURLProtocol.requestHandler = { request in
            if request.url?.host == "auth.openai.com" {
                refreshRequests += 1
                let response = HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                let body = """
                {
                  "access_token": "retry-access-token",
                  "refresh_token": "retry-refresh-token",
                  "expires_in": 3600,
                  "id_token": "retry-id-token"
                }
                """
                return (response, Data(body.utf8))
            }

            usageRequests += 1
            let authHeader = request.value(forHTTPHeaderField: "Authorization")
            if usageRequests == 1 {
                XCTAssertEqual(authHeader, "Bearer initial-access-token")
                let response = HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data("{}".utf8))
            }

            XCTAssertEqual(authHeader, "Bearer retry-access-token")
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {
              "plan_type": "plus",
              "rate_limit": {
                "primary_window": {
                  "used_percent": 10,
                  "limit_window_seconds": 18000,
                  "reset_after_seconds": 60
                }
              }
            }
            """
            return (response, Data(body.utf8))
        }

        let provider = CodexProvider(session: session)
        let account = OpenAIAuthAccount(
            accessToken: "initial-access-token",
            accountId: "account-id",
            externalUsageAccountId: nil,
            email: "user@example.com",
            refreshToken: "refresh-token",
            idToken: "id-token",
            expiresAt: Date().addingTimeInterval(3600),
            authSource: "UsageBar Codex Accounts",
            sourceLabels: ["UsageBar Codex Accounts"],
            source: .usageBarCodexAccounts,
            credentialType: .oauthBearer,
            storedCodexAccountID: "stored-account-id"
        )

        let candidate = try await provider.fetchUsageForAccount(account, index: 0)

        XCTAssertEqual(refreshRequests, 1)
        XCTAssertEqual(usageRequests, 2)
        XCTAssertEqual(candidate.usage.remainingQuota, 90)
    }

    private func makeCodexAccountStore() -> (CodexAccountStore, InMemoryCodexAccountSecretsBackend, () -> Void) {
        let suiteName = "CodexAccountStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let backend = InMemoryCodexAccountSecretsBackend()
        let store = CodexAccountStore(
            defaults: defaults,
            secretsBackend: backend
        )
        let cleanup = {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return (store, backend, cleanup)
    }

    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class InMemoryCodexAccountSecretsBackend: CodexAccountSecretsBackend {
    var storage: [String: Data] = [:]

    var savedAccountIDs: [String] {
        Array(storage.keys).sorted()
    }

    func read(accountID: String) -> Data? {
        storage[accountID]
    }

    func write(_ data: Data, accountID: String) throws {
        storage[accountID] = data
    }

    func delete(accountID: String) throws {
        storage.removeValue(forKey: accountID)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
