import AppKit

extension StatusBarController {
    func setupMenu() {
        menu = NSMenu()
        menu.delegate = self

        historyMenuItem = NSMenuItem(title: L("Usage History"), action: nil, keyEquivalent: "")
        historyMenuItem.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Usage History")
        historySubmenu = NSMenu()
        historyMenuItem.submenu = historySubmenu
        let loadingItem = NSMenuItem(title: L("Loading..."), action: nil, keyEquivalent: "")
        loadingItem.isEnabled = false
        historySubmenu.addItem(loadingItem)

        loadCachedHistoryOnStartup()

        let refreshItem = NSMenuItem(title: L("Refresh"), action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let checkForUpdatesItem = NSMenuItem(title: L("Check for Updates..."), action: #selector(AppDelegate.checkForUpdates), keyEquivalent: "u")
        checkForUpdatesItem.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Check for Updates")
        checkForUpdatesItem.target = NSApp.delegate
        menu.addItem(checkForUpdatesItem)

        refreshIntervalMenu = NSMenu()
        for interval in RefreshInterval.allCases {
            let item = NSMenuItem(title: interval.title, action: #selector(refreshIntervalSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = interval.rawValue
            refreshIntervalMenu.addItem(item)
        }
        updateRefreshIntervalMenu()

        multiProviderBarMenu = NSMenu()
        for identifier in ProviderIdentifier.allCases {
            let providerItem = NSMenuItem(
                title: identifier.displayName,
                action: #selector(multiProviderProviderSelected(_:)),
                keyEquivalent: ""
            )
            providerItem.target = self
            providerItem.representedObject = identifier.rawValue
            multiProviderBarMenu.addItem(providerItem)
        }

        enabledProvidersMenu = NSMenu()
        for identifier in ProviderIdentifier.allCases {
            let providerItem = NSMenuItem(
                title: identifier.displayName,
                action: #selector(toggleProvider(_:)),
                keyEquivalent: ""
            )
            providerItem.target = self
            providerItem.representedObject = identifier.rawValue
            enabledProvidersMenu.addItem(providerItem)
        }

        criticalBadgeMenuItem = NSMenuItem(title: L("Critical Badge"), action: #selector(toggleCriticalBadge(_:)), keyEquivalent: "")
        criticalBadgeMenuItem.target = self
        criticalBadgeMenuItem.isHidden = true

        showProviderNameMenuItem = NSMenuItem(title: L("Show Provider Icon"), action: #selector(toggleShowProviderName(_:)), keyEquivalent: "")
        showProviderNameMenuItem.target = self
        showProviderNameMenuItem.isHidden = true

        updateEnabledProvidersMenu()
        updateStatusBarDisplayMenuState()

        predictionPeriodMenu = NSMenu()
        for period in PredictionPeriod.allCases {
            let item = NSMenuItem(title: period.title, action: #selector(predictionPeriodSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = period.rawValue
            predictionPeriodMenu.addItem(item)
        }
        updatePredictionPeriodMenu()

        menu.addItem(NSMenuItem.separator())

        launchAtLoginItem = NSMenuItem(title: L("Launch at Login"), action: #selector(launchAtLoginClicked), keyEquivalent: "")
        launchAtLoginItem.isHidden = true
        launchAtLoginItem.target = self
        updateLaunchAtLoginState()
        menu.addItem(launchAtLoginItem)

        installCLIItem = NSMenuItem(title: L("Install CLI (usagebar)"), action: #selector(installCLIClicked), keyEquivalent: "")
        installCLIItem.isHidden = true
        installCLIItem.target = self
        menu.addItem(installCLIItem)
        updateCLIInstallState()

        let settingsItem = NSMenuItem(title: L("Settings..."), action: #selector(AppDelegate.openSettingsWindow), keyEquivalent: ",")
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings")
        settingsItem.target = NSApp.delegate
        menu.addItem(settingsItem)

        let shareSnapshotItem = NSMenuItem(title: L("Share Usage Snapshot..."), action: #selector(shareUsageSnapshotClicked), keyEquivalent: "")
        shareSnapshotItem.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Share Usage Snapshot")
        shareSnapshotItem.target = self
        menu.addItem(shareSnapshotItem)
        debugLog("setupMenu: Share Usage Snapshot menu item added")

        menu.addItem(NSMenuItem.separator())

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let versionItem = NSMenuItem(title: String(format: L("UsageBar v%@"), version), action: #selector(openGitHub), keyEquivalent: "")
        versionItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "Version")
        versionItem.target = self
        menu.addItem(versionItem)

        let quitItem = NSMenuItem(title: L("Quit"), action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: "Quit")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.addItem(NSMenuItem.separator())

        viewErrorDetailsItem = NSMenuItem(title: L("View Error Details..."), action: #selector(viewErrorDetailsClicked), keyEquivalent: "e")
        viewErrorDetailsItem.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "View Error Details")
        viewErrorDetailsItem.target = self
        viewErrorDetailsItem.isHidden = true
        menu.addItem(viewErrorDetailsItem)

        statusItem?.menu = menu
        logMenuStructure()
    }

    func updateRefreshIntervalMenu() {
        for item in refreshIntervalMenu.items {
            item.state = (item.tag == refreshInterval.rawValue) ? .on : .off
        }
    }

    @objc func refreshIntervalSelected(_ sender: NSMenuItem) {
        if let interval = RefreshInterval(rawValue: sender.tag) {
            refreshInterval = interval
        }
    }

    @objc func multiProviderProviderSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let identifier = ProviderIdentifier(rawValue: rawValue) else { return }
        var current = multiProviderSelection
        if let idx = current.firstIndex(of: identifier) {
            current.remove(at: idx)
        } else {
            current.append(identifier)
        }
        multiProviderSelection = current
        debugLog("multiProviderProviderSelected: \(identifier.displayName), now \(current.count) selected")
        updateStatusBarDisplayMenuState()
        updateStatusBarText()
    }

    @objc func toggleCriticalBadge(_ sender: NSMenuItem) {
        criticalBadgeEnabled.toggle()
        debugLog("toggleCriticalBadge: value=\(criticalBadgeEnabled)")
    }

    @objc func toggleShowProviderName(_ sender: NSMenuItem) {
        showProviderName.toggle()
        debugLog("toggleShowProviderName: value=\(showProviderName)")
    }

    func updateStatusBarDisplayMenuState() {
        if let multiProviderBarMenu {
            let currentMultiSelection = multiProviderSelection
            for item in multiProviderBarMenu.items {
                guard let rawValue = item.representedObject as? String,
                      let identifier = ProviderIdentifier(rawValue: rawValue) else { continue }
                item.state = currentMultiSelection.contains(identifier) ? .on : .off
                item.isEnabled = isProviderEnabled(identifier)
            }
        }

        updateEnabledProvidersMenu()
        criticalBadgeMenuItem?.state = criticalBadgeEnabled ? .on : .off
        showProviderNameMenuItem?.state = showProviderName ? .on : .off
    }

    func updatePredictionPeriodMenu() {
        for item in predictionPeriodMenu.items {
            item.state = (item.tag == predictionPeriod.rawValue) ? .on : .off
        }
    }

    @objc func predictionPeriodSelected(_ sender: NSMenuItem) {
        if let period = PredictionPeriod(rawValue: sender.tag) {
            predictionPeriod = period
        }
    }

    @objc func toggleProvider(_ sender: NSMenuItem) {
        guard let idString = sender.representedObject as? String,
              let identifier = ProviderIdentifier(rawValue: idString) else { return }
        let key = "provider.\(identifier.rawValue).enabled"
        let current = isProviderEnabled(identifier)
        UserDefaults.standard.set(!current, forKey: key)
        updateEnabledProvidersMenu()
        updateStatusBarDisplayMenuState()
        updateStatusBarText()
        refreshClicked()
    }

    func updateEnabledProvidersMenu() {
        guard let enabledProvidersMenu else { return }
        for item in enabledProvidersMenu.items {
            guard let idString = item.representedObject as? String,
                  let identifier = ProviderIdentifier(rawValue: idString) else { continue }
            item.state = isProviderEnabled(identifier) ? .on : .off
        }
    }

}
