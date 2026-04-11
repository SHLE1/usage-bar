## UI/UX Priority Plan for UsageBar

### Summary
以当前代码和你新截图来看，最该先做的不是重画，而是把“改设置时的反馈”补齐，把“主菜单一眼判断异常”的负担降下来，同时保留你已经定下的高密度信息风格和固定菜单结构。

### Priority 1
- 在 [StatusBarSettingsView.swift](/Users/hypered/Github/usage-bar/CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift:17) 增加实时预览卡片。
  目标：用户勾选 Provider 时，立刻看到顶部栏会显示什么，以及主菜单两组里会出现哪些项。
  原因：当前页只有开关，没有结果反馈；这是最大 UX 缺口。
- 复用现有状态栏呈现方式，而不是做新样式。
  直接参考 [MultiProviderBarView.swift](/Users/hypered/Github/usage-bar/CopilotMonitor/CopilotMonitor/Views/MultiProviderBarView.swift:5) 和 [StatusBarController.swift](/Users/hypered/Github/usage-bar/CopilotMonitor/CopilotMonitor/App/StatusBarController.swift:1506) 的显示规则，做一个静态预览版。
- 预览里只显示 3 类信息。
  顶部栏预览、一级菜单里的 `Pay-as-you-go` 列表、一级菜单里的 `Quota Status` 列表。
  不显示二级菜单细节，避免设置页变成第二个主菜单。

### Priority 2
- 把二级菜单内容改成更明确的分段，而不是连续堆叠。
  重点整理 [ProviderMenuBuilder.swift](/Users/hypered/Github/usage-bar/CopilotMonitor/CopilotMonitor/Helpers/ProviderMenuBuilder.swift:1423) 生成的 `usage + pace + reset` 区块，以及各 Provider 的 `Plan / Account / Token From` 区块。
- 分段顺序统一成固定模板。
  `Usage`
  `Plan`
  `Account`
  `Token From`
  不是每个 Provider 都要四段，但顺序保持一致。
- 分段标题继续用现有的 header 风格，不引入新视觉语言。
  直接复用 [StatusBarController.swift](/Users/hypered/Github/usage-bar/CopilotMonitor/CopilotMonitor/App/StatusBarController.swift:2967) 的 `createHeaderView`。
- `Settings` 页的卡片层级再拉开一点。
  [SettingsScaffold.swift](/Users/hypered/Github/usage-bar/CopilotMonitor/CopilotMonitor/App/Settings/SettingsScaffold.swift:39) 现在三个卡片权重几乎一样。
  建议把 `Additional Cost Items` 弱化成补充区块，不要和两类主 Provider 同权重。
- `Status Bar` 页里的已启用项更明显。
  [StatusBarSettingsView.swift](/Users/hypered/Github/usage-bar/CopilotMonitor/CopilotMonitor/App/Settings/StatusBarSettingsView.swift:66) 已经把 enabled 排前面，这是对的。
  再补一个小结行，例如 `Showing 4 providers in the status bar`，会比纯勾选清单更明确。

### Public Changes
- Settings 的 `Status Bar` 页会新增一个预览区，但不改变现有 tab 结构。
- 一级菜单会缩短多账号名称显示方式，但不改变分组标题、不改变 `left` 文案规则。
- 二级菜单会统一分段顺序，但不删现有信息。

### Test Plan
- 在 `Status Bar` 页开启和关闭 Provider，预览内容必须立刻变化，且顺序与真实主菜单一致。
- 多账号 ChatGPT、Copilot、Gemini 在一级菜单中不再出现完整邮箱，但进入二级菜单后仍能看到完整账号信息。
- 一级菜单仍保留现有两大分组和 `Predicted EOM` 的位置逻辑，不破坏既有设计决策。
- 二级菜单中 `Usage / Plan / Account / Token From` 的顺序对所有支持这些信息的 Provider 保持一致。
- 深色与浅色模式下，预览区和真实菜单都保持可读，不新增强调色滥用。

### Assumptions
- 不改 `Pay-as-you-go`、`Quota Status`、`Predicted EOM` 这些你已定下的标题格式。
- 不改固定的菜单信息密度路线，只做扫读效率优化。
- `Status Bar` 设置页的预览是只读预览，不承载真实交互。
