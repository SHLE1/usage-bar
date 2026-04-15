# macOS 26 System-First Adaptation Plan

## Status

Plan only. This file defines the implementation strategy.

## Goal

Align UsageBar with this principle:

> Except where native system components cannot express the required behavior, the app should prefer system-owned UI and system-owned rendering so that future macOS visual and interaction changes are adopted automatically whenever possible.

This is specifically a **macOS 26 system-first adaptation plan**.
Because macOS 26 is already available, implementation can begin immediately.

## Key Product Rule

The objective is **not** to manually force Liquid Glass everywhere.
The objective is to:

1. maximize use of native system containers, bars, controls, and materials
2. reduce unnecessary custom visual shells
3. keep custom rendering only where the product truly requires behavior that native components cannot provide
4. ensure future macOS UI refreshes are inherited automatically as much as possible

## Design Philosophy

### Preferred rule
If a native SwiftUI/AppKit component can express the UI well enough, use it.

### Fallback rule
If native components cannot express the feature or would meaningfully degrade the product, keep a custom implementation — but isolate it and make the customization as thin as possible.

### Anti-pattern
Do not recreate system-looking components with custom drawing if a real system component exists.

---

# Core Strategy

## What automatically adapts best on macOS 26
These benefit most from future automatic system styling:
- standard windows
- split views
- sidebars
- lists
- toolbars/titlebars
- standard pickers
- standard popup buttons
- standard toggles
- standard text fields
- standard menus and menu items where not overridden with custom views
- system-managed backgrounds/materials

## What does not automatically adapt well
These require ongoing manual maintenance:
- custom `RoundedRectangle + fill + stroke` shells
- custom menu item views
- custom `NSView` rendering in menus
- custom status bar drawing
- custom preview panels that imitate system containers
- hardcoded visual skins that replace system surfaces

---

# Important Apple Guidance Applied To This Project

Based on Apple’s macOS 26 / Liquid Glass guidance:
- standard SwiftUI/AppKit components pick up the latest visual design automatically
- Liquid Glass is primarily a system layer for controls, navigation, and surfaces close to system UI
- custom views should adopt new materials only when needed, and should not replace the content layer with decorative glass indiscriminately
- existing apps should begin by removing unnecessary custom chrome before adding new custom glass effects

This plan follows that guidance directly.

---

# Project-Specific Interpretation

For UsageBar, the system-first target means:

## Desired outcome
- Settings should rely more on native structure and lighter system-owned grouping
- Menus should use standard `NSMenuItem` whenever a custom view is not truly necessary
- Status bar rendering should stay custom only where the product genuinely needs custom information density
- Shared visual shells should become thinner and easier to swap for future system styles
- New macOS 26 visual changes should arrive “for free” in more places

## Allowed custom zones
Custom UI is still acceptable where the product genuinely needs:
- compact multi-metric status bar composition
- complex provider submenu rows that standard menu items cannot express cleanly
- adaptive-width controls where system SwiftUI wrappers do not behave correctly
- provider-specific previews or progress layouts that lack a native equivalent

But each of those should be kept narrow and isolated.

---

# Non-Negotiable Constraints

Read and obey:
- `AGENTS.md`
- `AGENTS-design-decisions.md`

Especially preserve:
- menu information architecture
- fixed group title formats
- provider grouping rules
- subscription behavior rules
- existing product terminology
- UI language policy (app text in English)
- code comments/logs/repo artifacts in English

Do not use this system-first migration as a reason to change product semantics.

---

# High-Level Migration Principle

## The main question for every UI surface
Ask:

> Can this surface be expressed by a standard system component or a thin wrapper around a system component?

If yes:
- convert to native system ownership

If no:
- keep it custom, but isolate the custom code and remove cosmetic over-design

---

# Phase 1 - Inventory and Classification

## Goal
Classify every major UI surface into one of three buckets:

### Bucket A — Already system-first
These can largely stay as-is.

### Bucket B — Can be converted to system-owned UI now
These should be prioritized.

### Bucket C — Must remain custom for product reasons
These should be isolated and cleaned up, not removed.

## Files to classify first

### Settings / windows
- `CopilotMonitor/CopilotMonitor/App/AppDelegate.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/CodexSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`

### Menu system
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+Menu.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+MenuSections.swift`
- `CopilotMonitor/CopilotMonitor/Helpers/ProviderMenuBuilder.swift`

### Status bar views
- `CopilotMonitor/CopilotMonitor/Views/StatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderStatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderBarView.swift`
- `CopilotMonitor/CopilotMonitor/Helpers/MenuDesignToken.swift`

## Deliverable for Phase 1
Create an internal implementation checklist that marks each surface as:
- Keep native
- Convert to native
- Keep custom but isolate

---

# Phase 2 - Settings: Maximize System Ownership

## Goal
Make Settings the first fully system-first area of the app.

## Why first
Settings already has the highest automatic-adaptation potential because it already uses:
- `NSWindow`
- `NavigationSplitView`
- sidebar `List`
- standard SwiftUI controls

The remaining work is mostly about removing custom shells that block automatic future adaptation.

## Primary files
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/CodexSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`

## Tasks

### 2.1 Reduce or remove custom section shells
Current custom wrappers like `SettingsSectionCard` and `SettingsSecondaryCard` should be evaluated aggressively.

Preferred outcome:
- use lighter system-aligned grouping
- rely less on custom rounded filled panels
- preserve readability, but let the system own more of the surface feel

If complete removal is not practical:
- make the wrappers visually thin
- centralize them so future macOS 26+ branching is easy

### 2.2 Prefer standard controls everywhere possible
Rules:
- use `Picker(.menu)` where possible
- use standard `Toggle`
- use standard `TextField`
- use `NSPopUpButton` wrapper only where SwiftUI picker sizing/behavior is insufficient
- avoid custom controls that merely imitate system controls

### 2.3 Isolate custom fallback controls
For example, `AdaptiveWidthPopupPicker` is allowed because it wraps a native control for behavior SwiftUI does not provide well.

That is acceptable.
The rule is:
- thin native wrapper = acceptable
- custom imitation control = avoid

### 2.4 Prepare Settings visual shells for macOS 26 branching
Introduce a centralized visual style policy for shared Settings surfaces.

Possible direction:
- one shared settings surface style abstraction
- macOS 26 path vs fallback path

The purpose is not to force Liquid Glass immediately.
The purpose is to make future adoption of native system surfaces straightforward.

## Done criteria for Phase 2
- Settings uses the maximum reasonable amount of system-owned UI
- remaining custom surfaces are thin and centralized
- no page depends on heavy custom shell styling to feel complete

---

# Phase 3 - Menus: Eliminate Unnecessary Custom Views

## Goal
Increase the proportion of menu UI that is standard `NSMenuItem`-based, because standard menus inherit system updates better than custom embedded views.

## Primary files
- `CopilotMonitor/CopilotMonitor/Helpers/ProviderMenuBuilder.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+Menu.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController+MenuSections.swift`

## Tasks

### 3.1 Audit all custom menu rows
For every custom menu row, classify it:

#### Keep custom only if required for:
- multiline layout
- special progress layout
- complex left/right content that standard menu items cannot represent cleanly
- highly compact quota visualization that would degrade badly with standard menu items

#### Convert to standard menu items if possible for:
- simple informational rows
- basic headers
- simple icon + title rows
- single-line text rows without complex alignment

### 3.2 Reduce dependence on `item.view = ...`
This is one of the highest-value long-term system-first tasks in the codebase.

### 3.3 Keep menu architecture unchanged
Do not change the menu information architecture.
This is only a rendering-ownership migration.

## Done criteria for Phase 3
- more of the menu is owned by system menu rendering
- only truly necessary complex rows remain custom
- future menu visual updates from macOS can flow through more naturally

---

# Phase 4 - Status Bar: Keep Custom Only Where Required

## Goal
Minimize custom status bar rendering where possible, but preserve compact product behavior.

## Primary files
- `CopilotMonitor/CopilotMonitor/Views/StatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderStatusBarIconView.swift`
- `CopilotMonitor/CopilotMonitor/Views/MultiProviderBarView.swift`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`

## Reality check
The status bar is the least likely area to ever become fully automatic because UsageBar has highly custom density and formatting needs.

Therefore the real goal is not “make it fully automatic.”
The goal is:
- keep custom rendering only where required
- use system image/text behavior where possible
- avoid cosmetic over-customization that fights future platform changes

## Tasks

### 4.1 Audit each custom status bar view
Ask:
- is this custom because of required product density?
- or because it was easier than using a system-owned approach?

### 4.2 Reduce hardcoded visual assumptions
Where custom status rendering remains necessary:
- centralize metrics
- centralize semantic styling
- reduce fragile hardcoded visual tuning
- prefer template/system image behavior where possible

### 4.3 Avoid fake system surfaces
Do not add custom background shells to the status bar just to imitate macOS 26.
If the system does not own the surface, keep the custom rendering clean and minimal.

## Done criteria for Phase 4
- custom status bar rendering is justified, isolated, and thin
- no unnecessary imitation of system glass is introduced

---

# Phase 5 - Introduce Native macOS 26 Surface APIs Selectively

## Goal
Now that system ownership has been maximized, selectively adopt macOS 26-native surface/material APIs where they add real value.

## Important rule
Only do this **after** removing unnecessary custom shells.
Otherwise the app will accumulate more styling debt.

## Likely targets
- Settings shared surface wrappers in `SettingsScaffold.swift`
- specific helper/preview sections that still need a custom container
- AppKit custom surfaces that now have a first-party macOS 26 equivalent

## Possible APIs / concepts to evaluate
Depending on availability and exact platform APIs in your toolchain:
- SwiftUI glass-related modifiers for custom views
- AppKit glass/material views for custom containers
- updated macOS 26 system container/material APIs
- native toolbar/sidebar/split-view styling improvements

## Selection rule
Adopt native macOS 26 APIs only where they represent a real system-owned surface.
Do not apply glass to the content layer indiscriminately.

## Done criteria for Phase 5
- custom containers that still exist use native macOS 26 surface APIs where appropriate
- the app feels current on macOS 26 without becoming over-decorated

---

# Phase 6 - Fallback Architecture for Older macOS Versions

## Goal
Keep the app stable and visually coherent on older supported versions while using system-first macOS 26 surfaces where available.

## Requirement
The project currently targets macOS 13+, so every macOS 26-specific surface adoption must have a graceful fallback.

## Tasks
- wrap new APIs in availability checks
- keep fallback surfaces restrained and simple
- centralize version branching in shared surface layers where possible

## Done criteria for Phase 6
- macOS 26 gets the newest system-owned behavior
- older versions remain clean and stable
- version checks are centralized rather than scattered everywhere

---

# Immediate File-Level Priorities

## Highest-value immediate targets

### 1. `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`
Reason:
- shared shell layer
- biggest blocker to future automatic adaptation in Settings
- best leverage for system-first cleanup

### 2. `CopilotMonitor/CopilotMonitor/Helpers/ProviderMenuBuilder.swift`
Reason:
- largest concentration of custom menu rendering
- major blocker to future automatic menu adaptation

### 3. `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
Reason:
- custom menu view helpers live here
- direct control point for reducing custom menu view use

### 4. `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
Reason:
- still contains custom preview/container shells that should become thinner or more system-owned

### 5. `CopilotMonitor/CopilotMonitor/Views/StatusBarIconView.swift`
Reason:
- likely to remain custom, but should be audited and minimized

---

# Decision Rules for Implementation

## Rule 1
If a standard system component expresses the feature well enough, use it.

## Rule 2
If a thin wrapper around a system component solves the issue, use the wrapper.

## Rule 3
Only keep fully custom rendering when system components genuinely cannot express the product requirement.

## Rule 4
When custom rendering remains, remove unnecessary shell styling and isolate the code.

## Rule 5
Do not manually force a fake Liquid Glass look where the system should own the surface.

---

# Validation Checklist

## For every migrated surface
Confirm:
- the feature behavior is unchanged
- the UI is still native and stable
- the amount of custom shell code decreased or became thinner
- the use of true system-owned rendering increased

## For macOS 26-specific adoption
Confirm:
- the code path is availability-gated
- the fallback path remains visually coherent
- the new API is used where the surface is semantically appropriate

## Build and runtime validation
Before handoff:
- run `make setup`
- build the app
- relaunch the app
- verify behavior through logs
- update `README.md` and `README.zh-CN.md` if user-visible behavior changes

---

# Success Criteria

This plan succeeds when UsageBar reaches the following state:

1. Most Settings UI is system-owned or a thin wrapper around system-owned components
2. Menu rendering uses standard `NSMenuItem` wherever practical
3. Custom menu/status surfaces remain only where native system components cannot express the product requirement
4. macOS 26 visual/system changes are inherited automatically in significantly more places than today
5. The app feels current on macOS 26 without becoming a hand-crafted imitation of Liquid Glass

## Final Definition of Done

UsageBar should become a **system-first native macOS app**:
- future-facing where system UI can own the experience
- custom only where the product genuinely needs it
- easier to keep current as macOS evolves
