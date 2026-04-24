# 统一 Xcode 项目名称为 UsageBar

## 摘要
- 将开发环境里的旧名 `CopilotMonitor` 统一改为 `UsageBar`。
- 实际 App 名称、Bundle ID 已经是 `UsageBar`，这次主要修正 Xcode project、target、scheme、目录路径、构建命令和发布文档。
- 不修改 `plans/` 历史计划文件；保留 `AppMigrationHelper` 里的 `CopilotMonitor.app`，因为它用于旧版本迁移兼容。
s
## 主要改动
- Xcode 结构：
  - `CopilotMonitor/` 目录改为 `UsageBar/`
  - `CopilotMonitor.xcodeproj` 改为 `UsageBar.xcodeproj`
  - 主 target / scheme 从 `CopilotMonitor` 改为 `UsageBar`
  - 测试 target 从 `CopilotMonitorTests` 改为 `UsageBarTests`
  - entitlements 文件从 `CopilotMonitor.entitlements` 改为 `UsageBar.entitlements`
- 构建与发布配置：
  - 更新 `.github/workflows/*.yml` 中的 project、scheme、工作目录、archive 路径、Info.plist 路径。
  - 更新 `Makefile` 的 SwiftLint 路径。
  - 更新 `docs/RELEASE_WORKFLOW.md` 中的旧路径与命令。
- 文档：
  - 更新 `README.md` 和 `README.zh-CN.md` 的 Xcode build/open 命令。
  - 不更新历史 `plans/` 文件，避免改动旧记录。
- 保留兼容：
  - `AppMigrationHelper` 中的 legacy bundle 名单继续包含 `CopilotMonitor.app`。
  - 不改变 `CFBundleDisplayName`、`CFBundleName`、`PRODUCT_NAME`、Bundle ID，它们已经正确。

## 验证
- 先运行 `make setup`。
- 确认 `xcodebuild -list -project UsageBar/UsageBar.xcodeproj` 显示：
  - project: `UsageBar`
  - schemes: `UsageBar`、`usagebar-cli`
  - targets: `UsageBar`、`usagebar-cli`、`UsageBarTests`
- 清理并编译：
  - `xcodebuild clean build -project UsageBar/UsageBar.xcodeproj -scheme UsageBar -configuration Debug`
- 测试：
  - `xcodebuild test -project UsageBar/UsageBar.xcodeproj -scheme UsageBar -configuration Debug`
- 运行检查：
  - 结束旧进程，运行新构建的 `UsageBar.app`
  - 通过日志确认 App 正常启动，无旧 project/scheme 路径导致的错误
- 搜索检查：
  - `rg "CopilotMonitor" .` 只允许出现在 `plans/` 历史文件和 `AppMigrationHelper` legacy 名单中。

## 默认与假设
- 推荐并采用完整统一方案。
- `plans/` 目录视为历史记录，不参与本次改名。
- `CopilotMonitor.app` 作为旧版兼容名称保留，不视为遗漏。
- 不做发布、不创建 release、不修改版本号。
