import AppKit
import SwiftUI
import os.log

private let settingsViewLogger = Logger(subsystem: "com.opencodeproviders", category: "SettingsView")

struct SettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var selectedTab: SettingsTab? = {
        if let saved = UserDefaults.standard.string(forKey: "settings.selectedTab"),
           let tab = SettingsTab(rawValue: saved) {
            return tab
        }
        return .general
    }()
    private var minimumSidebarWidth: CGFloat {
        SettingsSidebarMetrics.minimumWidth(for: SettingsTab.allCases)
    }
    private var preferredColorScheme: ColorScheme? {
        switch prefs.appAppearanceMode {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(
                min: minimumSidebarWidth,
                ideal: SettingsSidebarMetrics.idealWidth
            )
            .background(SettingsSidebarSplitViewBridge(minimumSidebarWidth: minimumSidebarWidth))
        } detail: {
            Group {
                switch selectedTab ?? .general {
                case .general:
                    GeneralSettingsView()
                case .statusBar:
                    StatusBarSettingsView()
                case .advancedProviders:
                    AdvancedProviderSettingsView()
                case .subscriptions:
                    SubscriptionSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 760, idealWidth: 840, minHeight: 520, idealHeight: 560)
        .preferredColorScheme(preferredColorScheme)
        .id("\(prefs.appLanguageMode.rawValue)-\(prefs.appAppearanceMode.rawValue)")
        .onAppear {
            if selectedTab == nil {
                selectedTab = .general
            }
            settingsViewLogger.debug("Settings view appeared with native sidebar layout")
        }
        .onChange(of: selectedTab) { newValue in
            let title = newValue?.title ?? SettingsTab.general.title
            if let rawValue = newValue?.rawValue {
                UserDefaults.standard.set(rawValue, forKey: "settings.selectedTab")
            }
            settingsViewLogger.debug("Switched settings tab to \(title, privacy: .public)")
        }
    }
}

private struct SettingsSidebarSplitViewBridge: NSViewRepresentable {
    let minimumSidebarWidth: CGFloat

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        configure(for: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configure(for: nsView)
    }

    private func configure(for view: NSView) {
        DispatchQueue.main.async {
            guard let splitViewController = splitViewController(from: view),
                  splitViewController.splitViewItems.count > 1 else {
                return
            }

            let sidebarItem = splitViewController.splitViewItems[0]

            sidebarItem.canCollapse = false
            sidebarItem.minimumThickness = minimumSidebarWidth
            sidebarItem.maximumThickness = .greatestFiniteMagnitude

            if sidebarItem.isCollapsed {
                sidebarItem.isCollapsed = false
            }

            if let sidebarView = splitViewController.splitView.subviews.first,
               sidebarView.frame.width < minimumSidebarWidth {
                splitViewController.splitView.setPosition(minimumSidebarWidth, ofDividerAt: 0)
            }

            settingsViewLogger.debug("Settings sidebar minimum width set to \(Int(minimumSidebarWidth))pt")
        }
    }

    private func splitViewController(from view: NSView) -> NSSplitViewController? {
        if let controller = enclosingSplitView(for: view)?.delegate as? NSSplitViewController {
            return controller
        }

        var responder: NSResponder? = view
        while let current = responder {
            if let controller = current as? NSSplitViewController {
                return controller
            }
            responder = current.nextResponder
        }

        return findSplitViewController(in: view.window?.contentViewController)
    }

    private func enclosingSplitView(for view: NSView) -> NSSplitView? {
        var currentView: NSView? = view
        while let current = currentView {
            if let splitView = current as? NSSplitView {
                return splitView
            }
            currentView = current.superview
        }
        return nil
    }

    private func findSplitViewController(in controller: NSViewController?) -> NSSplitViewController? {
        guard let controller else { return nil }
        if let splitViewController = controller as? NSSplitViewController {
            return splitViewController
        }

        for child in controller.children {
            if let splitViewController = findSplitViewController(in: child) {
                return splitViewController
            }
        }

        return nil
    }
}

private enum SettingsSidebarMetrics {
    static let idealWidth: CGFloat = 220
    private static let minimumWidthFloor: CGFloat = 150
    private static let rowFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    private static let iconWidth: CGFloat = 16
    private static let iconSpacing: CGFloat = 10
    private static let rowInsets: CGFloat = 34

    static func minimumWidth(for tabs: [SettingsTab]) -> CGFloat {
        let widestTitleWidth = tabs
            .map { ($0.title as NSString).size(withAttributes: [.font: rowFont]).width }
            .max() ?? 0

        let contentWidth = widestTitleWidth + iconWidth + iconSpacing + rowInsets
        return max(minimumWidthFloor, ceil(contentWidth))
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case statusBar
    case subscriptions
    case advancedProviders

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return L("General")
        case .statusBar:
            return L("Status Bar")
        case .advancedProviders:
            return L("Advanced Providers")
        case .subscriptions:
            return L("Subscriptions")
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            return "gearshape"
        case .statusBar:
            return "menubar.rectangle"
        case .advancedProviders:
            return "slider.horizontal.3"
        case .subscriptions:
            return "creditcard"
        }
    }
}
