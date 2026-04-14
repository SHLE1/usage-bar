# Codex Multi Auth Integration Plan

## Status

Plan only. Do not implement any code changes in this round.

## Goal

Add first-class support for `codex-multi-auth` to the UsageBar Codex provider.

Primary requirement from the user:
- Codex-related configuration and account discovery must prefer `codex-multi-auth`
- Only when `codex-multi-auth` files or directories do not exist should the provider fall back to existing Codex and OpenCode sources

Local reference repository:
- `/Users/hypered/Github/codex-multi-auth`

## Summary of the Intended Direction

The current project already supports several OpenAI/Codex-related auth sources:
- OpenCode auth
- OpenCode multi-auth compatibility files under `.opencode`
- `codex-lb`
- native Codex auth under `~/.codex/auth.json`

The planned change is to make `codex-multi-auth` the primary source for Codex account discovery and Codex usage cache discovery.

This is not a rewrite of the Codex provider. It is an adapter-style integration with a strict priority order.

## New Priority Rules

### 1. Codex account source priority

Codex account discovery should use this order:

1. `codex-multi-auth`
   - `CODEX_MULTI_AUTH_DIR/openai-codex-accounts.json`
   - `CODEX_MULTI_AUTH_DIR/projects/*/openai-codex-accounts.json`
   - `~/.codex/multi-auth/openai-codex-accounts.json`
   - `~/.codex/multi-auth/projects/*/openai-codex-accounts.json`
2. native Codex auth
   - `~/.codex/auth.json`
3. OpenCode auth and OpenCode compatibility sources
   - current OpenCode OAuth source
   - current `.opencode/openai-codex-accounts.json` compatibility source
4. existing lower-priority compatibility sources that are still relevant
   - `codex-lb`

Important rule:
- If any valid `codex-multi-auth` account source exists, it becomes the primary Codex source for discovery and selection
- Fallback to native Codex or OpenCode should happen only when `codex-multi-auth` is absent or unusable

### 2. Codex usage cache priority

For Codex quota display and fallback behavior, use this order:

1. live usage fetch using the selected account
2. `codex-multi-auth` quota cache
   - `CODEX_MULTI_AUTH_DIR/quota-cache.json`
   - `~/.codex/multi-auth/quota-cache.json`
3. existing Codex/OpenCode live fallback behavior if still applicable

### 3. Configuration priority

Codex endpoint-related configuration should prefer `codex-multi-auth` runtime presence when deciding the primary discovery root.

This does not mean UsageBar should execute or mutate `codex-multi-auth` settings. It means:
- if `codex-multi-auth` storage exists, treat it as the canonical source for account pool resolution
- if it does not exist, use the current Codex/OpenCode resolution behavior

## Current Project State

### UsageBar already has reusable building blocks

The current codebase already has:
- multi-source OpenAI account discovery in `TokenManager`
- stable account selection keys using email/accountId/source fallback
- email-first subscription key behavior in `ProviderAccountResult.subscriptionId`
- deduplication with `CandidateDedupe.merge()`
- Codex provider support for direct ChatGPT endpoint and external/self-service endpoint handling
- existing compatibility support for `.opencode/openai-codex-accounts.json`

### codex-multi-auth exposes stable storage files

The cloned reference project documents these relevant files:
- `openai-codex-accounts.json`
- `quota-cache.json`
- `runtime-observability.json`
- project-scoped account files under `projects/<project-key>/`

It also supports a custom root via:
- `CODEX_MULTI_AUTH_DIR`

## In Scope

1. Add `codex-multi-auth` as a first-class Codex source in UsageBar
2. Prefer `codex-multi-auth` over native Codex and OpenCode
3. Read `codex-multi-auth` account storage directly from disk
4. Read `codex-multi-auth` quota cache as a fallback source
5. Preserve current UI behavior and current menu structure
6. Preserve current subscription key stability rules
7. Add tests for source priority, parsing, and fallback behavior
8. Keep all logs and comments in English

## Out of Scope

1. Do not modify the external `codex-multi-auth` repository
2. Do not call `codex auth login`, `codex auth switch`, or other mutating commands from UsageBar
3. Do not implement refresh-token consumption or token refresh logic in UsageBar
4. Do not change menu section titles or design decisions
5. Do not redesign the Codex settings UI unless required for source visibility
6. Do not depend on subprocess CLI execution as the main data path

## Design Decisions for This Integration

### A. Read-only integration

UsageBar should treat `codex-multi-auth` as a read-only external state source.

UsageBar may read:
- account pool files
- quota cache files
- runtime observability files later if needed

UsageBar should not:
- rewrite those files
- switch accounts for the user
- refresh tokens
- repair storage

### B. Cache-first fallback instead of token refresh

If a `codex-multi-auth` account has no usable access token, or live usage fetch fails, UsageBar should fall back to `quota-cache.json` when possible.

This keeps the app stable and avoids coupling UsageBar to the external auth manager's token lifecycle.

### C. Preserve current endpoint model

The existing Codex endpoint logic in UsageBar should remain in place.

The planned integration changes the account source priority, not the endpoint architecture.

## Detailed Implementation Plan

## Phase 0 - Plan and source mapping only

Deliverable:
- this plan document only

No code changes.

## Phase 1 - Add `codex-multi-auth` account discovery

### Files expected to change

- `CopilotMonitor/CopilotMonitor/Services/TokenManager.swift`
- `CopilotMonitor/CopilotMonitor/Providers/CodexProvider.swift`
- `CopilotMonitor/CopilotMonitorTests/CodexProviderTests.swift`

### Planned changes

#### 1. Add a new OpenAI auth source for Codex multi-auth

In `TokenManager.swift`:
- add a new source enum case for `codexMultiAuth`
- add a user-facing source label such as `Codex Multi Auth`
- add source priority higher than native Codex and OpenCode compatibility sources

#### 2. Add codex-multi-auth path discovery

Implement a path resolver that checks in this order:

1. `CODEX_MULTI_AUTH_DIR`
   - `<env>/openai-codex-accounts.json`
   - `<env>/projects/*/openai-codex-accounts.json`
2. default root
   - `~/.codex/multi-auth/openai-codex-accounts.json`
   - `~/.codex/multi-auth/projects/*/openai-codex-accounts.json`

Rules:
- use both `fileExists` and `isReadableFile`
- keep deterministic sorted ordering
- avoid duplicate path entries

#### 3. Parse `openai-codex-accounts.json`

Map V3 account storage entries into `OpenAIAuthAccount`.

Expected source fields from the external project:
- `accountId`
- `email`
- `refreshToken`
- `accessToken`
- `expiresAt`
- `enabled`

Mapping rules:
- `accessToken` -> `OpenAIAuthAccount.accessToken`
- `accountId` -> `OpenAIAuthAccount.accountId`
- `email` -> `OpenAIAuthAccount.email`
- `authSource` -> exact file path
- `sourceLabels` -> `Codex Multi Auth`
- `source` -> new enum case
- `credentialType` -> OAuth bearer

Filtering rules:
- skip disabled accounts
- skip unreadable files
- skip accounts without usable access tokens for live fetch
- still allow those accounts to be considered later for quota-cache identity matching if needed

#### 4. Update global OpenAI account aggregation order

Update `getOpenAIAccounts()` so the order becomes:

1. codex-multi-auth
2. native Codex auth
3. OpenCode auth
4. OpenCode compatibility multi-auth
5. codex-lb

Note:
- final ordering may be slightly adjusted during implementation if the existing OpenCode direct OAuth must remain before some compatibility sources, but `codex-multi-auth` must stay first

#### 5. Preserve existing dedupe model

Do not replace the current dedupe architecture.

Continue using:
- primary identity by accountId when available
- secondary merge by email
- existing `CandidateDedupe.merge()` path in `CodexProvider`
- email-first subscription key behavior

## Phase 2 - Add `codex-multi-auth` quota-cache fallback

### Files expected to change

- `CopilotMonitor/CopilotMonitor/Providers/CodexProvider.swift`
- possibly a small new helper file under `CopilotMonitor/CopilotMonitor/Services/` or `Providers/`
- `CopilotMonitor/CopilotMonitorTests/CodexProviderTests.swift`

### Planned changes

#### 1. Add Swift models for `quota-cache.json`

Model these external structures:
- `byAccountId`
- `byEmail`
- entry fields:
  - `updatedAt`
  - `status`
  - `model`
  - `planType`
  - `primary.usedPercent`
  - `primary.windowMinutes`
  - `primary.resetAtMs`
  - `secondary.usedPercent`
  - `secondary.windowMinutes`
  - `secondary.resetAtMs`

#### 2. Add quota cache path discovery

Check in this order:

1. `CODEX_MULTI_AUTH_DIR/quota-cache.json`
2. `~/.codex/multi-auth/quota-cache.json`

Rules:
- require readability check
- fail silently for missing files
- log clear English debug messages for malformed cache entries

#### 3. Add cache lookup rules

When matching a cache entry to an account, use:
1. normalized email first
2. accountId second

This matches the project’s existing stability rule that prefers email for long-lived identity.

#### 4. Add fallback flow in `CodexProvider`

Planned behavior:
- first try live fetch for the selected account
- if live fetch succeeds, use live result
- if live fetch fails for that account, try `quota-cache.json`
- if cache exists and matches, build `DetailedUsage` from cache
- if neither live nor cache succeeds, keep the existing error path

#### 5. Cache output shape inside UsageBar

Convert cache windows into existing Codex detail fields:
- `primary.usedPercent` -> base short window usage
- `secondary.usedPercent` -> base long window usage
- `resetAtMs` -> `Date`
- `windowMinutes` -> derive display label and hours
- `planType` -> `DetailedUsage.planType`

Initial scope:
- support base windows first
- spark-specific cache enrichment is optional and can remain live-only unless the cache format clearly provides a stable model-specific mapping during implementation

## Phase 3 - Improve diagnostics and transparency

### Files expected to change

- `CopilotMonitor/CopilotMonitor/Services/TokenManager.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/CodexSettingsView.swift` if needed
- `CopilotMonitor/CopilotMonitorTests/...`

### Planned changes

#### 1. Improve source visibility

Ensure the UI clearly shows where the active token/account came from.

Examples:
- `Token From: ~/.codex/multi-auth/openai-codex-accounts.json`
- `Token From: ~/.codex/multi-auth/projects/<project-key>/openai-codex-accounts.json`
- native fallback paths when multi-auth is absent

#### 2. Add debug logs

Add English debug logs for:
- discovered codex-multi-auth roots
- discovered account files
- skipped unreadable files
- skipped disabled accounts
- live fetch success/failure by source
- cache fallback hit/miss

#### 3. Optional later enhancement

Later, `runtime-observability.json` may be used for diagnostics only, not for initial quota display logic.

This is optional and not required for the first implementation.

## Planned Data Flow

### Preferred path

1. discover `codex-multi-auth`
2. load accounts from `openai-codex-accounts.json`
3. pick/dedupe accounts using current UsageBar rules
4. fetch live usage with current Codex endpoint logic
5. display results

### Fallback path

1. live fetch fails or usable token is unavailable
2. load `quota-cache.json`
3. match by email first, then accountId
4. build `DetailedUsage` from cache
5. display cached usage

### Final fallback path

1. `codex-multi-auth` does not exist at all
2. fall back to native Codex auth and current OpenCode compatibility sources
3. use current behavior

## Testing Plan

## Unit tests to add or update

### TokenManager tests

1. reads accounts from `CODEX_MULTI_AUTH_DIR`
2. falls back to `~/.codex/multi-auth` when env var is absent
3. prefers codex-multi-auth over native Codex/OpenCode sources
4. skips disabled accounts
5. skips unreadable files
6. dedupes by accountId and email correctly
7. preserves source labels and authSource path

### CodexProvider tests

1. live fetch from codex-multi-auth account succeeds
2. live fetch fails and quota cache fallback succeeds
3. cache matches by email before accountId
4. cache-based detail mapping produces correct primary and secondary windows
5. no codex-multi-auth present -> fallback to native Codex and OpenCode behavior
6. source priority keeps codex-multi-auth candidates ahead of fallback sources

### Regression tests

1. existing native `~/.codex/auth.json` parsing still works
2. existing OpenCode auth parsing still works
3. existing OpenCode compatibility file parsing still works
4. existing selection key behavior stays stable
5. existing subscription key behavior stays email-first

## Risks and Mitigations

### Risk 1: project-scoped files duplicate global files

Mitigation:
- dedupe accounts by accountId and email
- keep deterministic path ordering

### Risk 2: some account entries have refresh token but no access token

Mitigation:
- do not implement refresh flow
- use cache fallback only

### Risk 3: stale quota cache shows slightly outdated values

Mitigation:
- prefer live fetch whenever possible
- use cache only as fallback
- log when cached data is used

### Risk 4: source ordering breaks current users unexpectedly

Mitigation:
- add explicit tests for source priority
- keep full fallback path intact

## Acceptance Criteria

The work is complete when all of the following are true:

1. UsageBar can discover Codex accounts from `codex-multi-auth`
2. `codex-multi-auth` is preferred over native Codex and OpenCode sources
3. if `codex-multi-auth` is absent, existing Codex/OpenCode behavior still works
4. Codex quota display can fall back to `quota-cache.json`
5. UI shows the correct token source path
6. no token refresh logic is added
7. existing menu labels and design decisions remain unchanged
8. tests cover source priority and cache fallback

## Proposed File Delivery

This plan file is stored at:
- `plans/codex-multi-auth-integration-plan.md`

## Next Step

If approved, the next round should implement Phase 1 first, then Phase 2, and only after that consider Phase 3.
