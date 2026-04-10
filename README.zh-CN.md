<p align="right">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">中文</a>
</p>

<p align="center">
  <img src="docs/screenshot-subscription.png" alt="UsageBar 截图" width="40%">
  <img src="docs/screenshot3.png" alt="UsageBar 截图" width="40%">
</p>

<!-- TODO: 待 README 文字定稿且 UI 样式稳定后，更新截图。 -->

<p align="center">
  <strong>在 macOS 菜单栏中实时监控你所有 AI 服务商的用量。</strong>
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

## 安装

### Homebrew

```bash
brew install --cask SHLE1/tap/usage-bar
```

### 直接下载

从 [**Releases**](https://github.com/SHLE1/usage-bar/releases/latest) 页面下载最新的 `.dmg` 文件，打开后将 **UsageBar** 拖入「应用程序」文件夹即可。

## 简介

**UsageBar** 是一款 macOS 菜单栏应用，可自动检测并监控 AI 服务商的用量。它主要从你的 [OpenCode](https://opencode.ai) 配置中读取凭证，同时也会自动从独立工具、系统钥匙串、编辑器配置文件及浏览器 Cookie 中发现账号——无需任何手动配置。

## 支持的服务商

### 按量付费（Pay-as-you-go）

| 服务商 | 核心指标 |
|--------|---------|
| **OpenRouter** | 积分余额、日/周/月费用 |
| **OpenCode** | 当前统计费用摘要 |

**GitHub Copilot 附加账单（Add-on）** 是一个特殊的计费行，当 Copilot 超额计费功能启用时出现，用于追踪超出 Copilot 配额后的用量计费。

### 配额制（Quota-based）

| 服务商 | 核心指标 |
|--------|---------|
| **GitHub Copilot** | 多账号、每日历史、超额追踪、认证来源标签 |
| **Claude** | 5h/7d 用量窗口、Sonnet/Opus 拆分 |
| **ChatGPT** | 主/副配额、套餐类型 |
| **Kimi for Coding** | 用量上限、会员等级、重置时间 |
| **Gemini CLI** | 按模型配额、多账号支持（显示邮箱标签） |
| **Antigravity** | 本地缓存反解析（`state.vscdb`），无需本地服务 |
| **MiniMax Coding Plan** | 5h/周 配额、双窗口子菜单 |
| **Z.AI Coding Plan** | Token/MCP 配额、模型用量、工具用量（24h） |
| **Nano-GPT** | 每周输入 Token 配额、USD/NANO 余额 |
| **Chutes AI** | 每日配额限制、积分余额 |
| **Synthetic** | 5h 用量上限、请求数限制、重置时间 |

> **注意**：ChatGPT 的原始 Provider ID 为 `codex`，CLI 命令中使用此 ID（例如 `usagebar provider codex`）。

## 凭证发现机制

UsageBar 从多个来源发现凭证，并自动对账号去重。

### OpenCode Auth

主要凭证来源。UsageBar 按以下顺序查找 `auth.json`：

1. `$XDG_DATA_HOME/opencode/auth.json`（若 `XDG_DATA_HOME` 已设置）
2. `~/.local/share/opencode/auth.json`（默认路径）
3. `~/Library/Application Support/opencode/auth.json`（macOS 后备路径）

### OpenCode 插件

- **ChatGPT**：[`ndycode/oc-chatgpt-multi-auth`](https://github.com/ndycode/oc-chatgpt-multi-auth) — 读取 `~/.opencode/openai-codex-accounts.json` 及各项目的账号文件
- **Antigravity/Gemini**：[`NoeFabris/opencode-antigravity-auth`](https://github.com/NoeFabris/opencode-antigravity-auth)、[`jenslys/opencode-gemini-auth`](https://github.com/jenslys/opencode-gemini-auth) — Gemini CLI OAuth 凭证来自 `~/.gemini/oauth_creds.json`，与 Antigravity 账号合并
- **Claude**：[`anomalyco/opencode-anthropic-auth`](https://github.com/anomalyco/opencode-anthropic-auth)

### 独立工具

| 服务商 | 来源 |
|--------|------|
| **ChatGPT** | `~/.codex/auth.json`（Codex CLI / Codex for Mac）、`~/.codex-lb/`（[codex-lb](https://github.com/Soju06/codex-lb)） |
| **Claude** | macOS 钥匙串（Claude Code CLI） |
| **GitHub Copilot** | macOS 钥匙串（`github.com`）、`~/.config/github-copilot/hosts.json` 和 `apps.json`（VS Code / Cursor）、浏览器 Cookie（Chrome、Brave、Arc、Edge） |

## 功能

### 多服务商状态栏
状态栏以紧凑的横向列表展示所选服务商的用量指标，每个服务商图标旁显示使用百分比或费用。可在 **设置 > 状态栏** 中选择要显示的服务商。

### 自动服务商发现
- **零配置**：自动读取 OpenCode 的 `auth.json`
- **多来源发现**：从 OpenCode、独立工具、钥匙串、编辑器配置和浏览器 Cookie 中查找并合并账号
- **智能分类**：按量付费与配额制服务商分组展示

### 实时监控
- **菜单栏看板**：一览所有服务商用量
- **颜色编码进度条**：从绿色到红色直观显示用量等级
- **详细子菜单**：点击任意服务商行查看深度指标
- **认证来源标签**：每个账号显示 Token 发现来源（OpenCode、VS Code、钥匙串等）

### 用量预测
- **节奏指示器**：显示当前用量节奏是正常、偏快还是过快
- **月末预测（EOM）**：使用加权平均算法预估月底总费用
- **等待时间**：配额耗尽时，显示距下次重置的剩余时间

### 订阅追踪
配额制服务商支持订阅费用配置：
- **按服务商配置套餐**：可选预设档位或输入自定义月费
- **月度合计**：标题行显示合并后的 `$XXX/m` 订阅总费用
- **孤立条目清理**：自动检测不再匹配活跃账号的过期订阅记录

### 便利功能
- **登录时启动**：随 macOS 自动启动
- **并发获取**：所有服务商同时拉取数据
- **自动更新**：通过 Sparkle 框架后台更新（每 6 小时检查一次）
- **分享用量快照**：导出当前服务商用量概览

## 菜单结构

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
UsageBar v2.9.2
Quit (⌘Q)
```

### 菜单分组标题

| 分组 | 格式 | 说明 |
|------|------|------|
| **Pay-as-you-go** | `Pay-as-you-go: $XX.XX` | 所有按量付费服务商的费用总和 |
| **Quota Status** | `Quota Status: $XXX/m` | 月度订阅总费用（若未配置订阅，则仅显示 `Quota Status`） |
| **Predicted EOM** | `Predicted EOM: $XXX` | 全服务商月末预估总费用 |

### 配额显示规则

- **下拉行**：当有多个时间窗口时显示所有百分比（例如 `Claude: 0%, 100%` 分别代表 5h 和 7d 窗口）
- **状态栏**：每个服务商显示单一百分比，优先级顺序为：周 → 月 → 日 → 时 → 回退聚合值
- 配额制服务商在下拉菜单中显示**剩余**百分比（如 `25% left`），颜色阈值反转——红/橙代表剩余量低

## 设置

UsageBar 包含三个设置选项卡：

| 选项卡 | 内容 |
|--------|------|
| **General（通用）** | 自动刷新周期、预测周期、登录时启动、紧急徽章、CLI 安装/卸载 |
| **Status Bar（状态栏）** | 切换各服务商在多服务商状态栏中的可见性，以及启用/禁用 GitHub Copilot Add-on |
| **Subscriptions（订阅）** | 为配额制服务商配置月度订阅费用（预设档位或自定义金额） |

### CLI 安装

从 **Settings > General > Command Line Tool** 安装 CLI：
- 点击 **Install** 将 CLI 二进制文件复制到 `/usr/local/bin/usagebar`
- 需要管理员权限（系统会弹出授权对话框）
- 也可手动运行 `bash scripts/install-cli.sh`

## 命令行工具

```bash
# 显示所有服务商及其用量（默认命令）
usagebar status

# 列出所有已配置的服务商
usagebar list

# 查询指定服务商的详细信息（使用原始 Provider ID）
usagebar provider claude
usagebar provider codex          # ChatGPT
usagebar provider gemini_cli
usagebar provider copilot

# JSON 输出（用于脚本集成）
usagebar status --json
usagebar provider claude --json
usagebar list --json
```

### 表格输出示例

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

### JSON 输出示例

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

### 退出码

| 代码 | 含义 |
|------|------|
| 0 | 成功 |
| 1 | 通用错误（无可用数据） |
| 2 | 认证失败 |
| 3 | 网络错误 |
| 4 | 无效参数 |

## 工作原理

1. **Token 发现**：从 OpenCode 的 `auth.json`（支持 XDG 多路径回退）及插件管理的元数据中读取认证 Token
2. **多来源账号发现**：对 ChatGPT、GitHub Copilot 等多账号服务商，从多个来源发现账号并按稳定的账号元数据（邮箱优先策略）去重合并
3. **并发获取**：通过 Swift TaskGroup 同时查询所有服务商 API，支持可配置超时
4. **智能缓存**：网络错误时回退到缓存数据；每日历史采用混合缓存策略（近期获取新数据，较早日期使用缓存）
5. **优雅降级**：部分服务商失败时仍显示可用的服务商；多账号服务商支持部分成功

### 隐私与安全

- **纯本地运行**：所有数据保留在你的设备上，无任何第三方服务器
- **只读访问**：使用来自 OpenCode 及其他来源的现有 Token，不申请额外权限
- **直连 API**：直接与服务商 API 通信，无任何中间层
- **浏览器 Cookie 访问**：GitHub Copilot 可选读取支持浏览器的会话 Cookie（只读，不存储密码）

## 常见问题

### "No providers found"（未找到服务商）

确认 OpenCode 已安装并完成认证。应用按以下顺序查找 `auth.json`：

1. `$XDG_DATA_HOME/opencode/auth.json`（若 `XDG_DATA_HOME` 已设置）
2. `~/.local/share/opencode/auth.json`（默认路径）
3. `~/Library/Application Support/opencode/auth.json`（macOS 后备路径）

对于 ChatGPT 多账号配置，应用还会搜索：
- `~/.opencode/auth/openai.json`
- `~/.opencode/openai-codex-accounts.json`
- `~/.opencode/projects/*/openai-codex-accounts.json`

### GitHub Copilot 未显示

Copilot 账号按以下优先级从多个来源发现：

1. **OpenCode auth** — `auth.json` 中的 `copilot` 条目
2. **Copilot CLI 钥匙串** — macOS 钥匙串中 `github.com` 相关条目
3. **VS Code / Cursor** — `~/.config/github-copilot/hosts.json` 和 `apps.json`
4. **浏览器 Cookie** — Chrome、Brave、Arc、Edge 的会话 Cookie

不同来源中登录名相同的账号将自动合并。使用 `usagebar provider copilot` 可验证已检测到的来源。

### 找不到 OpenCode 二进制文件

应用通过多种策略动态查找 `opencode` 二进制文件：

1. 当前 PATH（`which opencode`）
2. 登录 Shell 的 PATH
3. 常见安装路径：`~/.opencode/bin/opencode`、Homebrew 路径、`/usr/local/bin/opencode`

## 开发

### 环境要求

- macOS 13.0+
- Xcode 15.0+

### 初始化

```bash
git clone https://github.com/SHLE1/usage-bar.git
cd usage-bar

# 配置 Git 钩子（克隆后首次运行，必须执行）
make setup
```

Git 钩子包含：
- **SwiftLint**：对暂存的 `.swift` 文件检查代码风格
- **action-validator**：验证 GitHub Actions 工作流 YAML 文件

### 构建与运行

```bash
# 构建
xcodebuild -project CopilotMonitor/CopilotMonitor.xcodeproj \
  -scheme CopilotMonitor -configuration Debug build

# 运行（自动检测构建路径）
open "$(xcodebuild -project CopilotMonitor/CopilotMonitor.xcodeproj \
  -scheme CopilotMonitor -configuration Debug -showBuildSettings 2>/dev/null \
  | sed -n 's/^[[:space:]]*BUILT_PRODUCTS_DIR = //p' | head -n 1)/UsageBar.app"
```

也可使用 VS Code 任务 **"Debug: Kill + Build + Run"** 一键完成。

### 代码检查

```bash
make lint            # 运行所有 Linter
make lint-swift      # 仅 SwiftLint
make lint-actions    # 仅 GitHub Actions YAML 验证
```

## 贡献

欢迎提交 Pull Request！

1. Fork 本项目
2. 创建你的功能分支（`git checkout -b feature/amazing-feature`）
3. 运行 `make setup`（克隆后首次执行）
4. 完成你的修改
5. 提交（`git commit -m 'Add amazing feature'`）—— 预提交钩子会自动运行
6. 推送（`git push origin feature/amazing-feature`）
7. 创建 Pull Request

## 许可证

MIT License — 详见 [LICENSE](LICENSE) 文件。

## 相关项目

- [OpenCode](https://opencode.ai) — 服务商发现的核心依赖
- [GitHub Copilot](https://github.com/features/copilot)

## 致谢

- [OP.GG](https://op.gg)
- [Sangrak Choi](https://kargn.as)

---

<p align="center">
  Made with tiredness for AI power users
</p>
