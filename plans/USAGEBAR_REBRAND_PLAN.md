# UsageBar Rebrand Plan

## Goal

Rebrand this fork from the upstream `OpenCode Bar` identity into `UsageBar` owned by `SHLE1`, while preserving existing functionality and adding lightweight attribution to the original project.

## Target Identity

- App name: `UsageBar`
- Repo URL: `https://github.com/SHLE1/usage-bar`
- Repo slug: `SHLE1/usage-bar`
- CLI command: `usagebar`
- CLI binary name: `usagebar-cli`
- Bundle ID: `io.github.SHLE1.UsageBar`
- Credit style: lightweight attribution in app copy only

## Done Criteria

- All user-visible app naming is updated from `OpenCode Bar` to `UsageBar`.
- All in-app GitHub links point to `https://github.com/SHLE1/usage-bar`.
- App bundle metadata, product names, executable paths, and CLI naming are aligned with `UsageBar` and `usagebar`.
- Release assets and Sparkle metadata no longer reference upstream names or URLs.
- A lightweight attribution sentence to the original upstream project is present in app copy.
- Build, tests, packaging, and update metadata are verified after the rename.

## Recommended Execution Order

1. Update app identity and in-app links.
2. Update Xcode project product names, executable names, and bundle IDs.
3. Update CLI command names, install paths, and helper scripts.
4. Update release workflows, Sparkle feed URLs, DMG names, and release titles.
5. Update docs, screenshots, and repository metadata.
6. Rebuild, run, inspect logs, and validate release packaging.

## Phase 1: App Identity and In-App Ownership

### Must change

- `CopilotMonitor/CopilotMonitor/Info.plist`
  - `CFBundleDisplayName`
  - `CFBundleIdentifier`
  - `CFBundleName`
  - `SUFeedURL`
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
  - Version menu title currently shows `OpenCode Bar`
  - Share snapshot text currently says `My OpenCode Bar usage snapshot`
  - GitHub repository URL currently points to upstream
  - GitHub issue creation URL currently points to upstream
  - GitHub support prompt currently says `Support OpenCode Bar?`
  - CLI install menu text currently uses `opencodebar`
  - CLI install success text currently uses `/usr/local/bin/opencodebar`
  - Add lightweight attribution sentence in support/about-related copy
- `CopilotMonitor/CopilotMonitor/App/AppMigrationHelper.swift`
  - Change target bundle name from `OpenCode Bar.app` to `UsageBar.app`
  - Change expected bundle ID to `io.github.SHLE1.UsageBar`
  - Preserve old bundle names for migration cleanup
  - Add `OpenCode Bar.app` to legacy names if needed for smooth migration from existing installs

### Should verify after change

- `CopilotMonitor/CopilotMonitor/App/AppDelegate.swift`
  - Sparkle logging remains valid after app/feed rename
- `CopilotMonitor/CopilotMonitor/App/ModernApp.swift`
  - No display copy depends on old app name

## Phase 2: Xcode Project and Build Product Names

### Must change

- `CopilotMonitor/CopilotMonitor.xcodeproj/project.pbxproj`
  - Main app product reference `OpenCode Bar.app` -> `UsageBar.app`
  - Main target `PRODUCT_NAME` -> `UsageBar`
  - Main target `PRODUCT_BUNDLE_IDENTIFIER` -> `io.github.SHLE1.UsageBar`
  - CLI target display/product name `opencodebar-cli` -> `usagebar-cli`
  - Embedded CLI copy phase references
  - `TEST_HOST` paths from `OpenCode Bar.app/Contents/MacOS/OpenCode Bar`
  - Any build artifact names that still expose upstream branding

### Optional cleanup

- Internal target names like `CopilotMonitor` and `CopilotMonitorTests`
  - Can be left as-is for now if rename risk is higher than value
  - Rename later only if you want complete internal consistency

## Phase 3: CLI Naming and Install Flow

### Must change

- `CopilotMonitor/CLI/main.swift`
  - `commandName: "opencodebar"` -> `usagebar`
- `CopilotMonitor/CopilotMonitor/App/Settings/CLIService.swift`
  - Install path `/usr/local/bin/opencodebar` -> `/usr/local/bin/usagebar`
  - Bundle CLI executable `opencodebar-cli` -> `usagebar-cli`
  - Install/uninstall AppleScript commands
- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
  - Duplicate CLI install paths/messages also updated here
- `scripts/install-cli.sh`
  - App path `/Applications/OpenCode Bar.app` -> `/Applications/UsageBar.app`
  - CLI source `opencodebar-cli` -> `usagebar-cli`
  - CLI destination `/usr/local/bin/opencodebar` -> `/usr/local/bin/usagebar`
  - User-facing script output updated to `UsageBar` and `usagebar`

### Should verify after change

- App menu install flow still succeeds with administrator privileges
- Installed CLI command works from Terminal

## Phase 4: Release, Sparkle, and Distribution

### Must change

- `CopilotMonitor/CopilotMonitor/Info.plist`
  - `SUFeedURL` should point to `https://github.com/SHLE1/usage-bar/releases/latest/download/appcast.xml`
- `.github/workflows/build-release.yml`
  - App paths `OpenCode Bar.app` -> `UsageBar.app`
  - Main executable `OpenCode Bar` -> `UsageBar`
  - CLI executable `opencodebar-cli` -> `usagebar-cli`
  - Unsigned DMG name `OpenCode-Bar.dmg` -> `UsageBar.dmg` or chosen final convention
  - Release DMG name `OpenCode-Bar-${VERSION}.dmg` -> `UsageBar-${VERSION}.dmg`
  - Volume names `OpenCode Bar` -> `UsageBar`
  - Sparkle download URL from upstream repo -> `SHLE1/usage-bar`
  - Sparkle appcast title `OpenCode Bar Updates` -> `UsageBar Updates`
  - Artifact names `OpenCode-Bar*` -> `UsageBar*`
  - Release title `OpenCode Bar <version>` -> `UsageBar <version>`
- `.github/workflows/manual-release.yml`
  - Same app path and executable updates as above
  - Replace mixed legacy DMG name `OpenCodeUsageMonitor-${VERSION}.dmg`
  - Replace upstream repo URLs in Sparkle appcast generation
  - Replace release title `OpenCode Bar <version>` -> `UsageBar <version>`
  - Review the workflow's version-bump commit/push step after repo rename
- `ExportOptions.plist`
  - Verify export still works with renamed bundle/product

### Important follow-up

- `SUPublicEDKey` in `Info.plist` and `SPARKLE_PRIVATE_KEY` secret in GitHub Actions must match your own Sparkle key pair if you want independent updates.
- If you keep the upstream Sparkle key, update trust and ownership implications should be reviewed before release.

## Phase 5: Repository, Docs, and Public Metadata

### Must change

- `README.md`
  - Repo badges and links from upstream -> `SHLE1/usage-bar`
  - Product name `OpenCode Bar` -> `UsageBar`
  - CLI command examples `opencodebar` -> `usagebar`
  - Installation/release links
  - Clone instructions
  - Any references to current app bundle name
- `docs/RELEASE_WORKFLOW.md`
  - App name, app path, DMG name, release upload commands
- `docs/AI_USAGE_API_REFERENCE.md`
  - Branding references to `OpenCode Bar`
- `package.json`
  - Package name and description still mention `copilot-monitor`

### Should change

- `AGENTS.md`
  - Current brand, bundle ID, CLI examples, and repo-specific notes
- `AGENTS-design-decisions.md`
  - Brand references in menu examples and status bar wording
- `.vscode/tasks.json`
  - Check generated/opened app path if it references `OpenCode Bar.app`

## Phase 6: Visual Assets and Screenshots

### Should change

- `CopilotMonitor/CopilotMonitor/Assets.xcassets/AppIcon.appiconset/*`
  - Replace the app icon with your own asset if you want complete ownership branding
- `docs/appicon.jpg`
  - Update public app icon preview
- `docs/screenshot-subscription.png`
- `docs/screenshot3.png`
- `docs/screenshot2.png`
- `docs/screenshot.jpeg`
  - Refresh screenshots after app rename so public materials match the product

## Phase 7: Attribution

### Chosen style

- Use lightweight attribution in app copy only

### Recommended placement

- `CopilotMonitor/CopilotMonitor/App/StatusBarController.swift`
  - Support/about-related prompt or informational text

### Recommended copy

- `Based on the original opgginc/opencode-bar project.`

## Validation Checklist

### Local development

- Run `make setup`
- Build app in Debug and Release
- Confirm generated app name is `UsageBar.app`
- Confirm main executable name is `UsageBar`
- Confirm embedded CLI name is `usagebar-cli`
- Confirm CLI install creates `/usr/local/bin/usagebar`
- Confirm `usagebar --help` works
- Confirm in-app GitHub links open `https://github.com/SHLE1/usage-bar`
- Confirm issue reporter opens the correct issue URL

### App behavior

- Clear old cached settings if needed and test launch
- Confirm bundle migration from an existing `OpenCode Bar.app` install
- Confirm no broken menu items after rename
- Confirm share snapshot text uses `UsageBar`
- Confirm the attribution sentence is visible where intended

### Release pipeline

- Run workflow validation on `.github/workflows/*.yml`
- Verify artifact names use `UsageBar`
- Verify appcast uses your repo URL
- Verify `SUFeedURL` matches the generated appcast URL
- Verify Sparkle signature generation succeeds with your key
- Verify notarization paths reference `UsageBar.app`

## Risks and Notes

- Changing bundle ID can affect settings continuity, login item behavior, and update migration.
- Renaming the app bundle without keeping migration logic can break upgrades for existing installs.
- Sparkle will not become truly independent until feed URLs and keys are updated.
- Internal target names can stay unchanged temporarily to reduce rename risk.
- The manual release workflow currently mixes multiple legacy names, so release cleanup should be treated as a separate focused pass.

## Suggested First Implementation Slice

1. `Info.plist`
2. `project.pbxproj`
3. `StatusBarController.swift`
4. `CLIService.swift`
5. `CLI/main.swift`
6. `AppMigrationHelper.swift`
7. `scripts/install-cli.sh`

That slice is enough to make the running app feel like `UsageBar` before moving on to release automation and public docs.
