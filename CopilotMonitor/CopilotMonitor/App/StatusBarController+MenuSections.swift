import AppKit
import os.log

private let statusBarMenuLogger = Logger(subsystem: "com.opencodeproviders", category: "StatusBarController")

extension StatusBarController {
    private enum ErrorMenuStatus {
        case rateLimited
        case noCredentials
        case noSubscription
        case error

        var title: String {
            switch self {
            case .rateLimited:
                return L("Rate limited")
            case .noCredentials:
                return L("No Credentials")
            case .noSubscription:
                return L("No Subscription")
            case .error:
                return L("Error")
            }
        }

        var shouldDeferToBottom: Bool {
            switch self {
            case .rateLimited, .error:
                return false
            case .noCredentials, .noSubscription:
                return true
            }
        }

        var shouldDisplayInList: Bool {
            switch self {
            case .noCredentials:
                return false
            case .rateLimited, .noSubscription, .error:
                return true
            }
        }

        var shouldDisableListItem: Bool {
            switch self {
            case .rateLimited, .error:
                return true
            case .noCredentials, .noSubscription:
                return false
            }
        }
    }

    func updateMultiProviderMenu() {
        debugLog("updateMultiProviderMenu: started")
        if isMainMenuTracking {
            hasDeferredMenuRebuild = true
            hasDeferredStatusBarRefresh = true
            debugLog("updateMultiProviderMenu: deferred while menu is open")
            return
        }
        hasDeferredMenuRebuild = false

        guard let separatorIndex = menu.items.firstIndex(where: { $0.isSeparatorItem }) else {
            debugLog("updateMultiProviderMenu: no separator found, returning")
            return
        }
        debugLog("updateMultiProviderMenu: separatorIndex=\(separatorIndex)")

        var itemsToRemove: [NSMenuItem] = []
        let startIndex = separatorIndex + 1
        if startIndex < menu.items.count {
            for i in startIndex..<menu.items.count where menu.items[i].tag == 999 {
                itemsToRemove.append(menu.items[i])
            }
        }
        debugLog("updateMultiProviderMenu: removing \(itemsToRemove.count) old items")
        itemsToRemove.forEach { menu.removeItem($0) }

        debugLog("updateMultiProviderMenu: providerResults.count=\(providerResults.count)")
        if !providerResults.isEmpty {
            let providerNames = providerResults.keys.map { $0.rawValue }.joined(separator: ", ")
            debugLog("updateMultiProviderMenu: providers=[\(providerNames)]")
        }

        guard !providerResults.isEmpty else {
            debugLog("updateMultiProviderMenu: no data, returning")
            updateStatusBarDisplayMenuState()
            updateStatusBarText()
            return
        }

        var insertIndex = separatorIndex + 1
        let payAsYouGoTotal = calculatePayAsYouGoTotal(providerResults: providerResults, copilotUsage: currentUsage)
        let subscriptionTotal = SubscriptionSettingsManager.shared.getTotalMonthlySubscriptionCost()

        let payAsYouGoSectionStartIndex = insertIndex
        let separator1 = NSMenuItem.separator()
        separator1.tag = 999
        menu.insertItem(separator1, at: insertIndex)
        insertIndex += 1

        let payAsYouGoHeader = NSMenuItem()
        payAsYouGoHeader.view = createHeaderView(title: String(format: L("Pay-as-you-go: $%.2f"), payAsYouGoTotal))
        payAsYouGoHeader.tag = 999
        menu.insertItem(payAsYouGoHeader, at: insertIndex)
        insertIndex += 1

        var hasPayAsYouGo = false
        let payAsYouGoOrder = AppPreferences.shared.payAsYouGoSettingsItemOrder(
            providers: [.openRouter, .openCode]
        ).compactMap(ProviderIdentifier.init(rawValue:))
        debugLog("updateMultiProviderMenu: pay-as-you-go order=[\(payAsYouGoOrder.map { $0.rawValue }.joined(separator: ", "))]")
        for identifier in payAsYouGoOrder {
            guard isProviderEnabled(identifier) else { continue }

            let result = providerResults[identifier]
            let errorMessage = lastProviderErrors[identifier]

            if let errorMessage, shouldDisplayErrorStateEvenWithResult(errorMessage) {
                hasPayAsYouGo = true
                let item = createErrorMenuItem(identifier: identifier, errorMessage: errorMessage)
                if item.isEnabled {
                    item.submenu = createErrorSubmenu(identifier: identifier, result: result, errorMessage: errorMessage)
                }
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            } else if let result {
                if case .payAsYouGo(_, let cost, _) = result.usage {
                    hasPayAsYouGo = true
                    let costValue = cost ?? 0.0
                    let item = NSMenuItem(
                        title: String(format: L("%@ ($%.2f)"), identifier.displayName, costValue),
                        action: nil,
                        keyEquivalent: ""
                    )
                    item.image = iconForProvider(identifier)
                    item.tag = 999

                    if let details = result.details, details.hasAnyValue {
                        item.submenu = createDetailSubmenu(details, identifier: identifier)
                    }

                    menu.insertItem(item, at: insertIndex)
                    insertIndex += 1
                }
            } else if let errorMessage {
                guard shouldDisplayErrorMenuItem(errorMessage) else {
                    debugLog("updateMultiProviderMenu: hiding \(identifier.displayName) pay-as-you-go row because credentials are unavailable")
                    continue
                }
                hasPayAsYouGo = true
                let item = createErrorMenuItem(identifier: identifier, errorMessage: errorMessage)
                if item.isEnabled {
                    item.submenu = createErrorSubmenu(identifier: identifier, result: nil, errorMessage: errorMessage)
                }
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            } else if loadingProviders.contains(identifier) {
                hasPayAsYouGo = true
                let item = NSMenuItem(title: String(format: L("%@ (Loading...)"), identifier.displayName), action: nil, keyEquivalent: "")
                item.image = iconForProvider(identifier)
                item.isEnabled = false
                item.tag = 999
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            }
        }

        if isProviderEnabled(.copilot) && isCopilotAddOnEnabled {
            if let copilotResult = providerResults[.copilot],
               let details = copilotResult.details,
               let overageCost = details.copilotOverageCost {
                hasPayAsYouGo = true
                let addOnItem = NSMenuItem(
                    title: String(format: L("Copilot Add-on ($%.2f)"), overageCost),
                    action: nil,
                    keyEquivalent: ""
                )
                addOnItem.image = iconForProvider(.copilot)
                addOnItem.tag = 999

                let submenu = NSMenu()
                let overageRequests = details.copilotOverageRequests ?? 0
                let overageItem = NSMenuItem()
                overageItem.view = createDisabledLabelView(text: String(format: L("Overage Requests: %.0f"), overageRequests))
                submenu.addItem(overageItem)

                submenu.addItem(NSMenuItem.separator())
                let historyItem = NSMenuItem(title: L("Usage History"), action: nil, keyEquivalent: "")
                historyItem.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Usage History")
                debugLog("updateMultiProviderMenu: calling createCopilotHistorySubmenu")
                historyItem.submenu = createCopilotHistorySubmenu()
                debugLog("updateMultiProviderMenu: createCopilotHistorySubmenu completed")
                submenu.addItem(historyItem)

                submenu.addItem(NSMenuItem.separator())

                if let email = details.email {
                    let emailItem = NSMenuItem()
                    emailItem.view = createDisabledLabelView(
                        text: String(format: L("Account: %@"), email),
                        icon: NSImage(systemSymbolName: "person.circle", accessibilityDescription: "User Account"),
                        multiline: false
                    )
                    submenu.addItem(emailItem)
                }

                if let authSource = details.authSource {
                    let authItem = NSMenuItem()
                    authItem.view = createDisabledLabelView(
                        text: String(format: L("Token From: %@"), authSource),
                        icon: NSImage(systemSymbolName: "key", accessibilityDescription: "Auth Source"),
                        multiline: true
                    )
                    submenu.addItem(authItem)
                }

                addOnItem.submenu = submenu
                menu.insertItem(addOnItem, at: insertIndex)
                insertIndex += 1
                debugLog("updateMultiProviderMenu: Copilot Add-on inserted with cost $\(overageCost)")
            } else if loadingProviders.contains(.copilot) {
                hasPayAsYouGo = true
                let item = NSMenuItem(title: L("Copilot Add-on (Loading...)"), action: nil, keyEquivalent: "")
                item.image = iconForProvider(.copilot)
                item.isEnabled = false
                item.tag = 999
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            }
        }

        if hasPayAsYouGo {
            insertIndex = insertPredictedEOMSection(at: insertIndex)
        } else {
            debugLog("updateMultiProviderMenu: hiding pay-as-you-go section because no visible items were generated")
            while insertIndex > payAsYouGoSectionStartIndex {
                insertIndex -= 1
                menu.removeItem(at: insertIndex)
            }
        }

        let quotaSectionStartIndex = insertIndex
        let separator2 = NSMenuItem.separator()
        separator2.tag = 999
        menu.insertItem(separator2, at: insertIndex)
        insertIndex += 1

        let quotaHeader = NSMenuItem()
        let quotaTitle = subscriptionTotal > 0
            ? String(format: L("Quota Status: $%.0f/m"), subscriptionTotal)
            : L("Quota Status")
        quotaHeader.view = createHeaderView(title: quotaTitle)
        quotaHeader.tag = 999
        menu.insertItem(quotaHeader, at: insertIndex)
        insertIndex += 1

        var hasQuota = false
        var deferredUnavailableItems: [NSMenuItem] = []
        var deferredUnavailableProviders: [ProviderIdentifier] = []

        if isProviderEnabled(.copilot),
           let copilotResult = providerResults[.copilot],
           let accounts = copilotResult.accounts,
           !accounts.isEmpty {
            let copilotAuthLabels = Set(
                accounts.map { account in
                    authSourceLabel(for: account.details?.authSource, provider: .copilot) ?? L("Unknown")
                }
            )
            let showCopilotAuthLabel = copilotAuthLabels.count > 1
            let baseName = multiAccountBaseName(for: .copilot)
            for account in accounts {
                hasQuota = true
                let accountIdentifier: String
                if let accountId = account.accountId?.trimmingCharacters(in: .whitespacesAndNewlines), !accountId.isEmpty {
                    accountIdentifier = accountId
                } else {
                    accountIdentifier = "#\(account.accountIndex + 1)"
                }
                var displayName = accounts.count > 1 ? "\(baseName) (\(accountIdentifier))" : baseName
                if accounts.count > 1, showCopilotAuthLabel {
                    let sourceLabel = authSourceLabel(for: account.details?.authSource, provider: .copilot) ?? L("Unknown")
                    displayName += " - \(sourceLabel)"
                }
                let unavailableLabel = unavailableUsageSuffix(for: account, identifier: .copilot)
                if let unavailableLabel {
                    displayName += " (\(unavailableLabel))"
                }
                let isUnavailableRateLimited = unavailableLabel == L("Rate limited")
                let quotaItem = createNativeQuotaMenuItem(
                    name: displayName,
                    usedPercent: account.usage.usagePercentage,
                    icon: iconForProvider(.copilot),
                    isEnabled: !isUnavailableRateLimited
                )
                quotaItem.tag = 999

                if quotaItem.isEnabled,
                   let details = account.details,
                   details.hasAnyValue {
                    quotaItem.submenu = createDetailSubmenu(details, identifier: .copilot, accountId: account.subscriptionId)
                }

                menu.insertItem(quotaItem, at: insertIndex)
                insertIndex += 1
            }
        } else if isProviderEnabled(.copilot), let copilotUsage = currentUsage {
            hasQuota = true
            let limit = copilotUsage.userPremiumRequestEntitlement
            let used = copilotUsage.usedRequests
            let usedPercent = limit > 0 ? (Double(used) / Double(limit)) * 100 : 0

            let quotaItem = createNativeQuotaMenuItem(
                name: ProviderIdentifier.copilot.displayName,
                usedPercent: usedPercent,
                icon: iconForProvider(.copilot)
            )
            quotaItem.tag = 999

            if let details = providerResults[.copilot]?.details, details.hasAnyValue {
                quotaItem.submenu = createDetailSubmenu(details, identifier: .copilot)
            } else {
                let submenu = NSMenu()
                let filledBlocks = Int((Double(used) / Double(max(limit, 1))) * 10)
                let emptyBlocks = 10 - filledBlocks
                let progressBar = String(repeating: "═", count: filledBlocks) + String(repeating: "░", count: emptyBlocks)
                let progressItem = NSMenuItem()
                progressItem.view = createDisabledLabelView(text: "[\(progressBar)] \(used)/\(limit)")
                submenu.addItem(progressItem)

                let usedItem = NSMenuItem()
                usedItem.view = createDisabledLabelView(text: String(format: L("Monthly Usage: %.0f%%"), usedPercent))
                submenu.addItem(usedItem)

                if let resetDate = copilotUsage.quotaResetDateUTC {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    formatter.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
                    let paceInfo = calculateMonthlyPace(usagePercent: usedPercent, resetDate: resetDate)
                    let paceItem = NSMenuItem()
                    paceItem.view = createPaceView(paceInfo: paceInfo)
                    submenu.addItem(paceItem)

                    let resetItem = NSMenuItem()
                    resetItem.view = createDisabledLabelView(
                        text: String(format: L("Resets: %@ UTC"), formatter.string(from: resetDate)),
                        indent: 0,
                        textColor: .secondaryLabelColor
                    )
                    submenu.addItem(resetItem)
                    debugLog("updateMultiProviderMenu: reset row tone aligned with pace text for copilot fallback")
                }

                submenu.addItem(NSMenuItem.separator())

                if let planName = copilotUsage.planDisplayName {
                    let planItem = NSMenuItem()
                    planItem.view = createDisabledLabelView(
                        text: String(format: L("Plan: %@"), planName),
                        icon: NSImage(systemSymbolName: "crown", accessibilityDescription: "Plan")
                    )
                    submenu.addItem(planItem)
                }

                let freeItem = NSMenuItem()
                freeItem.view = createDisabledLabelView(text: String(format: L("Quota Limit: %@"), String(limit)))
                submenu.addItem(freeItem)

                submenu.addItem(NSMenuItem.separator())

                if let email = providerResults[.copilot]?.details?.email {
                    let emailItem = NSMenuItem()
                    emailItem.view = createDisabledLabelView(
                        text: String(format: L("Email: %@"), email),
                        icon: NSImage(systemSymbolName: "person.circle", accessibilityDescription: "User Email"),
                        multiline: false
                    )
                    submenu.addItem(emailItem)
                }

                let authItem = NSMenuItem()
                authItem.view = createDisabledLabelView(
                    text: String(format: L("Token From: %@"), "Browser Cookies (Chrome/Brave/Arc/Edge)"),
                    icon: NSImage(systemSymbolName: "key", accessibilityDescription: "Auth Source"),
                    multiline: true
                )
                submenu.addItem(authItem)

                quotaItem.submenu = submenu
            }

            menu.insertItem(quotaItem, at: insertIndex)
            insertIndex += 1
        }

        let quotaOrder = AppPreferences.shared.statusBarSettingsOrder(
            for: .subscription,
            providers: [.claude, .kimi, .minimaxCodingPlan, .codex, .zaiCodingPlan, .nanoGpt, .antigravity, .chutes, .synthetic]
        )
        debugLog("updateMultiProviderMenu: quota order=[\(quotaOrder.map { $0.rawValue }.joined(separator: ", "))]")
        for identifier in quotaOrder {
            guard isProviderEnabled(identifier) else { continue }

            let result = providerResults[identifier]
            let errorMessage = lastProviderErrors[identifier]

            if let errorMessage,
               shouldDisplayErrorStateEvenWithResult(errorMessage, identifier: identifier, result: result) {
                hasQuota = true
                let item = createErrorMenuItem(identifier: identifier, errorMessage: errorMessage)
                if item.isEnabled {
                    item.submenu = createErrorSubmenu(identifier: identifier, result: result, errorMessage: errorMessage)
                }
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            } else if let result {
                if let accounts = result.accounts, !accounts.isEmpty {
                    let authLabels = Set(
                        accounts.map { account in
                            authSourceLabel(for: account.details?.authSource, provider: identifier) ?? "Unknown"
                        }
                    )
                    let showAuthLabel = authLabels.count > 1
                    let baseName = multiAccountBaseName(for: identifier)
                    let codexEmailByAccountId: [String: String]
                    if identifier == .codex {
                        codexEmailByAccountId = Dictionary(
                            uniqueKeysWithValues: TokenManager.shared.getOpenAIAccounts().compactMap { account in
                                guard let accountId = account.accountId?.trimmingCharacters(in: .whitespacesAndNewlines),
                                      !accountId.isEmpty,
                                      let email = account.email?.trimmingCharacters(in: .whitespacesAndNewlines),
                                      !email.isEmpty else {
                                    return nil
                                }
                                return (accountId, email)
                            }
                        )
                    } else {
                        codexEmailByAccountId = [:]
                    }

                    for account in accounts {
                        hasQuota = true
                        var displayName = accounts.count > 1 ? "\(baseName) #\(account.accountIndex + 1)" : baseName

                        let detailsEmail = account.details?.email?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let accountEmail: String?
                        if identifier == .claude, let detailsEmail, !detailsEmail.isEmpty {
                            accountEmail = detailsEmail
                        } else if identifier == .codex, let detailsEmail, !detailsEmail.isEmpty {
                            accountEmail = detailsEmail
                        } else if identifier == .codex,
                                  let accountId = account.accountId?.trimmingCharacters(in: .whitespacesAndNewlines),
                                  !accountId.isEmpty,
                                  let mappedEmail = codexEmailByAccountId[accountId],
                                  !mappedEmail.isEmpty {
                            accountEmail = mappedEmail
                        } else if identifier == .codex,
                                  let fallbackEmail = codexEmailByAccountId.values.first,
                                  accounts.count == 1 {
                            accountEmail = fallbackEmail
                        } else {
                            accountEmail = nil
                        }

                        if let accountEmail {
                            if accounts.count > 1 {
                                displayName += " (\(accountEmail))"
                            } else {
                                displayName = "\(baseName) (\(accountEmail))"
                            }
                        } else if accounts.count > 1, showAuthLabel {
                            let sourceLabel = authSourceLabel(for: account.details?.authSource, provider: identifier) ?? "Unknown"
                            displayName += " (\(sourceLabel))"
                        }

                        let unavailableLabel = unavailableUsageSuffix(for: account, identifier: identifier)
                        if let unavailableLabel {
                            displayName += " (\(unavailableLabel))"
                        }
                        let isUnavailableRateLimited = unavailableLabel == L("Rate limited")

                        let usedPercents: [Double]
                        if identifier == .claude,
                           let details = account.details,
                           let fiveHour = details.fiveHourUsage,
                           let sevenDay = details.sevenDayUsage {
                            var percents = [fiveHour, sevenDay]
                            if let sonnetUsage = details.sonnetUsage {
                                percents.append(sonnetUsage)
                            }
                            usedPercents = percents
                        } else if identifier == .minimaxCodingPlan,
                                  let fiveHour = account.details?.fiveHourUsage,
                                  let sevenDay = account.details?.sevenDayUsage {
                            usedPercents = [fiveHour, sevenDay]
                        } else if identifier == .kimi,
                                  let fiveHour = account.details?.fiveHourUsage,
                                  let sevenDay = account.details?.sevenDayUsage {
                            usedPercents = [fiveHour, sevenDay]
                        } else if identifier == .codex {
                            var percents = [account.usage.usagePercentage]
                            if let secondary = account.details?.secondaryUsage {
                                percents.append(secondary)
                            }
                            if let sparkPrimary = account.details?.sparkUsage {
                                percents.append(sparkPrimary)
                            }
                            if let sparkSecondary = account.details?.sparkSecondaryUsage {
                                percents.append(sparkSecondary)
                            }
                            usedPercents = percents
                        } else if identifier == .zaiCodingPlan {
                            let percents = [account.details?.tokenUsagePercent, account.details?.mcpUsagePercent].compactMap { $0 }
                            usedPercents = percents.isEmpty ? [account.usage.usagePercentage] : percents
                        } else if identifier == .chutes {
                            let percents = [dailyPercentFromDetails(account.details), chutesMonthlyPercentFromDetails(account.details)].compactMap { $0 }
                            usedPercents = percents.isEmpty ? [account.usage.usagePercentage] : percents
                        } else if identifier == .nanoGpt {
                            let percents = [
                                account.details?.sevenDayUsage,
                                account.details?.tokenUsagePercent,
                                account.details?.mcpUsagePercent
                            ].compactMap { $0 }
                            usedPercents = percents.isEmpty ? [account.usage.usagePercentage] : percents
                        } else {
                            usedPercents = [account.usage.usagePercentage]
                        }

                        let item = createNativeQuotaMenuItem(
                            name: displayName,
                            usedPercents: usedPercents,
                            icon: iconForProvider(identifier),
                            isEnabled: !isUnavailableRateLimited
                        )
                        item.tag = 999

                        if item.isEnabled,
                           let details = account.details,
                           details.hasAnyValue {
                            item.submenu = createDetailSubmenu(details, identifier: identifier, accountId: account.subscriptionId)
                        }

                        menu.insertItem(item, at: insertIndex)
                        insertIndex += 1
                    }
                } else if case .quotaBased(let remaining, let entitlement, _) = result.usage {
                    hasQuota = true
                    let singlePercent = entitlement > 0 ? (Double(entitlement - remaining) / Double(entitlement)) * 100 : 0

                    let usedPercents: [Double]
                    if identifier == .claude,
                       let details = result.details,
                       let fiveHour = details.fiveHourUsage,
                       let sevenDay = details.sevenDayUsage {
                        var percents = [fiveHour, sevenDay]
                        if let sonnetUsage = details.sonnetUsage {
                            percents.append(sonnetUsage)
                        }
                        usedPercents = percents
                    } else if identifier == .minimaxCodingPlan,
                              let fiveHour = result.details?.fiveHourUsage,
                              let sevenDay = result.details?.sevenDayUsage {
                        usedPercents = [fiveHour, sevenDay]
                    } else if identifier == .kimi,
                              let fiveHour = result.details?.fiveHourUsage,
                              let sevenDay = result.details?.sevenDayUsage {
                        usedPercents = [fiveHour, sevenDay]
                    } else if identifier == .codex {
                        var percents = [singlePercent]
                        if let secondary = result.details?.secondaryUsage {
                            percents.append(secondary)
                        }
                        if let sparkPrimary = result.details?.sparkUsage {
                            percents.append(sparkPrimary)
                        }
                        if let sparkSecondary = result.details?.sparkSecondaryUsage {
                            percents.append(sparkSecondary)
                        }
                        usedPercents = percents
                    } else if identifier == .zaiCodingPlan {
                        let percents = [result.details?.tokenUsagePercent, result.details?.mcpUsagePercent].compactMap { $0 }
                        usedPercents = percents.isEmpty ? [singlePercent] : percents
                    } else if identifier == .chutes {
                        let percents = [dailyPercentFromDetails(result.details), chutesMonthlyPercentFromDetails(result.details)].compactMap { $0 }
                        usedPercents = percents.isEmpty ? [singlePercent] : percents
                    } else if identifier == .nanoGpt {
                        let percents = [
                            result.details?.sevenDayUsage,
                            result.details?.tokenUsagePercent,
                            result.details?.mcpUsagePercent
                        ].compactMap { $0 }
                        usedPercents = percents.isEmpty ? [singlePercent] : percents
                    } else {
                        usedPercents = [singlePercent]
                    }

                    let item = createNativeQuotaMenuItem(
                        name: identifier.displayName,
                        usedPercents: usedPercents,
                        icon: iconForProvider(identifier)
                    )
                    item.tag = 999

                    if let details = result.details, details.hasAnyValue {
                        item.submenu = createDetailSubmenu(details, identifier: identifier)
                    }

                    menu.insertItem(item, at: insertIndex)
                    insertIndex += 1
                }
            } else if let errorMessage {
                guard shouldDisplayErrorMenuItem(errorMessage) else {
                    debugLog("updateMultiProviderMenu: hiding \(identifier.displayName) quota row because credentials are unavailable")
                    continue
                }
                hasQuota = true
                let item = createErrorMenuItem(identifier: identifier, errorMessage: errorMessage)
                if item.isEnabled {
                    item.submenu = createErrorSubmenu(identifier: identifier, result: nil, errorMessage: errorMessage)
                }
                let status = errorMenuStatus(for: errorMessage)
                if status.shouldDeferToBottom {
                    deferredUnavailableItems.append(item)
                    deferredUnavailableProviders.append(identifier)
                    debugLog("updateMultiProviderMenu: deferred \(status.title) item for \(identifier.displayName)")
                } else {
                    menu.insertItem(item, at: insertIndex)
                    insertIndex += 1
                }
            } else if loadingProviders.contains(identifier) {
                hasQuota = true
                let item = NSMenuItem(title: String(format: L("%@ (Loading...)"), identifier.displayName), action: nil, keyEquivalent: "")
                item.image = iconForProvider(identifier)
                item.isEnabled = false
                item.tag = 999
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            }
        }

        if isProviderEnabled(.geminiCLI) {
            let geminiResult = providerResults[.geminiCLI]
            let geminiError = lastProviderErrors[.geminiCLI]

            if let geminiError,
               shouldDisplayErrorStateEvenWithResult(geminiError, identifier: .geminiCLI, result: geminiResult) {
                hasQuota = true
                let item = createErrorMenuItem(identifier: .geminiCLI, errorMessage: geminiError)
                if item.isEnabled {
                    item.submenu = createErrorSubmenu(identifier: .geminiCLI, result: geminiResult, errorMessage: geminiError)
                }
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            } else if let result = geminiResult,
                      let details = result.details,
                      let geminiAccounts = details.geminiAccounts,
                      !geminiAccounts.isEmpty {
                let geminiAuthLabels = Set(
                    geminiAccounts.map { account in
                        authSourceLabel(for: account.authSource, provider: .geminiCLI) ?? L("Unknown")
                    }
                )
                let showGeminiAuthLabel = geminiAuthLabels.count > 1

                for account in geminiAccounts {
                    hasQuota = true
                    let accountNumber = account.accountIndex + 1
                    let usedPercent = normalizedUsagePercent(100.0 - account.remainingPercentage) ?? 0.0
                    let normalizedEmail = account.email.trimmingCharacters(in: .whitespacesAndNewlines)
                    var displayName = "Gemini CLI"

                    if !normalizedEmail.isEmpty, normalizedEmail.lowercased() != "unknown" {
                        displayName = "Gemini CLI (\(normalizedEmail))"
                    } else if geminiAccounts.count > 1, showGeminiAuthLabel {
                        displayName = "Gemini CLI #\(accountNumber)"
                        let sourceLabel = authSourceLabel(for: account.authSource, provider: .geminiCLI) ?? L("Unknown")
                        displayName += " (\(sourceLabel))"
                    } else if geminiAccounts.count > 1 {
                        displayName = "Gemini CLI #\(accountNumber)"
                    }

                    let item = createNativeQuotaMenuItem(
                        name: displayName,
                        usedPercents: [usedPercent],
                        icon: iconForProvider(.geminiCLI)
                    )
                    item.tag = 999
                    item.submenu = createGeminiAccountSubmenu(account)
                    menu.insertItem(item, at: insertIndex)
                    insertIndex += 1
                }
            } else if let errorMessage = geminiError {
                if shouldDisplayErrorMenuItem(errorMessage) {
                    hasQuota = true
                    let item = createErrorMenuItem(identifier: .geminiCLI, errorMessage: errorMessage)
                    if item.isEnabled {
                        item.submenu = createErrorSubmenu(identifier: .geminiCLI, result: nil, errorMessage: errorMessage)
                    }
                    let status = errorMenuStatus(for: errorMessage)
                    if status.shouldDeferToBottom {
                        deferredUnavailableItems.append(item)
                        deferredUnavailableProviders.append(.geminiCLI)
                        debugLog("updateMultiProviderMenu: deferred \(status.title) item for Gemini CLI")
                    } else {
                        menu.insertItem(item, at: insertIndex)
                        insertIndex += 1
                    }
                } else {
                    debugLog("updateMultiProviderMenu: hiding Gemini CLI row because credentials are unavailable")
                }
            } else if loadingProviders.contains(.geminiCLI) {
                hasQuota = true
                let item = NSMenuItem(title: String(format: L("%@ (Loading...)"), ProviderIdentifier.geminiCLI.displayName), action: nil, keyEquivalent: "")
                item.image = iconForProvider(.geminiCLI)
                item.isEnabled = false
                item.tag = 999
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            }
        }

        if !deferredUnavailableItems.isEmpty {
            let deferredNames = deferredUnavailableProviders.map { $0.displayName }.joined(separator: ", ")
            debugLog("updateMultiProviderMenu: inserting \(deferredUnavailableItems.count) deferred unavailable item(s) after Gemini: [\(deferredNames)]")
            for item in deferredUnavailableItems {
                menu.insertItem(item, at: insertIndex)
                insertIndex += 1
            }
        }

        if !hasQuota {
            debugLog("updateMultiProviderMenu: hiding quota section because no visible items were generated")
            while insertIndex > quotaSectionStartIndex {
                insertIndex -= 1
                menu.removeItem(at: insertIndex)
            }
        }

        let orphaned = calculateOrphanedSubscriptions(providerResults: providerResults)
        orphanedSubscriptionKeys = orphaned.keys
        orphanedSubscriptionTotal = orphaned.total
        if orphaned.total > 0 {
            let title = String(format: L("Orphaned ($%.2f)"), orphaned.total)
            let orphanedItem = NSMenuItem(title: title, action: #selector(confirmResetOrphanedSubscriptions(_:)), keyEquivalent: "")
            orphanedItem.target = self
            orphanedItem.attributedTitle = italicMenuTitle(title)
            orphanedItem.image = orphanedIcon()
            orphanedItem.tag = 999
            menu.insertItem(orphanedItem, at: insertIndex)
            insertIndex += 1
        }

        let hasDynamicMenuContent = insertIndex > separatorIndex + 1
        if hasDynamicMenuContent {
            let separator3 = NSMenuItem.separator()
            separator3.tag = 999
            menu.insertItem(separator3, at: insertIndex)
        } else {
            debugLog("updateMultiProviderMenu: skipping trailing dynamic separator because all dynamic sections are hidden")
        }

        let totalCost = calculateTotalWithSubscriptions(providerResults: providerResults, copilotUsage: currentUsage)
        updateStatusBarDisplayMenuState()
        updateStatusBarText()
        debugLog("updateMultiProviderMenu: completed successfully, totalCost=$\(totalCost)")
        logMenuStructure()
    }

    func logMenuStructure() {
        let total = menu.items.count
        let separators = menu.items.filter { $0.isSeparatorItem }.count
        let withAction = menu.items.filter { !$0.isSeparatorItem && $0.action != nil }.count
        let withSubmenu = menu.items.filter { $0.hasSubmenu }.count

        statusBarMenuLogger.info("📋 [Menu] Items: \(total) (sep:\(separators), actions:\(withAction), submenus:\(withSubmenu))")

        var output = "\n========== MENU STRUCTURE ==========\n"
        for (index, item) in menu.items.enumerated() {
            output += logMenuItem(item, depth: 0, index: index)
        }
        output += "====================================\n"
        debugLog(output)
    }

    private func logMenuItem(_ item: NSMenuItem, depth: Int, index: Int) -> String {
        let indent = String(repeating: "  ", count: depth)
        var line = ""

        if item.isSeparatorItem {
            line = "\(indent)[\(index)] ─────────────\n"
        } else if let view = item.view {
            let viewType = String(describing: type(of: view))
            if let label = view.subviews.compactMap({ $0 as? NSTextField }).first {
                line = "\(indent)[\(index)] [VIEW:\(viewType)] \(label.stringValue)\n"
            } else {
                line = "\(indent)[\(index)] [VIEW:\(viewType)]\n"
            }
        } else {
            line = "\(indent)[\(index)] \(item.title)\n"
        }

        if let submenu = item.submenu {
            for (subIndex, subItem) in submenu.items.enumerated() {
                line += logMenuItem(subItem, depth: depth + 1, index: subIndex)
            }
        }

        return line
    }

    func sanitizedSubscriptionKey(_ key: String) -> String {
        let parts = key.split(separator: ".")
        guard parts.count >= 3 else { return key }
        let prefix = parts.prefix(2).joined(separator: ".")
        return "\(prefix).<redacted>"
    }

    private func orphanedIcon() -> NSImage? {
        let image = NSImage(systemSymbolName: "tray.full", accessibilityDescription: L("Orphaned subscriptions"))
        image?.size = NSSize(width: MenuDesignToken.Dimension.iconSize, height: MenuDesignToken.Dimension.iconSize)
        return image
    }

    private func italicMenuTitle(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [.font: NSFontManager.shared.convert(MenuDesignToken.Typography.defaultFont, toHaveTrait: .italicFontMask)]
        )
    }

    private func providerIdentifier(for subscriptionKey: String) -> ProviderIdentifier? {
        let prefix = subscriptionKey
            .replacingOccurrences(of: "subscription_v2.", with: "")
            .split(separator: ".")
            .first
            .map(String.init)

        guard let prefix else { return nil }
        return ProviderIdentifier.allCases.first { $0.rawValue == prefix }
    }

    private func collectVisibleSubscriptionKeys(providerResults: [ProviderIdentifier: ProviderResult]) -> Set<String> {
        var keys = Set<String>()

        for (identifier, result) in providerResults {
            guard isProviderEnabled(identifier) else { continue }

            if identifier == .geminiCLI,
               let details = result.details,
               let geminiAccounts = details.geminiAccounts,
               !geminiAccounts.isEmpty {
                for account in geminiAccounts {
                    let trimmedEmail = account.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let subscriptionAccountId: String? =
                        !trimmedEmail.isEmpty ? trimmedEmail :
                        ((account.accountId?.isEmpty == false) ? account.accountId : nil)
                    let key = SubscriptionSettingsManager.shared.subscriptionKey(for: .geminiCLI, accountId: subscriptionAccountId)
                    keys.insert(key)
                }
                continue
            }

            if let accounts = result.accounts, !accounts.isEmpty {
                for account in accounts {
                    if let subId = account.subscriptionId, !subId.isEmpty {
                        keys.insert(SubscriptionSettingsManager.shared.subscriptionKey(for: identifier, accountId: subId))
                    } else {
                        keys.insert(SubscriptionSettingsManager.shared.subscriptionKey(for: identifier))
                    }
                }
            } else {
                keys.insert(SubscriptionSettingsManager.shared.subscriptionKey(for: identifier))
            }
        }

        return keys
    }

    private func calculateOrphanedSubscriptions(providerResults: [ProviderIdentifier: ProviderResult]) -> (keys: [String], total: Double) {
        let visibleKeys = collectVisibleSubscriptionKeys(providerResults: providerResults)
        let allKeys = SubscriptionSettingsManager.shared.getAllSubscriptionKeys()

        var orphaned: [String] = []
        var total = 0.0

        for key in allKeys {
            if visibleKeys.contains(key) {
                continue
            }

            if let provider = providerIdentifier(for: key) {
                if loadingProviders.contains(provider) || !isProviderEnabled(provider) || !providerResults.keys.contains(provider) {
                    continue
                }
            } else {
                let plan = SubscriptionSettingsManager.shared.getPlan(forKey: key)
                if plan.cost <= 0 {
                    continue
                }
                orphaned.append(key)
                total += plan.cost
                continue
            }

            let plan = SubscriptionSettingsManager.shared.getPlan(forKey: key)
            if plan.cost <= 0 {
                continue
            }

            orphaned.append(key)
            total += plan.cost
        }

        if orphaned.isEmpty {
            debugLog("Orphaned subscriptions: none")
        } else {
            let formattedTotal = String(format: "%.2f", total)
            let sanitizedKeys = orphaned.map { sanitizedSubscriptionKey($0) }.joined(separator: ", ")
            debugLog("Orphaned subscriptions detected: \(orphaned.count) key(s), total=$\(formattedTotal), keys=[\(sanitizedKeys)]")
        }

        return (orphaned, total)
    }

    private func multiAccountBaseName(for identifier: ProviderIdentifier) -> String {
        switch identifier {
        case .codex:
            return "ChatGPT"
        default:
            return identifier.displayName
        }
    }

    private func authSourceLabel(for authSource: String?, provider: ProviderIdentifier) -> String? {
        guard let authSource, !authSource.isEmpty else { return nil }

        func parseSingleSource(_ rawSource: String) -> String? {
            let lowercased = rawSource.lowercased()

            if lowercased.contains("opencode") {
                return "OpenCode"
            }

            switch provider {
            case .codex:
                if lowercased.contains(".codex-lb") || lowercased.contains("/codex-lb/") || lowercased.contains("codex lb") {
                    return "Codex LB"
                }
                if lowercased.contains(".codex") || lowercased.contains("/codex/") || lowercased == "codex" {
                    return "Codex"
                }
            case .claude:
                if lowercased.contains("claude code (keychain)") || lowercased.contains("keychain") {
                    return "Claude Code (Keychain)"
                }
                if lowercased.contains("claude code (legacy)") || lowercased.contains(".credentials.json") || lowercased.contains(".claude") {
                    return "Claude Code (Legacy)"
                }
                if lowercased.contains("claude-code") || lowercased.contains("claude code") {
                    return "Claude Code"
                }
            case .copilot:
                if lowercased.contains("browser cookies") {
                    return "Browser Cookies"
                }
                if lowercased.contains("github-copilot") {
                    if lowercased.contains("hosts.json") {
                        return "VS Code (hosts.json)"
                    }
                    if lowercased.contains("apps.json") {
                        return "VS Code (apps.json)"
                    }
                    return "VS Code"
                }
            case .geminiCLI:
                if lowercased.contains("antigravity") {
                    return "Antigravity"
                }
                if lowercased.contains(".gemini/oauth_creds.json")
                    || lowercased.contains("/.gemini/oauth_creds.json")
                    || lowercased.contains("oauth_creds.json") {
                    return "Gemini CLI"
                }
            default:
                break
            }

            if lowercased.contains("keychain") {
                return "Keychain"
            }

            return nil
        }

        let parts = authSource
            .components(separatedBy: CharacterSet(charactersIn: ",;|"))
            .flatMap { $0.components(separatedBy: " + ") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let sourceParts = parts.isEmpty ? [authSource] : parts
        var labels: [String] = []
        for part in sourceParts {
            guard let label = parseSingleSource(part), !labels.contains(label) else { continue }
            labels.append(label)
        }

        if labels.isEmpty {
            return parseSingleSource(authSource)
        }
        if labels.count == 1 {
            return labels.first
        }
        return labels.joined(separator: " + ")
    }

    private func colorForRemainingPercent(_ remaining: Double) -> NSColor {
        if remaining <= 10 {
            return .systemRed
        } else if remaining <= 30 {
            return .systemOrange
        } else {
            return .secondaryLabelColor
        }
    }

    private func createNativeQuotaMenuItem(
        name: String,
        usedPercents: [Double],
        icon: NSImage?,
        isEnabled: Bool = true
    ) -> NSMenuItem {
        let attributed = NSMutableAttributedString()
        let primaryColor = isEnabled ? NSColor.labelColor : NSColor.disabledControlTextColor
        let secondaryColor = isEnabled ? NSColor.secondaryLabelColor : NSColor.disabledControlTextColor

        attributed.append(NSAttributedString(
            string: "\(name)",
            attributes: [.font: MenuDesignToken.Typography.defaultFont, .foregroundColor: primaryColor]
        ))

        let defaultFontUsagePercent: NSFont = MenuDesignToken.Typography.monospacedFont
        attributed.append(NSAttributedString(
            string: ": ",
            attributes: [.font: defaultFontUsagePercent, .foregroundColor: secondaryColor]
        ))

        for (index, usedPercent) in usedPercents.enumerated() {
            let remainingPercent = max(0.0, 100.0 - usedPercent)
            let percentText = UsagePercentDisplayFormatter.string(from: remainingPercent)
            let percentColor = isEnabled ? colorForRemainingPercent(remainingPercent) : NSColor.disabledControlTextColor
            let font: NSFont = isEnabled && usedPercent >= 100
                ? MenuDesignToken.Typography.monospacedBoldFont
                : defaultFontUsagePercent

            attributed.append(NSAttributedString(
                string: percentText,
                attributes: [.font: font, .foregroundColor: percentColor]
            ))

            if index < usedPercents.count - 1 {
                attributed.append(NSAttributedString(
                    string: ", ",
                    attributes: [.font: defaultFontUsagePercent, .foregroundColor: secondaryColor]
                ))
            }
        }

        attributed.append(NSAttributedString(
            string: L(" left"),
            attributes: [.font: defaultFontUsagePercent, .foregroundColor: secondaryColor]
        ))

        let item = NSMenuItem()
        item.attributedTitle = attributed
        item.image = icon
        item.isEnabled = isEnabled

        if let icon {
            if !isEnabled {
                item.image = tintedImage(icon, color: .disabledControlTextColor)
            } else {
                let minRemaining = usedPercents.map { max(0.0, 100.0 - $0) }.min() ?? 100.0
                if minRemaining <= 30 {
                    let iconColor: NSColor = minRemaining <= 10 ? .systemRed : .systemOrange
                    item.image = tintedImage(icon, color: iconColor)
                }
            }
        }

        return item
    }

    private func createNativeQuotaMenuItem(
        name: String,
        usedPercent: Double,
        icon: NSImage?,
        isEnabled: Bool = true
    ) -> NSMenuItem {
        createNativeQuotaMenuItem(name: name, usedPercents: [usedPercent], icon: icon, isEnabled: isEnabled)
    }

    private func unavailableUsageSuffix(for account: ProviderAccountResult, identifier: ProviderIdentifier) -> String? {
        guard (account.usage.totalEntitlement ?? 0) == 0 else { return nil }

        if identifier == .claude,
           let authErrorMessage = account.details?.authErrorMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
           !authErrorMessage.isEmpty,
           authErrorMessage.lowercased().contains("token expired") {
            return L("Token expired")
        }

        if identifier == .claude,
           let authErrorMessage = account.details?.authErrorMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
           !authErrorMessage.isEmpty,
           authErrorMessage.lowercased().contains("rate limited") {
            return L("Rate limited")
        }

        return L("No usage data")
    }

    private func isAuthenticationError(_ errorMessage: String) -> Bool {
        let authPatterns = [
            "Authentication failed",
            "not found",
            "not available",
            "access token",
            "API key",
            "No Gemini accounts",
            "credentials"
        ]
        let lowercased = errorMessage.lowercased()
        return authPatterns.contains { lowercased.contains($0.lowercased()) }
    }

    private func isRateLimitError(_ errorMessage: String) -> Bool {
        let lowercased = errorMessage.lowercased()
        return lowercased.contains("rate limited")
            || lowercased.contains("rate_limit_error")
            || lowercased.contains("http 429")
            || lowercased.contains("too many requests")
    }

    private func errorMenuStatus(for errorMessage: String) -> ErrorMenuStatus {
        let lowercased = errorMessage.lowercased()
        if isRateLimitError(errorMessage) {
            return .rateLimited
        }
        if lowercased.contains("subscription") {
            return .noSubscription
        }
        if isAuthenticationError(errorMessage) {
            return .noCredentials
        }
        return .error
    }

    private func shouldDisplayErrorStateEvenWithResult(_ errorMessage: String) -> Bool {
        switch errorMenuStatus(for: errorMessage) {
        case .rateLimited:
            return true
        case .noCredentials, .noSubscription, .error:
            return false
        }
    }

    private func shouldDisplayErrorMenuItem(_ errorMessage: String) -> Bool {
        errorMenuStatus(for: errorMessage).shouldDisplayInList
    }

    private func shouldDisplayErrorStateEvenWithResult(
        _ errorMessage: String,
        identifier: ProviderIdentifier,
        result: ProviderResult?
    ) -> Bool {
        guard shouldDisplayErrorStateEvenWithResult(errorMessage) else { return false }

        if ProviderDisplayPolicy.shouldShowRateLimitedErrorRow(
            identifier: identifier,
            errorMessage: errorMessage,
            result: result
        ) {
            return true
        }

        if ProviderDisplayPolicy.hasDisplayableAccountRows(identifier: identifier, result: result) {
            debugLog("Preserving account rows for \(identifier.displayName) despite rate limit cooldown because account data is available")
        }
        return false
    }

    private func createErrorMenuItem(identifier: ProviderIdentifier, errorMessage: String) -> NSMenuItem {
        let status = errorMenuStatus(for: errorMessage)
        let title = "\(identifier.displayName) (\(status.title))"

        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let iconColor: NSColor = status.shouldDisableListItem ? .disabledControlTextColor : .systemOrange
        item.image = tintedImage(iconForProvider(identifier), color: iconColor)
        item.isEnabled = !status.shouldDisableListItem
        item.tag = 999
        item.toolTip = errorMessage

        return item
    }

    private func createErrorSubmenu(
        identifier: ProviderIdentifier,
        result: ProviderResult?,
        errorMessage: String
    ) -> NSMenu {
        let submenu = NSMenu()

        let statusItem = NSMenuItem()
        statusItem.view = createDisabledLabelView(text: String(format: L("Status: %@"), errorMenuStatus(for: errorMessage).title))
        submenu.addItem(statusItem)

        let errorItem = NSMenuItem()
        errorItem.view = createDisabledLabelView(text: String(format: L("Error: %@"), errorMessage), multiline: true)
        submenu.addItem(errorItem)

        if let result, let details = result.details, details.hasAnyValue {
            submenu.addItem(NSMenuItem.separator())

            let cachedItem = NSMenuItem(title: L("Cached Details"), action: nil, keyEquivalent: "")
            cachedItem.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: L("Cached Details"))
            cachedItem.submenu = createDetailSubmenu(details, identifier: identifier)
            submenu.addItem(cachedItem)
        }

        return submenu
    }
}
