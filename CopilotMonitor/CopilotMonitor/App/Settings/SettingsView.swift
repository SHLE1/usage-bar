import SwiftUI
import os.log

private let settingsViewLogger = Logger(subsystem: "com.opencodeproviders", category: "SettingsView")

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Picker("", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Text(verbatim: tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .statusBar:
                    StatusBarSettingsView()
                case .subscriptions:
                    SubscriptionSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: selectedTab) { newValue in
            settingsViewLogger.debug("Switched settings tab to \(newValue.title, privacy: .public)")
        }
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case statusBar
    case subscriptions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return L("General")
        case .statusBar:
            return L("Status Bar")
        case .subscriptions:
            return L("Subscriptions")
        }
    }
}
