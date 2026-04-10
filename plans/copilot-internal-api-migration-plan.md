# GitHub Copilot Internal API Migration Plan

## Goal

Reduce delay in GitHub Copilot usage updates by making the Internal API path the primary source for quota data, while keeping the current cookie and billing-based path as a fallback for overage and history data.

## Background

The current `opencode-bar` implementation already uses two different Copilot data sources, but they are not used with the right priority.

Current state in `opencode-bar`:
- `CopilotProvider` still uses browser cookies, billing page scraping, `customerId` extraction, and `copilot_usage_card` as the main usage path.
- `TokenManager` already calls `https://api.github.com/copilot_internal/user`, but only as a secondary plan and quota enrichment step.

Reference implementation in `ClaudeBar`:
- `CopilotInternalAPIProbe` uses `https://api.github.com/copilot_internal/user` directly as the quota source.
- `CopilotProvider` supports a dual-probe structure and selects the active probe explicitly.

## Current Findings

### `opencode-bar` current main path

- `CopilotMonitor/CopilotMonitor/Providers/CopilotProvider.swift:36`
  - `fetch()` starts from cookie-based fetching.
- `CopilotMonitor/CopilotMonitor/Providers/CopilotProvider.swift:396`
  - `fetchCustomerId(cookies:)` depends on scraping `https://github.com/settings/billing`.
- `CopilotMonitor/CopilotMonitor/Providers/CopilotProvider.swift:473`
  - `fetchUsageData(customerId:cookies:)` depends on `copilot_usage_card`.
- `CopilotMonitor/CopilotMonitor/Services/CopilotHistoryService.swift:20`
  - history fetching also depends on cookies and billing endpoints.

### `opencode-bar` existing Internal API support

- `CopilotMonitor/CopilotMonitor/Services/TokenManager.swift:3427`
  - `fetchCopilotPlanInfo(accessToken:)` already calls `https://api.github.com/copilot_internal/user`.
- `CopilotMonitor/CopilotMonitor/Services/TokenManager.swift:3502`
  - quota fields are already parsed from `quota_snapshots`, `monthly_quotas`, and legacy fields.
- `CopilotMonitor/CopilotMonitor/Providers/CopilotProvider.swift:296`
  - token-derived candidates already exist, but they are not the primary source for usage.

### `ClaudeBar` reference path

- `/Users/hypered/Github/ClaudeBar/Sources/Infrastructure/Copilot/CopilotInternalAPIProbe.swift:72`
  - direct request to `GET /copilot_internal/user`.
- `/Users/hypered/Github/ClaudeBar/Sources/Infrastructure/Copilot/CopilotInternalAPIProbe.swift:125`
  - parses `premium_interactions` into entitlement, remaining, unlimited, and percent values.
- `/Users/hypered/Github/ClaudeBar/Sources/Domain/Provider/Copilot/CopilotProvider.swift:79`
  - explicit active-probe selection pattern.

## Root Cause Hypothesis

The delay is more likely caused by the current primary data path being heavier and more failure-prone than necessary, not by framework-level throttling.

Supporting evidence:
- `CopilotMonitor/CopilotMonitor/Models/ProviderProtocol.swift:141`
  - default `minimumFetchInterval` is `0`.
- `CopilotProvider` does not override `minimumFetchInterval`.
- The current main path requires several sequential steps:
  - browser cookie discovery
  - billing page fetch
  - HTML parsing for `customerId`
  - usage card API fetch
  - optional history fetch

## Migration Strategy

### Primary direction

Use `copilot_internal/user` as the primary source for current quota usage.

Expected benefits:
- fewer sequential network steps
- lower dependence on browser login state
- more direct and timely quota updates
- less risk of falling back to stale cached usage

### Fallback direction

Keep the current cookie and billing-based path for data that the Internal API may not provide well enough.

Keep cookie and billing fallback for:
- overage cost
- overage request count
- daily history submenu data
- cases where token-based Internal API access is unavailable

## Implementation Plan

### 1. Introduce a dedicated Internal API usage parser

Create a small parsing layer for the `copilot_internal/user` response that is focused on current usage values, not just plan metadata.

Minimum output fields:
- plan name
- quota reset date
- entitlement
- remaining
- used
- unlimited flag
- overage-permitted flag if available

Notes:
- Prefer the `premium_interactions` snapshot when present.
- Preserve the existing fallback parsing already implemented in `TokenManager` for older response shapes.
- Keep the implementation minimal and avoid broad refactoring.

### 2. Change `CopilotProvider.fetch()` priority order

Target file:
- `CopilotMonitor/CopilotMonitor/Providers/CopilotProvider.swift`

New priority order:
1. token-based Internal API usage
2. cookie and billing usage path
3. cached usage

Expected behavior:
- if Internal API succeeds, use it as the main quota source
- if cookie and billing data is also available, merge only the fields that Internal API does not provide well
- if Internal API fails, keep the current cookie path as the immediate fallback

### 3. Keep history loading separate from main quota freshness

Do not let history fetching block or degrade the freshness of the primary Copilot quota row.

Rules:
- current quota should be ready from Internal API without requiring history success
- history can remain a secondary asynchronous enrichment path
- failure to load history must not downgrade the main quota result if Internal API succeeded

### 4. Preserve current overage display behavior

The current implementation shows Copilot add-on and overage information using billing-derived fields.

Required behavior after migration:
- keep `copilotOverageCost` when billing data is available
- keep `copilotOverageRequests` when billing data is available
- do not regress add-on related UI behavior

### 5. Add clear debug logging around source selection

Required logging points:
- Internal API selected as primary source
- cookie and billing path used as fallback
- merged result contains Internal API quota plus billing overage details
- cache used only after both primary and fallback paths fail

All logs must remain in English.

## Data Mapping Plan

### Internal API to provider model

Map fields as follows:
- `copilot_plan` or equivalent -> `DetailedUsage.planType`
- `quota_reset_date_utc` or fallback date field -> `DetailedUsage.copilotQuotaResetDateUTC`
- `entitlement` -> `DetailedUsage.copilotLimitRequests`
- `used = entitlement - remaining` -> `DetailedUsage.copilotUsedRequests`
- `remaining` -> `ProviderUsage.quotaBased.remaining`
- `entitlement` -> `ProviderUsage.quotaBased.entitlement`

### Billing fallback to provider model

Keep fields from billing path when available:
- `netBilledAmount` -> `DetailedUsage.copilotOverageCost`
- `netQuantity` -> `DetailedUsage.copilotOverageRequests`
- `dailyHistory` -> `DetailedUsage.dailyHistory`

## Edge Cases To Handle

### Unlimited plans

If `premium_interactions.unlimited == true`:
- avoid invalid percentage math
- avoid `0/0` style rendering
- keep output stable for both menu row and status aggregation

### No premium interactions quota present

If `quota_snapshots.premium_interactions` is missing:
- do not treat it as a decoding failure automatically
- decide on a stable provider result representation before implementation
- ensure UI does not regress or show misleading exhaustion state

### Internal API unavailable but cookies valid

If token-based Internal API fails and cookie-based billing still works:
- keep the current cookie path usable
- do not surface a hard failure if a valid fallback result exists

### Both live paths fail

If both Internal API and cookie-based billing fail:
- use cached usage if available
- preserve the current graceful degradation behavior

## Scope

### In Scope

- promote Internal API to primary Copilot quota source
- preserve cookie and billing path as fallback and enrichment
- keep Copilot add-on and history behavior intact
- add source-selection logging
- update relevant tests

### Out of Scope

- adding a new user-facing settings toggle for Copilot probe mode
- rewriting all Copilot history fetching logic
- changing menu structure or labeling
- changing subscription or add-on product semantics

## Files Expected To Change Later

Primary files:
- `CopilotMonitor/CopilotMonitor/Providers/CopilotProvider.swift`
- `CopilotMonitor/CopilotMonitor/Services/TokenManager.swift`
- `CopilotMonitor/CopilotMonitor/Models/CopilotUsage.swift`

Possible test files:
- `CopilotMonitor/CopilotMonitorTests/CopilotProviderTests.swift`

Possible secondary files if model changes require them:
- `CopilotMonitor/CopilotMonitor/Models/ProviderResult.swift`

## Verification Plan

### Code-level verification

- build succeeds without Swift compile errors
- Copilot tests pass
- any updated parsing tests cover both old and new API shapes

### Runtime verification

After implementation, verify the following in the app:
1. Copilot quota row refreshes from Internal API without requiring cookie-derived usage success.
2. Copilot usage updates are visible sooner than before in normal refresh cycles.
3. Copilot add-on cost still appears when billing data is available.
4. Copilot history submenu still loads when cookies are available.
5. When Internal API fails but cookies still work, the Copilot row still shows usable data.
6. When both live sources fail, cached Copilot data is still used.

### Logging verification

Confirm logs clearly show which source produced the final Copilot result:
- Internal API
- cookie and billing fallback
- merged Internal API plus billing result
- cache fallback

## Risks

### Medium risk

- GitHub may change the Internal API response schema.
- Some accounts may have token access differences across environments.
- Internal API may not fully replace billing-derived overage information.

### Mitigation

- keep the cookie and billing path intact during the migration
- prefer the smallest possible change in `CopilotProvider`
- add tests for unlimited and missing-quota cases
- keep cache fallback behavior unchanged

## Definition of Done

This migration is complete when all of the following are true:

- Copilot current quota uses Internal API as the primary source.
- Cookie and billing usage remains available as fallback and enrichment.
- Copilot add-on cost behavior does not regress.
- Copilot history behavior does not regress.
- Cache fallback still works.
- Relevant tests pass.
- The app builds successfully.
