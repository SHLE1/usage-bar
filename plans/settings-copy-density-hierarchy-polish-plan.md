# Settings Copy, Density, and Hierarchy Polish Plan

## Status

Plan only. No code changes in this document.

## Branch Context

Current branch:
- `feat/macos-native-adaptation`

## Why This Plan Exists

The current Settings polish moved the UI in a more restrained, system-like direction, but it introduced three new problems:

1. supporting text readability is too low
2. some rows and summary areas feel over-compressed
3. page and section hierarchy is now too weak in places

A related issue is that some pages still explain too much in visible copy. This makes the settings feel less like macOS System Settings and more like a product UI trying to annotate itself.

## Primary Goal

Refine Settings so that it behaves more like macOS System Settings in these ways:
- less redundant explanation
- fewer always-visible descriptions
- better readability for the descriptions that remain
- clearer title/subtitle/section hierarchy
- more comfortable density for summary rows and important values
- less nested or over-explained layout

This is a **copy, hierarchy, and density polish pass**, not a behavior change.

## Read First

Before implementation, re-read:
- `AGENTS.md`
- `AGENTS-design-decisions.md`
- `plans/settings-system-settings-polish-plan.md`
- this file

## Important Constraints

### Preserve
- existing settings behavior
- existing settings tabs
- existing preference storage logic
- current native control choices unless there is a strong reason to change them
- all product semantics and design decisions already approved

### Do not do
- do not redesign the settings navigation
- do not rewrite settings business logic
- do not add decorative visual effects to solve hierarchy problems
- do not compensate for excess copy by making text too faint to read
- do not add new explanatory text unless it is truly necessary

---

# Core Principle

## The target is not “lighter text everywhere”
The target is:
- less text overall
- clearer hierarchy
- readable supporting text where supporting text is still needed

In other words:
- remove weak or redundant descriptions
- strengthen the descriptions that remain
- let structure do more work than copy

This is closer to how macOS System Settings behaves.

---

# Problems to Solve

## Problem 1 — Supporting text readability is too low
Current likely causes:
- too much use of `.tertiary` or `.quaternary`
- too much use of `caption` for meaningful explanatory text
- reduced contrast without reducing copy volume

### Desired correction
- essential supporting text should remain readable
- use weaker text styling only for genuinely secondary or decorative content
- do not hide hierarchy mistakes by fading text

## Problem 2 — Some rows feel too tight
Examples include summary-style rows like:
- configured subscription cost
- monthly totals
- small metrics or overview rows inside grouped settings sections

### Desired correction
- summary rows should feel more deliberate and slightly more spacious than ordinary rows
- not every piece of information should be squeezed into the same compact row pattern

## Problem 3 — Title hierarchy is too weak
Current likely causes:
- page subtitle too faint
- section title and section subtitle too visually similar to body/supporting copy
- row descriptions competing with section-level explanations

### Desired correction
- page title should remain clearly primary
- section title should feel clearly distinct from row content
- section subtitle should be readable, but lighter than the title
- row descriptions should be used sparingly

## Problem 4 — Too much always-visible explanation
Example patterns to reduce:
- obvious setting rows that still have a full sentence under them
- helper copy that explains interactions users can understand directly
- repeated wording across page subtitle, section subtitle, and row description

### Desired correction
- avoid explaining every setting inline
- prefer concise titles and fewer descriptions
- keep explanations only where they materially help user decision-making

---

# Design Rules For This Pass

## Rule 1 — Prefer fewer descriptions over fainter descriptions
If a row is self-explanatory, remove the row description.

Good candidates for description removal:
- App Language
- Appearance
- Launch at Login
- Critical Badge
- Status Bar Window
- simple picker/toggle rows whose title already explains the setting

## Rule 2 — Keep descriptions only when they add real context
Descriptions are still appropriate when:
- the setting has non-obvious consequences
- the setting controls a complex source selection
- the section needs one concise piece of framing context

## Rule 3 — Strengthen the remaining supporting text
Supporting text that remains should usually be more readable than it is now.
Avoid using ultra-faint styling for text that still matters.

## Rule 4 — Summary rows should not be treated like ordinary rows
Rows showing totals, summary amounts, or overview values should be allowed slightly more breathing room and stronger numeric emphasis.

## Rule 5 — One level of explanation is usually enough
Do not stack:
- page subtitle
- section subtitle
- row description

all explaining nearly the same thing.
Choose the right level and keep the others quiet or absent.

---

# File Targets

## Shared scaffold and hierarchy
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`

## Page-specific settings content
- `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/SubscriptionSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift`
- `CopilotMonitor/CopilotMonitor/App/Settings/CodexSettingsView.swift`

---

# Phase 1 - Shared Typography and Hierarchy Rules

## Goal
Adjust the shared scaffold so hierarchy is stronger and supporting text is readable enough.

## Main file
- `CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift`

## Tasks

### 1. Revisit page header hierarchy
Review:
- `SettingsPage`

Goals:
- page title remains clearly primary
- page subtitle remains readable enough to be useful
- avoid making the subtitle too faint if it is still being kept
- consider whether some pages should eventually use shorter subtitles or no subtitle

### 2. Revisit section header hierarchy
Review:
- `SettingsSectionCard`
- `SettingsSecondaryCard`

Goals:
- section title should be more distinct from body/supporting text
- section subtitle should be readable, but clearly secondary to title
- avoid using ultra-faint styling for section subtitles if those subtitles are still meaningful

### 3. Revisit row supporting text styling
Review:
- `SettingsRow`

Goals:
- row descriptions should not look disabled or barely visible
- row description spacing should not collapse hierarchy
- create a stronger default baseline for remaining row descriptions

### 4. Add or consider a specialized summary row pattern
If needed, introduce a shared row variant or helper for summary/metric rows.

Example use cases:
- configured subscription cost
- monthly total
- other rows where the right-hand value is the real focal point

Goal:
- these rows should not feel cramped or visually downgraded

## Acceptance criteria for Phase 1
- titles read clearly at page and section levels
- subtitles/descriptions that remain are readable
- shared row grammar supports both ordinary settings rows and summary rows cleanly

---

# Phase 2 - Reduce Redundant Copy Page by Page

## Goal
Remove descriptions that do not need to be visible all the time.

## Main files
- `GeneralSettingsView.swift`
- `SubscriptionSettingsView.swift`
- `StatusBarSettingsView.swift`
- `CodexSettingsView.swift`

## Tasks

### 2.1 General Settings
Audit each row description.

Likely candidates for removal or shortening:
- App Language
- Appearance
- Launch at Login
- Critical Badge

Keep descriptions only where they add real context.
For example, CLI installation or refresh/prediction behavior may justify concise context.

### 2.2 Subscriptions
Audit copy at all levels:
- page subtitle
- section subtitles
- row descriptions
- custom amount sub-row

Goals:
- reduce explanatory text where obvious
- make the summary area feel less cramped
- let the plan picker and amount value carry more of the meaning

### 2.3 Status Bar
Audit copy aggressively.
This page is especially vulnerable to over-explaining behavior.

Goals:
- keep the page understandable without narrating every interaction
- avoid visible helper text unless it adds clear value
- let previews, list structure, and titles carry more meaning

### 2.4 Advanced Providers
This page should be concise.
Keep only the minimum explanation needed for account/window selection.

## Acceptance criteria for Phase 2
- fewer visible descriptions overall
- no obvious row feels over-explained
- meaning is still clear from structure and titles

---

# Phase 3 - Relax Density for Summary and Important Rows

## Goal
Fix rows that now feel visually over-compressed.

## Main targets
- `SubscriptionSettingsView.swift`
- any shared row helpers in `SettingsScaffold.swift`

## Tasks

### 3.1 Improve summary spacing in subscription totals
Pay special attention to:
- `Configured subscription cost`
- `Monthly Total`
- right-aligned value emphasis

Goals:
- summary information should breathe more than ordinary rows
- value should be easy to scan
- row should not feel squeezed into a generic form pattern

### 3.2 Re-evaluate custom amount sub-row density
Current custom amount presentation should feel like a secondary editing area, not a cramped inline patch.

Goals:
- enough spacing to feel intentional
- not so much spacing that it becomes panel-like

### 3.3 Check any other summary-like rows
If any similar metric rows exist in other settings pages, align them to the same spacing logic.

## Acceptance criteria for Phase 3
- summary rows feel comfortable and readable
- totals and values are easier to scan
- secondary input areas no longer feel cramped

---

# Phase 4 - Final Hierarchy Consistency Pass

## Goal
Ensure every settings tab follows the same content logic:
- title
- optional page subtitle
- section title
- optional section subtitle
- row title
- optional row description
- control/value

## Tasks
- compare General, Subscriptions, Status Bar, and Advanced Providers side by side
- check which level is carrying each piece of explanation
- remove repeated explanation across levels
- verify title contrast and density feel consistent across all tabs

## Acceptance criteria for Phase 4
- hierarchy feels intentional and consistent
- supporting text is sparse but readable
- no page feels especially noisy or especially washed out

---

# Recommended Implementation Heuristics

## Good patterns
- section subtitle instead of many row descriptions
- no description for obvious rows
- readable supporting text when it remains
- clearer distinction between section headers and row descriptions
- summary values allowed slightly more space and emphasis

## Bad patterns
- description text everywhere
- quaternary text used for meaningful instructions
- summary rows squeezed into ordinary row spacing
- page subtitle, section subtitle, and row description all explaining similar things
- hierarchy achieved only by fading text instead of reducing copy

---

# Validation Checklist

## Visual
Check all tabs and confirm:
- titles are clearly stronger than subtitles
- subtitles/descriptions that remain are readable
- copy volume is lower than before
- summary rows breathe more than ordinary rows
- no page feels over-explained

## Functional
Confirm:
- no setting behavior changed
- all pickers/toggles/buttons still work
- subscription total and custom amount flow still work
- status bar settings still reorder and toggle correctly

## Process
Before handoff:
- run `make setup`
- build the app
- relaunch the app
- verify via logs
- update `README.md` and `README.zh-CN.md` only if user-visible wording or documented settings behavior meaningfully changed

---

# First Recommended Deliverable

If work starts now, the first PR-sized deliverable should be:

1. `SettingsScaffold.swift`
   - stronger hierarchy
   - more readable supporting text
   - optional summary-row support

2. `GeneralSettingsView.swift`
   - remove redundant row descriptions
   - establish baseline copy density

3. `SubscriptionSettingsView.swift`
   - fix compressed summary row feeling

This provides the highest value with the lowest behavioral risk.

## Final Instruction

Treat this as a **clarity-through-reduction** pass.
Do not solve excess copy by fading it.
Instead, remove unnecessary explanations, strengthen the hierarchy of what remains, and give summary information enough space to feel deliberate and readable.
