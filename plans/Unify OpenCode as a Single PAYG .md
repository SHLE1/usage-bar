# Plan: Unify OpenCode as a Single PAYG Provider

## Goal

Unify all OpenCode-related logic into a single canonical provider: `OpenCode`.

The final state must be:

- Only one OpenCode provider exists in UI and backend.
- OpenCode is treated as PAYG only.
- No OpenCode subscription plans, presets, or subscription totals remain.
- The legacy `OpenCode Zen` identity is removed from runtime logic, persisted settings, tests, and docs.
- Existing user preferences tied to `opencode_zen` are migrated to `open_code`.

## User Decision

Approved by user:

- Keep only one OpenCode PAYG concept.
- Do not add or keep OpenCode Go / OpenCode Zen subscription handling.
- Unify not only the UI but also the backend implementation.

## Current Findings

### Canonical problem

The app currently has two separate OpenCode-related identifiers:

- `ProviderIdentifier.openCode = "open_code"`
- `ProviderIdentifier.openCodeZen = "opencode_zen"`

Source:
- `CopilotMonitor/CopilotMonitor/Models/ProviderProtocol.swift:18-20`

But only `OpenCodeZenProvider` is actually registered and shown in the app:

- `CopilotMonitor/CopilotMonitor/Services/ProviderManager.swift:28-43`
- `CopilotMonitor/CLI/CLIProviderManager.swift:15-21`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift:1559-1579`

Meanwhile, `OpenCodeProvider` exists but is not used, and it appears to depend on a separate credits endpoint that is not the current effective data source:

- `CopilotMonitor/CopilotMonitor/Providers/OpenCodeProvider.swift:8-10`
- `CopilotMonitor/CopilotMonitor/Providers/OpenCodeProvider.swift:34`
- `CopilotMonitor/CopilotMonitor/Services/TokenManager.swift:3600-3603`

### Subscription state

OpenCode currently has no real subscription presets in code:

- `CopilotMonitor/CopilotMonitor/Models/SubscriptionSettings.swift:167-169`

However, stale subscription keys would still affect totals because `getTotalMonthlySubscriptionCost()` sums all saved subscription keys blindly:

- `CopilotMonitor/CopilotMonitor/Models/SubscriptionSettings.swift:265-270`

This means old `subscription_v2.open_code` or `subscription_v2.opencode_zen` entries must be cleaned during migration.

### Persisted preference impact

Provider identity is persisted in multiple UserDefaults keys using `identifier.rawValue`, so removing `opencode_zen` requires migration:

- enabled flag:
  - `provider.<rawValue>.enabled`
  - `CopilotMonitor/CopilotMonitor/App/Settings/AppPreferences.swift:113-123`
- pinned provider:
  - `StatusBarDisplayPreferences.providerKey`
  - `CopilotMonitor/CopilotMonitor/App/Settings/AppPreferences.swift:150-153`
- multi-provider selection:
  - `StatusBarDisplayPreferences.multiProviderProvidersKey`
  - `CopilotMonitor/CopilotMonitor/App/Settings/AppPreferences.swift:168-172`

## Target Architecture

### Canonical provider

Use only:

- `ProviderIdentifier.openCode = "open_code"`

Remove:

- `ProviderIdentifier.openCodeZen = "opencode_zen"`

### Canonical backend implementation

Use the current CLI-stats-based implementation as the real OpenCode provider behavior.

That means:

- Keep the fetch strategy currently implemented in `OpenCodeZenProvider`
- Move or merge it into `OpenCodeProvider`
- Delete the old unused credits-endpoint implementation
- Delete `OpenCodeZenProvider`

Reason:

- It matches the app's actual live behavior today
- It avoids keeping two parallel OpenCode code paths
- It removes the dormant `api.opencode.ai/v1/credits` path unless separately proven necessary later

## Non-Goals

This change will not:

- add OpenCode Go quota support
- add OpenCode Zen quota support
- keep any OpenCode subscription setting UI
- split OpenCode into separate Zen/Go runtime rows
- introduce backward-compatibility aliases beyond one-time preference migration

## Scope

### Backend code
- Provider identity
- Provider registration
- PAYG aggregation
- historical spend aggregation
- provider icons
- detail submenu routing
- CLI provider registry
- tests

### Persistence
- UserDefaults migration for provider identity
- cleanup of stale OpenCode subscription entries

### UI
- Replace user-facing `OpenCode Zen` labels with `OpenCode`

### Docs
- README
- design decision file
- any docs that still describe OpenCode Zen as a separate app concept inside OpenCode Bar

## File Impact

### Must change

1. `CopilotMonitor/CopilotMonitor/Models/ProviderProtocol.swift`
- remove `openCodeZen`
- keep `openCode`
- update `displayName`, `shortDisplayName`, `iconName`

2. `CopilotMonitor/CopilotMonitor/Providers/OpenCodeProvider.swift`
- replace current credits-endpoint logic with the current CLI stats logic
- keep identifier as `.openCode`

3. `CopilotMonitor/CopilotMonitor/Providers/OpenCodeZenProvider.swift`
- remove after logic is merged

4. `CopilotMonitor/CopilotMonitor/Services/ProviderManager.swift`
- register only `OpenCodeProvider()`

5. `CopilotMonitor/CLI/CLIProviderManager.swift`
- register only `.openCode`
- remove `.openCodeZen`

6. `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
- replace all `.openCodeZen` usages with `.openCode`
- update PAYG order
- update historical aggregation keys
- update provider order arrays
- update sample/debug/test fixture sections if any

7. `CopilotMonitor/CopilotMonitor/Helpers/ProviderMenuBuilder.swift`
- route OpenCode detail submenu through `.openCode`

8. `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- remove duplicate `openCodeZen`
- keep only `.openRouter, .openCode` in PAYG

9. `CopilotMonitor/CopilotMonitor/Views/SwiftUI/ModernStatusBarIconView.swift`
- remove `.openCodeZen` branch

10. `CopilotMonitor/CopilotMonitor/Views/MultiProviderStatusBarIconView.swift`
- remove `.openCodeZen` branch

11. `CopilotMonitor/CopilotMonitor/Models/SubscriptionSettings.swift`
- keep `openCode` presets empty
- remove `openCodeZen` preset entry and switch branch
- add cleanup handling note if migration helper is placed elsewhere

12. `CopilotMonitor/CopilotMonitor/App/Settings/AppPreferences.swift`
- add migration from `opencode_zen` to `open_code`

13. Tests
- `CopilotMonitor/CopilotMonitorTests/CLIFormatterTests.swift`
- `CopilotMonitor/CopilotMonitorTests/OpenCodeZenProviderTests.swift`
  - likely rename to `OpenCodeProviderTests.swift`
- any snapshots/assertions referring to `OpenCode Zen` or `opencode_zen`

14. Docs
- `README.md`
- `AGENTS-design-decisions.md`

### Should review

- `CopilotMonitor/CopilotMonitor/Models/ProviderResult.swift`
  - rename comments like `OpenCode Zen stats`
- any sample payload builders in `StatusBarController.swift`
- any CLI help/output examples that expose `opencode_zen`

## Migration Plan

### 1. Runtime identity migration

On app startup, before provider preferences are consumed, migrate:

- `provider.opencode_zen.enabled` -> `provider.open_code.enabled`
- pinned provider value `opencode_zen` -> `open_code`
- entries in `statusBarDisplay.multiProviderProviders` from `opencode_zen` -> `open_code`

Rules:

- if destination key already exists, do not overwrite user’s newer explicit choice
- deduplicate resulting provider arrays
- migration should be idempotent

### 2. Subscription cleanup

Delete stale subscription entries:

- `subscription_v2.opencode_zen`
- `subscription_v2.opencode_zen.*`
- `subscription_v2.open_code`
- `subscription_v2.open_code.*`

Reason:

- OpenCode must not contribute to subscription totals anymore
- stale keys would otherwise still inflate `Quota Status: $.../m`

### 3. No long-term alias support

After migration, the codebase should stop referring to `opencode_zen` entirely.

This avoids:
- duplicate providers
- split settings
- hidden state bugs
- future doc confusion

## Implementation Steps

### Phase 1. Collapse provider identity
- Remove `openCodeZen` from `ProviderIdentifier`
- Update all switch statements and provider arrays
- Update status bar, menu, icon, and CLI code to use only `.openCode`

### Phase 2. Collapse provider implementation
- Move the current CLI stats implementation from `OpenCodeZenProvider` into `OpenCodeProvider`
- Keep current debug logging, auth source, model breakdown, and history-related behavior
- Remove the unused credits-endpoint implementation
- Delete `OpenCodeZenProvider`

### Phase 3. Migrate persisted settings
- Add one-time migration helper in preferences/bootstrap path
- Migrate provider enablement, pinned provider, and multi-provider selections
- Remove stale OpenCode subscription entries

### Phase 4. Update UI wording
- Replace visible `OpenCode Zen` with `OpenCode`
- Ensure no duplicate OpenCode toggles remain in settings

### Phase 5. Update tests
- Rename and update provider identifier/display name assertions
- Preserve existing stats-adjustment test coverage by moving it to `OpenCodeProviderTests`

### Phase 6. Update docs and design decisions
- Replace OpenCode Zen wording with OpenCode where the app UI is concerned
- Explicitly document that OpenCode is treated as PAYG only in OpenCode Bar
- Remove any suggestion that OpenCode has subscription settings in this app

## Validation Plan

### Build and test
- Run targeted unit tests for:
  - provider identifier formatting
  - OpenCode stats adjustment logic
  - any provider serialization/output tests referencing raw provider ids
- Run app build
- Run app and verify logs

### Functional checks
1. Settings
- only one OpenCode toggle exists
- it appears in PAYG only
- no OpenCode row appears in subscription settings

2. Menu
- PAYG section shows `OpenCode`
- `OpenCode Zen` label does not appear anywhere
- no duplicate OpenCode row exists

3. Totals
- PAYG total still includes OpenCode spend
- Quota Status total does not include any OpenCode amount
- stale OpenCode subscription settings no longer affect totals

4. Persistence
- if a user previously enabled `OpenCode Zen`, the unified `OpenCode` remains enabled
- pinned provider and multi-provider selections continue to work after migration

5. CLI
- provider list exposes `open_code`
- `opencode_zen` is no longer emitted

## Risks

### Medium
Removing `openCodeZen` from `ProviderIdentifier` touches many switch statements.
Mitigation:
- do the identity collapse first
- compile immediately after each batch

### Medium
UserDefaults migration could accidentally drop provider visibility state.
Mitigation:
- make migration idempotent
- prefer destination value if already set
- add small focused tests if preferences test coverage exists nearby

### High
Stale subscription keys could keep affecting monthly totals even after UI cleanup.
Mitigation:
- explicitly remove both `subscription_v2.open_code*` and `subscription_v2.opencode_zen*`

### Low
Renaming tests/files may create noisy diffs.
Mitigation:
- keep behavior unchanged
- only rename where it improves clarity

## Rollback Point

If implementation fails midway, the safe rollback point is:

- restore `ProviderIdentifier.openCodeZen`
- restore `OpenCodeZenProvider` registration
- revert preference migration code
- revert doc wording changes

## Definition of Done

The work is done only when all of the following are true:

- `opencode_zen` no longer exists in runtime code paths
- only one OpenCode provider is shown in the app
- OpenCode is PAYG only
- OpenCode does not contribute to subscription totals
- old persisted OpenCode Zen settings are migrated
- stale OpenCode subscription keys are cleaned
- tests pass
- app builds and menu behavior is verified
- docs and design decisions match the new behavior