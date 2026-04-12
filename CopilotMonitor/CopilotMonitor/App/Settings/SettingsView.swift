import SwiftUI
import os.log

private let settingsViewLogger = Logger(subsystem: "com.opencodeproviders", category: "SettingsView")

struct SettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var selectedTab: SettingsTab? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    SettingsSidebarItem(tab: tab)
                        .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
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
        .id(prefs.appLanguageMode.rawValue)
        .onAppear {
            if selectedTab == nil {
                selectedTab = .general
            }
            settingsViewLogger.debug("Settings view appeared with sidebar layout")
        }
        .onChange(of: selectedTab) { newValue in
            let title = newValue?.title ?? SettingsTab.general.title
            settingsViewLogger.debug("Switched settings tab to \(title, privacy: .public)")
        }
    }
}

private struct SettingsSidebarItem: View {
    let tab: SettingsTab

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title)
                    .lineLimit(1)

                Text(tab.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
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

    var summary: String {
        switch self {
        case .general:
            return L("Refresh, startup, and command line tool")
        case .statusBar:
            return L("Choose which providers appear in UsageBar")
        case .advancedProviders:
            return L("Provider-specific account and window overrides")
        case .subscriptions:
            return L("Manage monthly plans and custom costs")
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
