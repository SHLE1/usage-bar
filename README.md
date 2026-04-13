<p align="right">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">中文</a>
</p>

<p align="center">
  <img src="docs/readme-screenshot-1.jpg" alt="UsageBar overview screenshot" width="78%">
</p>

<p align="center">
  <img src="docs/readme-screenshot-2.jpg" alt="UsageBar provider details screenshot" width="39%">
  <img src="docs/readme-screenshot-3.jpg" alt="UsageBar settings screenshot" width="39%">
</p>

<p align="center">
  <strong>Monitor all your AI provider usage in real-time from the macOS menu bar.</strong>
</p>

<p align="center">
  <a href="https://github.com/SHLE1/usage-bar/releases/latest">
    <img src="https://img.shields.io/github/v/release/SHLE1/usage-bar?style=flat-square" alt="Release">
  </a>
  <a href="https://github.com/SHLE1/usage-bar/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/SHLE1/usage-bar?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.0-orange?style=flat-square" alt="Swift">
</p>

---

## Installation

### Homebrew

```bash
brew install --cask SHLE1/tap/usage-bar
```

### Direct Download

Download the latest `.dmg` from the [**Releases**](https://github.com/SHLE1/usage-bar/releases/latest) page, open it, and drag **UsageBar** to your Applications folder.

## Overview

**UsageBar** is a macOS menu bar app that automatically detects and monitors AI provider usage. It primarily reads credentials from your [OpenCode](https://opencode.ai) configuration, but also auto-detects accounts from standalone tools, system keychains, editor config files, and browser cookies — no manual setup required.

## Supported Providers

### Pay-as-you-go

| Provider | Key Metrics |
|----------|-------------|
| **OpenRouter** | Credits balance, daily/weekly/monthly cost |
| **OpenCode** | Current stats-based cost summary |

**GitHub Copilot Add-on** is a special billable row that appears when Copilot overage billing is enabled. It tracks usage-based charges that exceed the included Copilot quota.

### Quota-based

| Provider | Key Metrics |
|----------|-------------|
| **GitHub Copilot** | Multi-account, daily history, overage tracking, auth source labels |
| **Claude** | 5h/7d usage windows, Sonnet/Opus breakdown |
| **ChatGPT** | Primary/Secondary quotas, plan type |
| **Kimi for Coding** | Usage limits, membership level, reset time |
| **Gemini CLI** | Per-model quotas, multi-account support with email labels |
| **Antigravity** | Local cache reverse parsing (`state.vscdb`), no localhost dependency |
| **MiniMax Coding Plan** | 5h/weekly quotas, dual-window submenu |
| **Z.AI Coding Plan** | Token/MCP quotas, model usage, tool usage (24h) |
| **Nano-GPT** | Weekly input tokens quota, USD/NANO balance |
| **Chutes AI** | Daily quota limits, credits balance |
| **Synthetic** | 5h usage limit, request limits, reset time |

> **Note**: The raw provider ID for ChatGPT is `codex`. CLI commands use this ID (e.g., `usagebar provider codex`).

## Credential Detection

UsageBar discovers credentials from multiple sources and automatically deduplicates accounts.

### OpenCode Auth

The primary credential source. UsageBar searches for `auth.json` in:
1. `$XDG_DATA_HOME/opencode/auth.json` (if set)
2. `~/.local/share/opencode/auth.json` (default)
3. `~/Library/Application Support/opencode/auth.json` (macOS fallback)

### OpenCode Plugins

- **ChatGPT**: [`ndycode/oc-chatgpt-multi-auth`](https://github.com/ndycode/oc-chatgpt-multi-auth) — reads `~/.opencode/openai-codex-accounts.json` and per-project account files
- **Antigravity/Gemini**: [`NoeFabris/opencode-antigravity-auth`](https://github.com/NoeFabris/opencode-antigravity-auth), [`jenslys/opencode-gemini-auth`](https://github.com/jenslys/opencode-gemini-auth) — Gemini CLI OAuth creds from `~/.gemini/oauth_creds.json` are merged with Antigravity accounts
- **Claude**: [`anomalyco/opencode-anthropic-auth`](https://github.com/anomalyco/opencode-anthropic-auth)

### Standalone Tools

| Provider | Source |
|----------|--------|
| **ChatGPT** | `~/.codex/auth.json` (Codex CLI / Codex for Mac), `~/.codex-lb/` ([codex-lb](https://github.com/Soju06/codex-lb)) |
| **Claude** | macOS Keychain (Claude Code CLI) |
| **GitHub Copilot** | macOS Keychain (`github.com`), `~/.config/github-copilot/hosts.json` and `apps.json` (VS Code / Cursor), browser cookies (Chrome, Brave, Arc, Edge) |

## Features

### Multi-Provider Status Bar
The top status bar shows a compact horizontal view of selected **quota-based** providers with their icons and remaining percentages. Pay-as-you-go providers are still managed in the dropdown cost section. **Settings > Status Bar** now includes a live menu preview so you can see which items stay visible before closing settings.

### Automatic Provider Detection
- **Zero Configuration**: Reads your OpenCode `auth.json` automatically
- **Multi-Source Discovery**: Finds and merges accounts from OpenCode, standalone tools, keychains, editor configs, and browser cookies
- **Smart Categorization**: Pay-as-you-go and quota-based providers are displayed in separate groups

### Real-time Monitoring
- **Menu Bar Dashboard**: View all provider usage at a glance
- **Color-Coded Progress**: Visual indicators from green to red based on usage level
- **Detailed Submenus**: Click any provider row for in-depth metrics
- **Auth Source Labels**: Each account shows where its token was detected (OpenCode, VS Code, Keychain, etc.)

### Usage Predictions
- **Pace Indicator**: Shows whether your current usage pace is on track, slightly fast, or too fast
- **Predicted EOM**: Estimates total end-of-month costs using weighted averages
- **Wait Time**: When quota is exhausted, shows how long until the next reset

### Subscription Tracking
Quota-based providers support subscription cost configuration:
- **Per-Provider Plans**: Set your subscription tier with preset or custom monthly costs
- **Monthly Total**: Header shows the combined `$XXX/m` subscription cost
- **Orphaned Plan Cleanup**: Detects stale subscription entries that no longer match active accounts

### Settings & Personalization
- **Sidebar Settings Window**: Separate areas for General, Status Bar, Advanced Providers, and Subscriptions
- **App Language**: Follow macOS, or switch the app to English or Simplified Chinese
- **Codex Status Bar Override**: Choose which Codex account and which limit window (5h, weekly, or both) drives the status bar
- **Live Menu Preview**: Preview visible menu groups and rows while changing provider toggles

### Convenience
- **Launch at Login**: Start automatically with macOS
- **Parallel Fetching**: All providers fetch simultaneously
- **Auto Updates**: Background updates via Sparkle framework (6-hour check interval)
- **Share Usage Snapshot**: Export a snapshot of your current provider usage

## Menu Structure

```
─────────────────────────────
Pay-as-you-go: $37.61
  OpenRouter       $37.42    ▸
  OpenCode           $0.19   ▸
─────────────────────────────
Quota Status: $219/m
  Copilot (0%)               ▸
  Claude: 0%, 100%           ▸
  Kimi for Coding: 0%, 51%   ▸
  ChatGPT (100%)             ▸
  Gemini CLI #1 (100%)       ▸
─────────────────────────────
Predicted EOM: $451
─────────────────────────────
Refresh (⌘R)
Check for Updates... (⌘U)
Settings... (⌘,)
Share Usage Snapshot...
─────────────────────────────
UsageBar v0.0.6
Quit (⌘Q)
```

### Menu Group Titles

| Group | Format | Description |
|-------|--------|-------------|
| **Pay-as-you-go** | `Pay-as-you-go: $XX.XX` | Sum of all pay-as-you-go provider costs |
| **Quota Status** | `Quota Status: $XXX/m` | Monthly subscription total (or just `Quota Status` if no subscriptions are set) |
| **Predicted EOM** | `Predicted EOM: $XXX` | Estimated end-of-month total across all providers |

### Quota Display

- **Dropdown rows** show multi-window percentages when available (e.g., `Claude: 0%, 100%` for 5h and 7d windows).
- **Status bar** shows a single percentage per provider, chosen by priority: Weekly → Monthly → Daily → Hourly → fallback aggregate.
- Quota-based providers display **remaining** percentage in the dropdown (e.g., `25% left`), with color thresholds inverted so red/orange means low remaining.

## Settings

UsageBar now uses a sidebar-based settings window with four tabs:

| Tab | Contents |
|-----|----------|
| **General** | Auto Refresh Period, Prediction Period, App Language, Launch at Login, Critical Badge, CLI Install/Uninstall |
| **Status Bar** | Live menu preview, visibility toggles for pay-as-you-go and quota-based providers, and GitHub Copilot Add-on visibility |
| **Advanced Providers** | Provider-specific overrides such as the Codex account selection and status bar window mode |
| **Subscriptions** | Configure monthly subscription costs for quota-based providers (preset tiers or custom amounts) |

> **Note**: The top status bar summary only shows quota-based providers. Pay-as-you-go providers still remain visible in the dropdown cost section.

### CLI Installation

Install the CLI from **Settings > General > Command Line Tool**:
- Click **Install** to copy the CLI binary to `/usr/local/bin/usagebar`
- Requires administrator privileges (prompted via system dialog)
- Alternatively, run `bash scripts/install-cli.sh` manually

## Command Line Interface

```bash
# Show all providers and their usage (default command)
usagebar status

# List all configured providers
usagebar list

# Get detailed info for a specific provider (use raw provider IDs)
usagebar provider claude
usagebar provider codex          # ChatGPT
usagebar provider gemini_cli
usagebar provider copilot

# JSON output for scripting
usagebar status --json
usagebar provider claude --json
usagebar list --json
```

### Table Output Example

```
$ usagebar status
Provider              Type             Usage       Key Metrics
─────────────────────────────────────────────────────────────────────────────────
Claude                Quota-based      77%         23/100 remaining
ChatGPT               Quota-based      0%          100/100 remaining
Copilot (user1)       Quota-based      45%         550/1000 remaining
Copilot (user2)       Quota-based      12%         880/1000 remaining
Gemini CLI (user@gmail.com)  Quota-based  0%       100% remaining
Kimi for Coding       Quota-based      26%         74/100 remaining
MiniMax Coding Plan   Quota-based      0%, 0%      100/100 remaining
OpenCode              Pay-as-you-go    -           $0.19 spent
OpenRouter            Pay-as-you-go    -           $37.42 spent
```

### JSON Output Example

```json
{
  "claude": {
    "type": "quota-based",
    "remaining": 23,
    "entitlement": 100,
    "usagePercentage": 77,
    "overagePermitted": false
  },
  "copilot": {
    "type": "quota-based",
    "remaining": 1430,
    "entitlement": 2000,
    "usagePercentage": 28,
    "overagePermitted": true,
    "accounts": [
      {
        "index": 0,
        "login": "user1",
        "authSource": "opencode",
        "remaining": 550,
        "entitlement": 1000,
        "usagePercentage": 45,
        "overagePermitted": true
      }
    ]
  },
  "openrouter": {
    "type": "pay-as-you-go",
    "cost": 37.42
  }
}
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (no data available) |
| 2 | Authentication failed |
| 3 | Network error |
| 4 | Invalid arguments |

## How It Works

1. **Token Discovery**: Reads authentication tokens from OpenCode's `auth.json` (with multi-path XDG fallback), plus plugin-managed metadata
2. **Multi-Source Account Discovery**: For providers like ChatGPT and GitHub Copilot, discovers accounts from multiple sources and deduplicates them by stable account metadata (email-first key strategy)
3. **Parallel Fetching**: Queries all provider APIs simultaneously using Swift TaskGroup with configurable timeouts
4. **Smart Caching**: Falls back to cached data on network errors; daily history uses a hybrid cache strategy (fresh data for recent days, cached for older days)
5. **Graceful Degradation**: Shows available providers even if some fail; partial success for multi-account providers

### Privacy & Security

- **Local Only**: All data stays on your machine — no third-party servers
- **Read-only Access**: Uses existing tokens from OpenCode and other sources (no additional permissions requested)
- **Direct API Communication**: Queries provider APIs directly without intermediaries
- **Browser Cookie Access**: GitHub Copilot optionally reads session cookies from supported browsers (read-only, no passwords stored)

## Troubleshooting

### "No providers found"

Verify that OpenCode is installed and authenticated. The app searches for `auth.json` in:
1. `$XDG_DATA_HOME/opencode/auth.json` (if `XDG_DATA_HOME` is set)
2. `~/.local/share/opencode/auth.json` (default)
3. `~/Library/Application Support/opencode/auth.json` (macOS fallback)

For ChatGPT multi-account setups, the app also searches:
- `~/.opencode/auth/openai.json`
- `~/.opencode/openai-codex-accounts.json`
- `~/.opencode/projects/*/openai-codex-accounts.json`

### GitHub Copilot not showing

Copilot accounts are discovered from multiple sources (in priority order):
1. **OpenCode auth** — `copilot` entry in `auth.json`
2. **Copilot CLI Keychain** — macOS Keychain entries for `github.com`
3. **VS Code / Cursor** — `~/.config/github-copilot/hosts.json` and `apps.json`
4. **Browser Cookies** — Chrome, Brave, Arc, Edge session cookies

Accounts from different sources with the same login are automatically merged. Use `usagebar provider copilot` to verify which sources are detected.

### OpenCode binary not found

The app dynamically searches for the `opencode` binary using multiple strategies:
1. Current PATH (`which opencode`)
2. Login shell PATH
3. Common install locations: `~/.opencode/bin/opencode`, Homebrew paths, `/usr/local/bin/opencode`

## Development

### Prerequisites

- macOS 13.0+
- Xcode 15.0+

### Setup

```bash
git clone https://github.com/SHLE1/usage-bar.git
cd usage-bar

# Configure git hooks (required before first commit)
make setup
```

Git hooks include:
- **SwiftLint**: Validates Swift code style on staged `.swift` files
- **action-validator**: Validates GitHub Actions workflow YAML files

### Build & Run

```bash
# Build
xcodebuild -project CopilotMonitor/CopilotMonitor.xcodeproj \
  -scheme CopilotMonitor -configuration Debug build

# Run (auto-detect build path)
open "$(xcodebuild -project CopilotMonitor/CopilotMonitor.xcodeproj \
  -scheme CopilotMonitor -configuration Debug -showBuildSettings 2>/dev/null \
  | sed -n 's/^[[:space:]]*BUILT_PRODUCTS_DIR = //p' | head -n 1)/UsageBar.app"
```

Or use the VS Code task **"Debug: Kill + Build + Run"** for a one-click workflow.

### Linting

```bash
make lint            # Run all linters
make lint-swift      # SwiftLint only
make lint-actions    # GitHub Actions YAML validation only
```

## Contributing

Contributions are welcome! Please submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run `make setup` (once, after clone)
4. Make your changes
5. Commit (`git commit -m 'Add amazing feature'`) — pre-commit hooks will run automatically
6. Push (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

MIT License — see [LICENSE](LICENSE) for details.

## Related

- [OpenCode](https://opencode.ai) — The AI coding tool that powers provider detection
- [GitHub Copilot](https://github.com/features/copilot)

## Credits

- [OP.GG](https://op.gg)
- [Sangrak Choi](https://kargn.as)

---

<p align="center">
  Made with tiredness for AI power users
</p>
