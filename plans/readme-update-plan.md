# README Update Plan

## Goal

Align `README.md` with the current UsageBar app behavior, current UI, current provider naming, and current installation/build flow.

## Done Criteria

- `README.md` matches the current app behavior for menu layout, settings, provider naming, CLI install flow, and OpenCode positioning.
- Outdated status bar mode documentation is removed or rewritten to match the current implementation.
- Provider descriptions reflect the current app behavior instead of old assumptions.
- Build-from-source instructions are updated to the current project reality.
- Screenshot updates are not required in this task, but a clear placeholder section is reserved.

## Current Mismatches To Fix

### 1. Status bar documentation is outdated

- `README.md:334-357` still documents old status bar modes such as `Total Cost`, `Icon Only`, and `Only Show`.
- Current runtime behavior forces `Multi-Provider Bar` mode in `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift:179-188`.
- Current settings UI only exposes provider toggles for the status bar in `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift:21-34`.
- `Critical Badge` now lives in the General settings tab in `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift:36-38`.

### 2. Menu structure example is outdated

- `README.md:301-325` shows old menu items and an old version example.
- Current menu now includes:
  - `Refresh`
  - `Check for Updates...`
  - `Settings...`
  - `Share Usage Snapshot...`
  - `UsageBar v<version>`
- Source of truth: `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift:403-412`, `484-499`.

### 3. Provider naming and provider descriptions need updates

- The current user-facing name for `codex` is `ChatGPT`, not `Codex`.
- Source: `CopilotMonitor/CopilotMonitor/Models/ProviderProtocol.swift:33-35`.
- `OpenCode` is now a single pay-as-you-go provider with current stats-based summary, not the older history-focused description.
- Source: `CopilotMonitor/CopilotMonitor/Providers/OpenCodeProvider.swift:22-24`, `157-200`.
- `GitHub Copilot Add-on` behaves as a special billable row/toggle, not a normal provider enum case.
- Source: `CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift:21-26`, `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift:1615-1670`.

### 4. Build from source instructions likely no longer match the repo

- `README.md:120-130` points to `CopilotMonitor/CopilotMonitor.xcodeproj`.
- The current repository snapshot does not expose a `.xcodeproj` file through the current file scan, so the build section should be revalidated and rewritten before publishing.

### 5. Usage history wording is too broad

- `README.md:101-105` suggests a general history/prediction feature set.
- Top-level `Usage History` is intentionally removed from the main menu.
- Source: `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift:390-398`.
- The README should describe history only where it actually exists and avoid implying a unified global history page for every provider.

### 6. CLI installation wording should match the current settings UI

- README currently says to click `Install CLI` from the Settings menu.
- The current UI installs the CLI from the `General` tab under `Command Line Tool`.
- Source: `CopilotMonitor/CopilotMonitor/App/Settings/GeneralSettingsView.swift:42-65`.
- Install target is `/usr/local/bin/usagebar`.
- Source: `CopilotMonitor/CopilotMonitor/App/Settings/CLIService.swift:9-21`.

## Recommended README Rewrite Structure

### 1. Header

- Keep the app name as `UsageBar`.
- Keep release/license/platform badges if they are still valid.
- Leave a screenshot placeholder note instead of refreshing images in this task.

### 2. Installation

- Keep Homebrew install instructions if still valid.
- Keep release DMG install instructions.
- Clarify that the app is a macOS menu bar app.

### 3. Overview

- Reword the overview to say that UsageBar is centered on OpenCode discovery but also auto-detects credentials from additional local sources for some providers.
- Avoid describing the app as OpenCode-only.

### 4. Supported Providers

- Rewrite the table to match current provider display names and current scope.
- Explicitly separate:
  - Standard providers
  - Special billing items such as `GitHub Copilot Add-on`
- Use the provider display names from `ProviderIdentifier.displayName` as the public-facing names where appropriate.

### 5. Detection Sources

- Keep the OpenCode plugin and standalone-tool sections.
- Keep multi-source detection notes for Copilot, Codex/ChatGPT, and Claude Code.
- Reword them for clarity and avoid duplication between sections.

### 6. Features

- Rewrite the feature list around the current product:
  - Automatic provider detection
  - Multi-provider status bar
  - Detailed provider submenus
  - Subscription tracking for quota-based providers
  - CLI install and CLI queries
  - Sparkle auto updates
- Remove or narrow claims that are no longer globally true.

### 7. Settings

- Add a short section for the current settings layout:
  - `General`
  - `Status Bar`
  - `Subscriptions`
- Clarify that provider visibility is configured from the Status Bar tab.

### 8. CLI

- Keep `usagebar status`, `usagebar list`, and `usagebar provider <id>` examples.
- Update any examples that still imply `Codex` is the current display name instead of `ChatGPT`.
- Keep raw provider IDs documented because CLI commands still use them.

### 9. Menu Structure

- Replace the current ASCII menu example with one that reflects the real menu shape today.
- Use placeholders where exact dynamic provider rows vary by user configuration.

### 10. Privacy and Security

- Keep the local-only and direct-provider-API messaging.
- Keep browser-cookie access notes for Copilot, since that behavior still exists.

### 11. Development

- Revalidate and rewrite build instructions.
- Keep `make setup` because it is still required before development.
- Mention that git hooks install SwiftLint and action-validator.

### 12. Screenshots Placeholder

- Add a small placeholder section such as:
  - `TODO: Refresh screenshots after README text is updated.`
- Do not block the README rewrite on image refresh.

## Edit Plan

1. Rewrite the Overview and Supported Providers sections.
2. Rewrite Features to match the current app behavior.
3. Rewrite the status bar and menu documentation.
4. Update CLI installation wording and command examples.
5. Revalidate and rewrite the Development section.
6. Add a screenshot placeholder section without changing image assets.
7. Do a final pass for naming consistency: `UsageBar`, `usagebar`, `ChatGPT`, `OpenCode`, `GitHub Copilot Add-on`.

## Validation Checklist

- Read the final `README.md` once top to bottom.
- Check every UI term against current source names.
- Check every CLI command example against the current CLI entrypoints in `CopilotMonitor/CLI/main.swift`.
- Check every settings reference against `SettingsView`, `GeneralSettingsView`, and `StatusBarSettingsView`.
- Check every menu claim against `StatusBarController.swift`.
- Confirm the screenshot section is clearly marked as a placeholder.

## Screenshot Placeholder

TODO: Refresh README screenshots after the text update is finished and the latest UI state is stable.
