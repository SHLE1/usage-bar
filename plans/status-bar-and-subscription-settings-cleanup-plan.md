# Status Bar and Subscription Settings Cleanup Plan

## Status

Plan only. No code changes in this document.

## Branch Context

Current branch:
- `feat/macos-native-adaptation`

## Why This Plan Exists

After the recent system-style Settings polish, three specific UI problems remain in the Settings experience:

1. the bottom explanatory block on the **Status Bar** page feels noisy and cluttered
2. the **Configured subscription cost** label on the **Subscriptions** page looks too de-emphasized because it is rendered in a gray secondary style
3. the **Subscriptions** page does not show provider icons for each provider row, which weakens scanability and visual consistency with other parts of Settings

This plan isolates those issues and proposes a focused cleanup pass.

## Read First

Before implementation, re-read:
- `AGENTS.md`
- `AGENTS-design-decisions.md`
- `plans/settings-system-settings-polish-plan.md`
- `plans/settings-copy-density-hierarchy-polish-plan.md`
- this file

## Constraints

### Must preserve
- existing settings behavior
- existing preference storage logic
- existing provider ordering and subscription logic
- existing page structure unless a very small structural adjustment is enough to solve the copy problem
- English-only user-facing app text
- system-first Settings direction

### Must not do
- do not redesign the Settings navigation
- do not rewrite subscription business logic
- do not introduce decorative custom UI just to solve hierarchy issues
- do not use custom arbitrary text colors for emphasis
- do not add more explanatory copy to solve a clutter problem

---

# Current Assessment

## Issue 1 — Status Bar page bottom text is visually messy

### Current location
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- currently rendered via `SettingsSecondaryCard`

### Current structure
The bottom block currently contains three separate text layers:
- title: `How this appears`
- subtitle: `The top status bar only shows quota-based providers. Pay-as-you-go providers still appear in the dropdown cost section.`
- body text: `Use Advanced Providers for provider-specific overrides such as the Codex account and limit window.`

### Problem analysis
This area feels cluttered for several reasons:
- it stacks too many explanatory tiers for a small note area
- the subtitle and body both act like helper copy, so hierarchy is weak
- the information overlaps with what is already implied by the page sections above
- the bottom-most helper ends the page with copy instead of with controls, which makes the page feel over-annotated

### Likely root cause
The current block tries to explain:
- what appears in the top status bar
- what appears in the dropdown
- where provider-specific overrides live

Those are valid facts, but they are packed into one three-layer note component.

---

## Issue 2 — “Configured subscription cost” looks too weak

### Current location
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`

### Current structure
The monthly total uses `SettingsSummaryRow`, and that shared component renders the title with:
- `.foregroundStyle(.secondary)`

### Problem analysis
For this specific row, the label is not merely decorative metadata. It is the label for the primary summary value in the section.

As a result, the current secondary styling makes the label feel:
- disabled
- less important than it should be
- visually detached from the total value

### Likely root cause
`SettingsSummaryRow` currently assumes every summary label should be visually secondary, but the **Monthly Total** row is a stronger summary than an ordinary supporting metric.

---

## Issue 3 — Subscription rows are missing provider icons

### Current location
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`

### Existing capability already available
Provider icon mapping already exists through:
- `ProviderIdentifier.menuIconAssetName`
- `ProviderIdentifier.menuIconSymbolName`

A SwiftUI implementation for provider icons already exists in:
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- local helper: `previewIcon(for:dimmed:)`

### Problem analysis
On the Subscriptions page, provider rows currently display only text plus the plan picker. That makes the list feel flatter and harder to scan, especially when:
- multiple providers are shown together
- some providers have account suffixes in their display names
- the Settings app already uses icons elsewhere for provider identity

### Likely root cause
The subscription rows never adopted the existing provider icon rendering pattern that is already used in Status Bar settings and the menu.

---

# Implementation Strategy

## Phase 1 — Clean up the Status Bar bottom helper block

### Goal
Reduce the bottom helper area to a single concise and readable explanation.

### Preferred direction
Replace the current three-layer helper block with a much lighter, less repetitive pattern.

### Recommended options

#### Option A — Keep a secondary card, but collapse the copy to one short message
Best default option.

Possible direction:
- remove either the title or the subtitle
- reduce the block to one compact helper sentence
- keep the provider-specific override hint, but compress it

Example structural direction only:
- one short note explaining that the top status bar is quota-only
- one short clause mentioning Advanced Providers for overrides
- avoid two separate explanatory paragraphs

#### Option B — Move the override hint closer to the relevant section
Alternative if the page still feels bottom-heavy after Option A.

Possible direction:
- keep the page focused on preview + provider lists
- move the Advanced Providers note near the subscription or preview section if that makes the page read more naturally

### Recommended decision
Start with **Option A** because it is smaller, safer, and aligns with the existing page structure.

### Acceptance criteria
- the bottom of the page no longer ends with layered explanatory text
- the note reads as one concise helper instead of a mini documentation block
- no new explanatory text is introduced unless something else is removed

---

## Phase 2 — Make the monthly total label read as a real label

### Goal
Make `Configured subscription cost` visually readable and appropriately important without breaking the shared scaffold.

### Preferred direction
Do not solve this with a custom color override. Use a system text style adjustment.

### Recommended implementation approaches

#### Approach A — Add an explicit title emphasis/style option to `SettingsSummaryRow`
Preferred approach.

Potential shape:
- add a parameter such as `titleProminence` or `emphasizeTitle`
- keep current secondary behavior as the default for existing callers
- opt in to primary label styling for the subscription total row only

#### Approach B — Create a more specific total row variant
Use only if `SettingsSummaryRow` is no longer a good semantic fit.

Potential shape:
- a dedicated summary-total row component for high-priority values
- stronger title treatment, same native layout principles

### Recommended decision
Use **Approach A** first because it is the smallest and least disruptive change.

### Acceptance criteria
- `Configured subscription cost` no longer looks disabled or washed out
- the total row still feels native and restrained
- no custom arbitrary text color is introduced

---

## Phase 3 — Add provider icons to subscription rows

### Goal
Improve scanability and make the Subscriptions page visually consistent with other provider lists.

### Preferred direction
Reuse the existing provider icon mapping instead of inventing a new icon system.

### Recommended implementation steps
1. extract a small shared Settings-level provider icon view or helper
2. back it with the existing provider asset/symbol resolution:
   - `menuIconAssetName`
   - fallback to `menuIconSymbolName`
3. use that icon in each subscription row before the provider name
4. keep icon sizing aligned with the current Settings usage pattern
5. maintain graceful fallback behavior for rows where `provider` is `nil`

### Fallback behavior
- if `provider` is available, always show its icon
- if `provider` is unknown on an orphaned row, either:
  - show no icon, or
  - use a neutral fallback symbol such as `questionmark.circle`

The final choice should prefer visual consistency without implying false provider identity.

### Layout considerations
- icon should sit to the left of the provider name
- account suffixes should remain part of the text label
- row alignment with the plan picker must remain stable
- icon size should match the Settings scale already used in `StatusBarSettingsView`

### Acceptance criteria
- every normal provider row on the Subscriptions page shows the corresponding provider icon
- rows remain visually aligned and not crowded
- icon rendering uses the existing provider asset/symbol mapping

---

# Likely Files To Touch

## Required
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`

## Optional
- a new shared helper file if extracting a reusable Settings provider icon view is cleaner than duplicating the logic from `StatusBarSettingsView`

---

# Validation Plan

## Visual validation
Confirm that:
- the Status Bar page bottom note is concise and no longer visually noisy
- the Monthly Total summary reads clearly at a glance
- provider rows on the Subscriptions page are easier to scan because of icons

## Behavior validation
Confirm that:
- subscription plan selection still works exactly as before
- custom monthly cost entry still works exactly as before
- row ordering and detected account labeling remain unchanged

## Build/runtime validation for implementation phase
When code changes are made later:
- add debug logs as required by `AGENTS.md`
- clear cache, build, kill the running app, and relaunch
- confirm behavior through logs

---

# Non-Goals

This plan does not include:
- subscription logic redesign
- new provider management features
- reworking the Status Bar preview section
- changing menu structure or provider grouping
- redesigning Settings typography globally beyond what is necessary for these three issues

---

# Recommended Execution Order

1. clean up the Status Bar bottom helper block
2. fix the Monthly Total label prominence
3. add provider icons to subscription rows

That order gives the fastest visible cleanup first, then fixes the summary emphasis issue, then finishes with the row-level polish.
