# macOS Native Adaptation Plan

## Status

Planning complete. This file is intended as a direct handoff document for the next agent.

## Branch

Work on:
- `feat/macos-native-adaptation`

## Mission

Improve UsageBar's macOS-native feel **without changing the existing product information architecture**.

This is **not** a rewrite of the app architecture, provider system, or menu structure.
This is a focused native-polish pass over:
- Settings UI
- Menu item presentation
- Status bar rendering
- Standard macOS app entry points and behaviors
- Accessibility and keyboard behavior

## High-Level Conclusion From Initial Audit

UsageBar is already fundamentally a native macOS app:
- `LSUIElement` menu bar app
- AppKit `NSStatusItem` + `NSMenu`
- SwiftUI used for settings UI
- Sparkle auto-updates
- `SMAppService` launch-at-login integration
- explicit `NSWindow` management for Settings

So the correct direction is:
- **preserve the current architecture**
- **preserve current menu structure and provider behavior**
- **polish presentation and macOS conventions**

Do **not** re-architect the app into a different menu bar framework.
Do **not** redesign provider logic.
Do **not** change core information hierarchy.

## Files Already Audited

### Core app / menu bar
- `CopilotMonitor/CopilotMonitor/App/ModernApp.swift`
- `CopilotMonitor/CopilotMonitor/App/AppDelegate.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+Menu.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+MenuSections.swift`

### Settings UI
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/CodexSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/AppPreferences.swift`

### Status bar views
- `CopilotMonitor/CopilotMonitor/Views/StatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderStatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderBarView.swift`

### Menu helpers
- `CopilotMonitor/CopilotMonitor/Helpers/ProviderMenuBuilder.swift`
- `CopilotMonitor/CopilotMonitor/Helpers/MenuDesignToken.swift`

### App configuration
- `CopilotMonitor/CopilotMonitor/Info.plist`
- `AGENTS-design-decisions.md`
- `AGENTS.md`

## Non-Negotiable Project Rules

The next agent must follow all repository instructions, especially:

### 1. Read these first
- `AGENTS.md`
- `AGENTS-design-decisions.md`

### 2. Before any development work
Run:
```bash
make setup
```

### 3. Language policy
- Reply to the user in Chinese unless asked otherwise
- All code comments, logs, commit messages, PR text, and repository artifacts must be in English
- All user-facing app text must remain in English

### 4. After each actual code change
The next agent must:
- add debug logging where needed while validating behavior
- check whether Chinese i18n is missing or incomplete, and update it if needed
- update both `README.md` and `README.zh-CN.md` for any user-facing feature or UI change before handoff
- clear cache, compile, kill the old app, run the new app, and confirm behavior through logs

### 5. Exception
If a step changes only documentation files, README files, or screenshot/image assets, a build/run cycle is not required.

## Important Design Constraints

The following must remain unchanged unless the user explicitly approves otherwise:

### Menu structure and naming
From `AGENTS-design-decisions.md`:
- do **not** change the group title formats:
  - `Pay-as-you-go: $XX.XX`
  - `Quota Status: $XXX/m` or `Quota Status`
- do **not** change the core information architecture of the menu
- do **not** change status bar percent priority rules
- do **not** change provider icon rules
- do **not** remove subscription settings from quota-based providers
- do **not** add subscription settings to pay-as-you-go providers

### Styling rules
- do not use emoji as menu icons
- do not use random spaces for alignment
- do not use text colors for emphasis except where already explicitly allowed
- use `MenuDesignToken` for menu layouts
- keep all UI text in English

## Current Native-Adaptation Findings

## 1. Settings UI is the highest-priority gap

### Why
The app is already architecturally native, but the Settings experience still feels more custom-product UI than standard macOS preferences UI.

### Current traits that feel less native
- custom card-heavy scaffolding in `SettingsScaffold.swift`
- custom compact menu chip controls instead of more standard macOS picker presentation
- custom preview blocks and custom row containers in `StatusBarSettingsView.swift`
- some preference rows visually resemble a bespoke panel more than a standard macOS settings pane

### Direction
Keep the current `NavigationSplitView` sidebar layout, but make the content panes feel more like native macOS settings.

## 2. The menu uses many custom `NSView` menu items

### Why this matters
`ProviderMenuBuilder.swift` uses a large number of custom `item.view = ...` menu rows.

This is functional, but overuse of custom menu views can reduce:
- native visual consistency
- accessibility quality
- keyboard/hover behavior consistency
- maintainability

### Direction
Do **not** remove custom menu views blindly.
Instead:
- keep them only where they are necessary
- convert simple informational rows back to standard `NSMenuItem` or attributed-title items where practical

## 3. Status bar rendering still has a hand-drawn feel

### Why this matters
Status bar UI is one of the most sensitive parts of macOS polish.
Current status bar views use:
- manual padding values
- manual text drawing
- manual appearance detection
- manual tinting in multiple places

This works, but can be improved for:
- consistency
- semantic rendering
- dark/light mode stability
- accessibility

### Direction
Polish the existing views rather than replacing them.

## 4. Standard macOS About behavior is missing

Current menu behavior uses the version item as a GitHub link.
That is useful, but not fully native.

### Direction
Add a standard `About UsageBar` entry using standard macOS behavior, while keeping GitHub/repository access as a separate item.

## 5. Settings window behavior can be more native

Current `AppDelegate.openSettingsWindow()` is already fairly good, but still can be improved with:
- frame autosave
- restoring last selected settings tab
- better persistence of window state

## 6. Accessibility should be improved as part of this work

This is part of native quality, not an optional add-on.
Focus on:
- custom menu item views
- custom status bar views
- SwiftUI rows that use `labelsHidden()`

## Scope

## In scope
1. Native polish for Settings UI
2. Native polish for menu row presentation
3. Native polish for status bar rendering and metrics organization
4. Add standard macOS app entry points where missing
5. Accessibility improvements for custom views and controls
6. Minor window-behavior improvements for Settings
7. Documentation updates if UI changes are user-facing

## Out of scope
1. Rewriting provider fetch logic
2. Rewriting the actor/provider architecture
3. Replacing `NSStatusItem` / `NSMenu` architecture
4. Changing core menu information hierarchy
5. Renaming provider categories or group titles
6. Changing provider business logic or API logic
7. Large visual redesign unrelated to native macOS behavior
8. Experimental glass/material redesign as the first step

## Recommended Execution Strategy

Implement in phases. Do **not** try to finish everything in one risky change.

---

# Phase 0 - Reconfirm constraints and establish UI baseline

## Goal
Make sure no design-decision rules are accidentally violated.

## Required actions
1. Re-read:
   - `AGENTS.md`
   - `AGENTS-design-decisions.md`
   - this plan file
2. Re-scan the following before editing:
   - `SettingsView.swift`
   - `SettingsScaffold.swift`
   - `GeneralSettingsView.swift`
   - `StatusBarSettingsView.swift`
   - `SubscriptionSettingsView.swift`
   - `CodexSettingsView.swift`
   - `AppDelegate.swift`
3. Record a quick implementation note in your own working notes about:
   - what must not change
   - what is safe to polish

## Done criteria
- The next agent fully understands this is a native-polish task, not a redesign task.

---

# Phase 1 - Settings Native Pass

## Priority
Highest

## Goal
Make the Settings experience feel closer to a standard macOS preferences window while preserving all existing behavior.

## Primary files
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/CodexSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/AppDelegate.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/AppPreferences.swift`

## Tasks

### 1. Reduce the custom card-heavy look
Review `SettingsScaffold.swift` and simplify or soften the visual treatment so it feels closer to native macOS settings panes.

Possible directions:
- reduce heavy card borders/containers where unnecessary
- prefer cleaner section grouping and native spacing
- keep layout readable, but avoid over-designed panel styling

Do not turn the page into a web-style dashboard.

### 2. Replace custom menu-chip controls where appropriate
Current settings use:
- `Menu { ... } label: { CompactSettingsMenuLabel(...) }`

Where practical, move toward more standard macOS settings controls such as:
- `Picker(...).pickerStyle(.menu)`
- or equivalent native-feeling selector patterns

Keep behavior unchanged.
Do not degrade compactness if the replacement becomes awkward.
If a direct replacement is worse, keep the current control and improve styling conservatively.

### 3. Normalize settings rows
Review all settings rows for:
- label alignment
- description hierarchy
- accessory alignment
- spacing consistency
- keyboard focus behavior

Preserve existing functionality.

### 4. Improve Settings window behavior
In `AppDelegate.swift` and related preferences storage:
- add frame autosave for the Settings window
- preserve/restore last selected tab if practical
- ensure window reuse remains correct
- keep standard title and toolbar behavior

### 5. Preserve current settings information architecture
Keep the current tabs:
- General
- Status Bar
- Advanced Providers
- Subscriptions

Do not rename them unless required by the user.

## Acceptance criteria
- Settings feels more native and less custom-dashboard-like
- Existing settings behavior is unchanged
- Existing tab structure is preserved
- Window opens and restores cleanly
- No user-facing strings violate repository language rules

---

# Phase 2 - Menu Native Pass

## Priority
High

## Goal
Keep the current menu structure, but make menu rows more standard-macOS where possible.

## Primary files
- `CopilotMonitor/CopilotMonitor/Helpers/ProviderMenuBuilder.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+Menu.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+MenuSections.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
- `CopilotMonitor/CopilotMonitor/Helpers/MenuDesignToken.swift`

## Tasks

### 1. Audit all custom menu item views
Classify rows into two buckets:

#### Keep as custom view
Use a custom view only when needed for:
- multiline content
- complex left/right layout
- progress bars
- rows with special formatting/layout requirements

#### Convert to standard menu items where possible
Prefer standard `NSMenuItem` / attributed titles for:
- simple single-line informational rows
- simple headers when a custom header is not necessary
- ordinary text rows with icon + title only

### 2. Preserve alignment and menu design token usage
Any remaining custom menu rows must continue using `MenuDesignToken`.
Do not introduce hardcoded spacing outside the token system.

### 3. Improve native behavior without changing structure
Preserve all existing sections and row semantics.
This phase is about presentation, not information architecture.

### 4. Add standard About behavior
Current menu has a version item that opens GitHub.
Refactor this into a more native structure such as:
- `About UsageBar`
- separate GitHub/Project Website item if desired

Use standard macOS About-panel behavior where appropriate.
Do not remove useful repository access.

## Acceptance criteria
- Menu still contains the same core information and sections
- Simple rows use more standard menu rendering where practical
- Complex rows remain readable and aligned
- About behavior feels like a real macOS app

---

# Phase 3 - Status Bar Native Polish

## Priority
High, but after Settings and menu improvements

## Goal
Improve consistency and native feel of status bar rendering without changing the user-facing status model.

## Primary files
- `CopilotMonitor/CopilotMonitor/Views/StatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderStatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderBarView.swift`
- `CopilotMonitor/CopilotMonitor/Helpers/MenuDesignToken.swift`

## Tasks

### 1. Centralize status bar metrics
Review hardcoded status bar metrics such as:
- icon size
- provider icon size
- text spacing
- left/right padding
- status bar height assumptions

Move shared values into a clearer tokenized structure where appropriate.

Do not break any deliberate special sizing rule such as Gemini icon sizing.

### 2. Improve color/rendering behavior
Review current manual light/dark rendering logic.
Make the rendering more robust and consistent while preserving visibility.

Be careful not to violate the repo's text-emphasis constraints.
Status bar text is a special rendering context, but still keep semantic behavior where possible.

### 3. Review custom drawing quality
For custom-drawn views:
- ensure baseline alignment looks correct
- ensure spacing is visually stable
- ensure glyph/icon scale is not cramped
- ensure status item width updates remain correct

### 4. Add accessibility metadata
For custom status bar views, provide meaningful accessibility labels/values if missing.

## Acceptance criteria
- Status bar looks consistent in light and dark mode
- Width calculation remains stable
- Custom rendering feels less ad-hoc
- Accessibility is improved

---

# Phase 4 - Accessibility and Keyboard Pass

## Goal
Improve actual macOS-native usability, not just visuals.

## Primary targets
- custom menu item views
- custom status bar views
- settings controls using hidden labels
- keyboard shortcuts and focus order

## Tasks
1. Review custom `NSView` menu items for accessibility
2. Review custom status bar views for accessibility labels/values
3. Check whether SwiftUI `Toggle("", ...)` patterns still expose proper labels to accessibility
4. Verify menu keyboard shortcuts remain correct
5. Verify Settings can be navigated sensibly with keyboard

## Acceptance criteria
- Accessibility support is meaningfully better than before
- No regression in shortcuts or interaction flow

---

# Phase 5 - Optional Newer-macOS Visual Enhancements

## Goal
Only after Phases 1 through 4 are stable.

## Important rule
Do not start here first.
Do not make the app more decorative at the cost of native clarity.

## Possible directions
- subtle material/vibrancy refinements
- more current macOS spacing and container treatment
- visual polish that still feels system-native

## Acceptance criteria
- The UI still feels like a macOS app, not a custom concept UI

---

# Recommended Order of Implementation

1. Phase 1 - Settings Native Pass
2. Phase 2 - Menu Native Pass
3. Phase 3 - Status Bar Native Polish
4. Phase 4 - Accessibility and Keyboard Pass
5. Phase 5 - Optional visual polish only if time remains

## Why this order
- Settings gives the highest immediate user-facing native-quality improvement
- Menu pass improves standard app feel
- Status bar pass is more delicate and should happen after structural UI cleanup
- Accessibility should be baked in before handoff

## Strong Recommendation for the Next Agent

If time is limited, complete:
1. Phase 1
2. the `About UsageBar` portion of Phase 2
3. the most obvious status bar token/accessibility cleanup from Phase 3

That will already produce a meaningful native-quality improvement.

# Validation Checklist

## Before handoff
The next agent must validate all of the following.

### General
- `make setup` was run before development
- design-decision constraints were not violated
- all new comments/logs/repo text are in English
- user-facing app text remains English only

### Settings
- Settings window opens correctly
- Settings window reopens without duplication
- tab selection behaves correctly
- any window autosave logic works
- all controls still modify the same preferences as before

### Menu
- menu structure still matches existing product rules
- `Pay-as-you-go` and `Quota Status` header formats are unchanged
- provider rows still appear in correct groups
- complex submenu content still renders correctly
- About/GitHub entries behave correctly

### Status bar
- icon/text rendering works in light mode
- icon/text rendering works in dark mode
- width resizing remains stable
- critical visual states still appear correctly

### Accessibility
- custom menu rows expose sensible accessibility information if applicable
- custom status bar views expose sensible accessibility information if applicable
- hidden-label controls still have accessible labels

### Documentation and localization
If user-facing behavior changed:
- update `README.md`
- update `README.zh-CN.md`
- check whether related localization strings need updates

### Build/run validation
Unless the final change is documentation-only, the next agent must:
1. clear cache
2. compile the app
3. kill the existing process
4. run the new app
5. confirm behavior through logs

## Suggested Implementation Notes for the Next Agent

### Be conservative
The goal is native polish, not novelty.
If a change looks more custom than before, it is probably the wrong direction.

### Prefer standard system controls when they are a good fit
But do not force them where they make the UI worse.

### Do not over-rotate on visuals
A stable and restrained native UI is better than a flashy one.

### Keep menu architecture intact
Do not rename sections or move product concepts around unless the user explicitly asks for that.

### Treat accessibility as part of native quality
Do not leave it for “later if there is time”.

## Suggested Final Handoff Format

When the next agent finishes implementation, their handoff should include:
1. summary of phases completed
2. list of changed files
3. any constraints intentionally preserved
4. validation performed
5. whether README files were updated
6. any deferred items left for later

## Final One-Sentence Instruction For the Next Agent

Implement a **conservative macOS-native polish pass** for UsageBar by improving Settings, menu presentation, status bar rendering, and standard macOS app behaviors **without changing the existing menu information architecture, provider logic, or design-decision constraints**.
