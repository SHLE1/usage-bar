import AppKit

extension StatusBarController {
    private var orderedQuotaProvidersForStatusBar: [ProviderIdentifier] {
        let selectedProviders = Set(multiProviderSelection)
        let settingsOrder = AppPreferences.shared.statusBarSettingsOrder(
            for: .subscription,
            providers: AppPreferences.statusBarSubscriptionProviders
        )
        return settingsOrder.filter { selectedProviders.contains($0) }
    }

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
        let orderedSelection = orderedQuotaProvidersForStatusBar
        debugLog("updateMultiProviderBarView: orderedSelection=[\(orderedSelection.map { $0.rawValue }.joined(separator: ", "))]")

        var entries: [MultiProviderBarView.Entry] = []
        for identifier in orderedSelection {
            guard isProviderEnabled(identifier),
                  let icon = iconForProvider(identifier)
            else { continue }

            guard let result = providerResults[identifier],
                  case .quotaBased = result.usage
            else {
                if let errorMessage = lastProviderErrors[identifier],
                   ProviderDisplayPolicy.shouldShowStatusBarError(errorMessage: errorMessage) {
                    entries.append(
                        MultiProviderBarView.Entry(
                            icon: icon,
                            displayText: "Err",
                            emphasisRemainingPercent: 0
                        )
                    )
                    debugLog("updateMultiProviderBarView: showing error state for \(identifier.displayName)")
                }
                continue
            }

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
