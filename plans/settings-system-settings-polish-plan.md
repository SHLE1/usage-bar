# Settings System-Style Polish Plan

## Status

Plan only. No code changes in this document.

## Branch Context

Current branch for related work:
- `feat/macos-native-adaptation`

## Goal

Polish the Settings experience so it feels closer to macOS System Settings while preserving the current native implementation, current feature set, and current information architecture.

This is **not** a rewrite and **not** a redesign of app behavior.

## Current Assessment

The Settings experience is already native in implementation:
- native `NSWindow`
- native `NSHostingController`
- native SwiftUI `NavigationSplitView`
- native sidebar `List` with `.sidebar`
- mostly native controls (`Picker`, `Toggle`, `TextField`, `NSPopUpButton` wrapper where needed)

However, the Settings content area still feels more like a polished third-party preferences page than Apple System Settings.

The main gap is not technical nativeness. The main gap is:
- visual rhythm
- section grouping style
- row alignment consistency
- card heaviness
- overall restraint of the content layout

## Primary Objective

Make the right-hand Settings content area feel:
- less like a dashboard/card page
- more like grouped system preferences
- more consistent across all tabs
- more restrained and Apple-like

## Read First

Before implementation, re-read:
- `AGENTS.md`
- `AGENTS-design-decisions.md`
- this file

## Important Constraints

### Must preserve
- existing tab structure
- existing settings behavior
- existing preference storage logic
- existing provider logic
- existing menu structure and design decisions
- existing English-only user-facing app text policy
- native AppKit + SwiftUI approach

### Must not do
- do not rewrite Settings into a different architecture
- do not replace `NavigationSplitView`
- do not convert the page into a custom web-like dashboard
- do not change provider/account/subscription business logic as part of this polish
- do not add flashy glass/material effects as a first step

## In Scope

1. Shared Settings scaffold polish
2. Shared row spacing/alignment normalization
3. Section/group styling refinement
4. Page header restraint
5. Per-page consistency pass for:
   - General
   - Status Bar
   - Advanced Providers
   - Subscriptions
6. Subtle cleanup of visually heavy areas such as previews and expanded custom input sections

## Out of Scope

1. Provider fetch logic
2. Subscription business logic
3. Settings data model redesign
4. Sidebar architecture changes
5. Large navigation changes
6. Menu bar architecture changes
7. New feature additions unrelated to Settings polish

---

# Highest-Value Strategy

## Guiding principle

If only part of this work can be completed, prioritize the shared scaffold first.

Why:
- one shared change affects every Settings tab
- it gives the highest visual improvement per unit of effort
- it reduces inconsistency without touching business logic

---

# Phase 1 - Shared Scaffold Polish

## Priority
Highest

## Main file
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`

## Goal

Adjust the shared building blocks so the Settings content area feels closer to grouped system preferences and less like a card-based product page.

## Components to review
- `SettingsPage`
- `SettingsSectionCard`
- `SettingsSecondaryCard`
- `SettingsRow`
- any shared spacing, padding, or typography rules used across settings pages

## Tasks

### 1. Reduce card heaviness in `SettingsSectionCard`

Current risk:
- sections feel too much like standalone content cards
- stronger border/fill/corner treatment than needed for a system-style settings pane

Target direction:
- lighter grouping
- more restrained separation
- softer visual boundaries
- more “section grouping” and less “dashboard card”

Potential adjustments:
- reduce fill prominence
- reduce border prominence
- reduce or soften corner radius emphasis
- reduce vertical padding where it feels too roomy

### 2. Refine `SettingsSecondaryCard`

Current risk:
- supplementary blocks can visually compete too much with primary settings sections

Target direction:
- clearly secondary
- visually lighter than primary sections
- closer to helper grouping than feature panel

### 3. Normalize `SettingsRow`

Target direction:
- title / description / accessory alignment should feel systematic across all pages
- row rhythm should resemble a settings form more than freeform content layout

Focus areas:
- vertical spacing
- title/description spacing
- right-side accessory alignment
- consistency of divider spacing between rows
- line wrapping behavior for descriptions

### 4. Restrain `SettingsPage` header

Current risk:
- large page title + subtitle can still feel slightly product-marketing-like

Target direction:
- more restrained page heading
- less visual weight above the actual settings controls
- faster transition into the form content

Potential adjustments:
- slightly reduce title size/weight
- reduce subtitle prominence
- tighten spacing between page header and first section

## Acceptance criteria for Phase 1
- all tabs inherit a lighter, more system-like baseline style
- section containers feel less card-like
- rows feel more uniform
- page headers feel more restrained

---

# Phase 2 - Page-Level Consistency Pass

## Priority
High

## Files
- `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/CodexSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`

## Goal

After the shared scaffold is improved, align each page so they all clearly belong to the same settings system.

## Page-specific focus

### General
Use this page as the reference baseline.

Check:
- right-side picker alignment
- toggle alignment
- section spacing
- divider rhythm
- visual density

### Subscriptions
This page already has functional native controls, including adaptive-width native plan pickers.

Focus only on visual consistency.

Check:
- whether each subscription row matches the rhythm of General settings rows
- whether the expanded custom amount area feels too editor-like
- whether the custom amount row is visually too strong compared with the rest of the page
- whether accessory controls align naturally with the rest of Settings

Desired direction:
- more like a standard settings row with a secondary detail/edit area
- less like an expanded mini-form embedded inside a list

### Advanced Providers
Check:
- picker alignment
- row spacing
- consistency with General page behavior and density

### Status Bar
Check:
- whether the preview block feels too heavy or too feature-panel-like
- whether draggable lists visually over-emphasize container styling
- whether helper text and preview hierarchy are too strong compared with system-style settings pages

Desired direction:
- preserve functionality
- make preview/ordering sections feel like settings aids, not standalone product feature cards

## Acceptance criteria for Phase 2
- all tabs feel like one coherent preferences system
- row density and alignment are consistent across tabs
- no page feels noticeably more custom or heavier than the others

---

# Phase 3 - System-Style Restraint Pass

## Priority
Medium

## Goal

Do a final polish pass aimed specifically at making the settings feel more Apple-like through restraint, not through extra decoration.

## Focus

### 1. Reduce obvious “designed UI” feeling
The page should not look like it is trying to show off custom styling.
It should feel calm and inevitable.

### 2. Strengthen grouped-form feel
The page should read as:
- grouped preferences
- supporting descriptions
- accessories aligned to a predictable column rhythm

### 3. Tone down visually heavy special sections
Examples:
- subscription custom amount edit area
- status bar preview block
- helper/info areas that visually dominate their page

## Acceptance criteria for Phase 3
- settings feel more restrained than before
- the page reads more like a system form than a custom product panel
- the interface remains clear and friendly, not sterile

---

# Suggested Implementation Order

1. `SettingsScaffold.swift`
2. `GeneralSettingsView.swift`
3. `SubscriptionSettingsView.swift`
4. `CodexSettingsView.swift`
5. `StatusBarSettingsView.swift`
6. final consistency pass across all tabs

## Why this order
- shared scaffold first gives the highest leverage
- General should act as the baseline reference page
- Subscriptions is currently the most visibly mixed page after recent native-control work
- Status Bar is the most complex page and should be polished after the base grammar is stable

---

# Practical Heuristics for the Implementing Agent

## Good signs
- sections feel lighter
- rows align naturally
- controls look native without drawing attention to themselves
- helper text is clear but visually quiet
- pages feel calmer after the change

## Bad signs
- settings look more “designed” than before
- cards still dominate the visual structure
- page headers compete with the settings controls
- each tab looks like it belongs to a different app
- visual polish is achieved by adding more effects instead of removing emphasis

---

# Validation Checklist

## Visual validation
Check all tabs side-by-side:
- General
- Status Bar
- Advanced Providers
- Subscriptions

Confirm:
- section hierarchy is consistent
- row spacing is consistent
- picker/toggle/button alignment is consistent
- headers are restrained
- pages feel calmer and more Apple-like

## Functional validation
Confirm that no behavior changed:
- pickers still save correctly
- toggles still save correctly
- subscription custom amount flow still works
- status bar ordering/settings UI still functions
- advanced provider selection still works

## Project-process validation
If implementation changes user-visible behavior or wording:
- update `README.md`
- update `README.zh-CN.md`

Unless the change is documentation-only, also:
- build the app
- relaunch the app
- verify via logs

---

# Recommended First Deliverable

If implementation starts, the first PR-sized deliverable should be:
- shared scaffold polish in `SettingsScaffold.swift`
- only minimal page-specific adjustments required to keep layout coherent

This delivers the highest ROI with the lowest risk.

## Final Instruction

Treat this as a **restraint and consistency task**.
The goal is not to make Settings more impressive.
The goal is to make Settings feel more like macOS System Settings by making it lighter, calmer, and more uniform.
