# Status Bar Provider Drag Order Plan

## Branch
- `feat/statusbar-provider-drag-order`

## Goal
Convert the **Status Bar** settings page into **single-column draggable lists** and guarantee that the same ordering is used by:

1. the settings page provider lists
2. the menu preview
3. the real dropdown menu

## Locked Product Decisions

### 1. No cross-group dragging
Keep the two existing groups and only allow reordering within each group:

- `Pay-as-you-go Providers`
- `Subscription Providers`

### 2. Single-column draggable lists
Replace the current two-column checkbox grids with single-column reorderable lists.

### 3. Checked state defines vertical grouping
Within each group:

- checked items stay at the top
- unchecked items stay at the bottom

### 4. Unchecked items automatically sink to the bottom
When a provider is unchecked:

- it moves to the bottom area of its group
- it disappears from the preview and the real menu

### 5. Re-check behavior
When a provider is checked again:

- it returns to the enabled area of its group
- it is inserted at the end of the enabled area by default
- the user can then drag it to any position within the enabled area

### 6. Dragging changes order only
- the checkbox controls visibility
- dragging controls display order

## Important Scope Clarification
To truly make the rule **"the way you order it is the way preview and menu show it"** correct, this work must cover more than the settings UI.

Some real menu sections still use special-case ordering branches today, especially around:

- `Copilot Add-on`
- `GitHub Copilot`
- `Gemini CLI`

This plan explicitly includes aligning those branches to the same ordering source.

## Implementation Plan

### Phase 1 — Unify the order model
**Goal:** Make provider order a real single source of truth.

#### Files
- `CopilotMonitor/CopilotMonitor/App/Settings/AppPreferences.swift`

#### Work
Reuse and adjust the existing helpers:

- `statusBarSettingsOrder(...)`
- `payAsYouGoSettingsItemOrder(...)`
- `rememberedStatusBarOrder(...)`
- `rememberedItemOrder(...)`

Ensure the persisted order always satisfies:

- enabled items first
- disabled items last

Behavior to preserve/implement:

- checking an item moves it into the enabled area tail
- unchecking an item sinks it to the bottom of the whole group
- persisted order remains stable and reusable by all UI layers

### Phase 2 — Convert settings UI to single-column draggable lists
**Goal:** Replace the current two-column grid with reorderable single-column lists.

#### Files
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`

#### Work
Replace:

- `payAsYouGoGrid`
- `providerGrid`

With reorderable single-column lists.

Each row should contain:

- drag affordance / reorder handle
- provider name
- checkbox

Behavior:

- drag updates order immediately
- order persists immediately
- no cross-group dragging

### Phase 3 — Make the menu preview reuse the same order
**Goal:** Remove any preview-specific ordering logic.

#### Files
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`

#### Work
Ensure preview rows are driven directly by the persisted order for each section.

Rules:

- only checked items are shown in preview
- unchecked items remain stored in order but hidden from preview

### Phase 4 — Make the real menu reuse the same order
**Goal:** Remove hardcoded menu ordering and special ordering drift.

#### Files
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+MenuSections.swift`

#### Work
##### Pay-as-you-go section
Drive the real menu from a unified ordered source that includes:

- `OpenRouter`
- `OpenCode`
- `Copilot Add-on`

`Copilot Add-on` must no longer be effectively fixed at the end if the settings order says otherwise.

##### Subscription section
Drive the real menu from the unified stored order, including:

- `GitHub Copilot`
- `Claude`
- `Kimi for Coding`
- `MiniMax Coding Plan`
- `ChatGPT`
- `Z.AI Coding Plan`
- `Nano-GPT`
- `Antigravity`
- `Chutes AI`
- `Synthetic`
- `Gemini CLI`

This means:

- `GitHub Copilot` must no longer be effectively fixed at the top
- `Gemini CLI` must no longer be effectively fixed at the bottom

Provider-specific rendering and submenu logic should remain as-is; only the section ordering source should be unified.

### Phase 5 — Documentation and localization
**Goal:** Keep docs aligned with the feature.

#### Files
- `README.md`
- `README.zh-CN.md`
- and, if needed:
  - `CopilotMonitor/CopilotMonitor/en.lproj/Localizable.strings`
  - `CopilotMonitor/CopilotMonitor/zh-Hans.lproj/Localizable.strings`

#### Work
Document that:

- Status Bar settings support drag reordering
- preview and real menu order follow the settings list

## Debug Logging Plan
Keep the necessary English debug logs for:

- persisted order after drag
- normalized order after toggle
- final order used to build the real menu

This is required both for troubleshooting and to satisfy the repository rule about adding real debug logging during feature work.

## Acceptance Criteria

### Settings UI
- [ ] Pay-as-you-go is shown as a single-column draggable list
- [ ] Subscription is shown as a single-column draggable list
- [ ] No cross-group dragging exists

### Ordering behavior
- [ ] Checked items always appear above unchecked items
- [ ] Unchecked items always sink to the bottom
- [ ] Re-checking inserts the item at the end of the enabled area
- [ ] Dragged order persists across app relaunch

### Preview consistency
- [ ] Settings list order equals menu preview order

### Real menu consistency
- [ ] Settings list order equals real dropdown menu order
- [ ] `Copilot Add-on` follows the settings order
- [ ] `GitHub Copilot` follows the settings order
- [ ] `Gemini CLI` follows the settings order

### Validation
- [ ] Project builds successfully
- [ ] App is relaunched after build
- [ ] Logs confirm the final menu order
- [ ] `README.md` and `README.zh-CN.md` are updated

## Explicitly Out of Scope
This iteration does **not** include:

- cross-group dragging
- preserving the current two-column layout
- changing provider category membership
- advanced animation polish
- special pinning/locking rules for specific providers

## Suggested Implementation Order
1. unify the order model
2. convert the settings UI
3. unify the real menu ordering
4. update docs and validate with build/run/logs
