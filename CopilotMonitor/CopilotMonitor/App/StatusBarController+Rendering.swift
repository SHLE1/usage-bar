import AppKit

extension StatusBarController {
    func updateStatusBarText() {
        if isMainMenuTracking {
            hasDeferredStatusBarRefresh = true
            debugLog("updateStatusBarText: deferred while menu is open")
            return
        }
        hasDeferredStatusBarRefresh = false

        let criticalCandidate = mostCriticalProvider()
        let shouldShowCriticalBadge = criticalBadgeEnabled && criticalCandidate != nil
        statusBarIconView?.setCriticalBadgeVisible(shouldShowCriticalBadge)

        attachActiveStatusBarView()
        updateMultiProviderBarView()
    }

    func updateMultiProviderBarView() {
        var entries: [MultiProviderBarView.Entry] = []
        for identifier in multiProviderSelection {
            guard isProviderEnabled(identifier),
                  let result = providerResults[identifier],
                  case .quotaBased = result.usage,
                  let icon = iconForProvider(identifier)
            else { continue }

            if identifier == .codex,
               let selectedAccount = resolvedCodexStatusBarAccount(from: result) {
                entries.append(
                    MultiProviderBarView.Entry(
                        icon: icon,
                        displayText: codexStatusBarText(for: selectedAccount, compact: true),
                        emphasisRemainingPercent: codexStatusBarEmphasisRemainingPercent(for: selectedAccount)
                    )
                )
                continue
            }

            let usedPercent = preferredUsedPercentForStatusBar(identifier: identifier, result: result)
                ?? result.usage.usagePercentage
            let remainingPercent = max(0.0, 100.0 - usedPercent)
            entries.append(
                MultiProviderBarView.Entry(
                    icon: icon,
                    displayText: UsagePercentDisplayFormatter.string(from: remainingPercent),
                    emphasisRemainingPercent: remainingPercent
                )
            )
        }
        debugLog("updateMultiProviderBarView: \(entries.count) provider(s)")
        multiProviderBarView?.update(entries: entries)
        updateStatusItemLayout(reason: "multi-provider-update")
    }
}
