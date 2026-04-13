import SwiftUI
import os.log

private let generalSettingsLogger = Logger(subsystem: "com.opencodeproviders", category: "GeneralSettingsView")

struct GeneralSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared

    @State private var cliInstalled = CLIService.isInstalled
    @State private var cliActionMessage: String?
    @State private var showingCLIAlert = false

    var body: some View {
        SettingsPage(
            title: L("General"),
            subtitle: L("Control refresh timing, appearance, startup behavior, and command line access.")
        ) {
            SettingsSectionCard(
                title: L("Usage Updates"),
                subtitle: L("Choose how often UsageBar refreshes and how it estimates end-of-month cost.")
            ) {
                VStack(spacing: 0) {
                    SettingsRow(
                        title: L("Auto Refresh Period"),
                        description: L("How often provider data refreshes in the background.")
                    ) {
                        Menu {
                            ForEach(RefreshInterval.allCases, id: \.self) { interval in
                                Button(interval.title) {
                                    prefs.refreshInterval = interval
                                    generalSettingsLogger.debug("Selected refresh interval \(interval.title, privacy: .public)")
                                }
                            }
                        } label: {
                            CompactSettingsMenuLabel(title: prefs.refreshInterval.title)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }

                    Divider()
                        .padding(.vertical, 16)

                    SettingsRow(
                        title: L("Prediction Period"),
                        description: L("The usage window used for monthly cost forecasts.")
                    ) {
                        Menu {
                            ForEach(PredictionPeriod.allCases, id: \.self) { period in
                                Button(period.title) {
                                    prefs.predictionPeriod = period
                                    generalSettingsLogger.debug("Selected prediction period \(period.title, privacy: .public)")
                                }
                            }
                        } label: {
                            CompactSettingsMenuLabel(title: prefs.predictionPeriod.title)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }
                }
            }

            SettingsSectionCard(
                title: L("App Behavior"),
                subtitle: L("Decide how UsageBar behaves after launch.")
            ) {
                VStack(spacing: 0) {
                    SettingsRow(
                        title: L("App Language"),
                        description: L("Choose which language UsageBar uses. The default follows macOS.")
                    ) {
                        Menu {
                            ForEach(AppLanguageMode.allCases, id: \.self) { mode in
                                Button(mode.title) {
                                    prefs.appLanguageMode = mode
                                    generalSettingsLogger.debug("Selected app language \(mode.rawValue, privacy: .public)")
                                }
                            }
                        } label: {
                            CompactSettingsMenuLabel(title: prefs.appLanguageMode.title)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }

                    Divider()
                        .padding(.vertical, 16)

                    SettingsRow(
                        title: L("Appearance"),
                        description: L("Choose whether UsageBar follows macOS appearance or stays in a fixed mode.")
                    ) {
                        Menu {
                            ForEach(AppAppearanceMode.allCases, id: \.self) { mode in
                                Button(mode.title) {
                                    prefs.appAppearanceMode = mode
                                    generalSettingsLogger.debug("Selected app appearance \(mode.rawValue, privacy: .public)")
                                }
                            }
                        } label: {
                            CompactSettingsMenuLabel(title: prefs.appAppearanceMode.title)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }

                    Divider()
                        .padding(.vertical, 16)

                    SettingsRow(
                        title: L("Launch at Login"),
                        description: L("Open UsageBar automatically when you sign in to macOS.")
                    ) {
                        Toggle("", isOn: $prefs.launchAtLogin)
                            .labelsHidden()
                    }

                    Divider()
                        .padding(.vertical, 16)

                    SettingsRow(
                        title: L("Critical Badge"),
                        description: L("Show an attention badge when a provider reaches a critical state.")
                    ) {
                        Toggle("", isOn: $prefs.criticalBadge)
                            .labelsHidden()
                    }
                }
            }

            SettingsSectionCard(
                title: L("Command Line Tool"),
                subtitle: L("Install the usagebar command so you can use UsageBar data from Terminal.")
            ) {
                SettingsRow(
                    title: cliInstalled ? L("Installed") : L("Not Installed"),
                    description: cliInstalled
                        ? String(format: L("Current path: %@"), CLIService.installPath)
                        : L("The command line tool is not available yet.")
                ) {
                    Button(cliInstalled ? L("Uninstall") : L("Install")) {
                        performCLIAction(install: !cliInstalled)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .alert(L("CLI"), isPresented: $showingCLIAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cliActionMessage ?? "")
        }
        .onAppear {
            generalSettingsLogger.debug("Rendering general settings with compact menu controls")
        }
    }

    // MARK: - Helpers

    private func performCLIAction(install: Bool) {
        let error: String?
        if install {
            error = CLIService.install()
        } else {
            error = CLIService.uninstall()
        }

        cliInstalled = CLIService.isInstalled

        if let error = error {
            cliActionMessage = error
            showingCLIAlert = true
        } else {
            let verb = install ? L("installed") : L("uninstalled")
            cliActionMessage = String(format: L("CLI %@ successfully."), verb)
            showingCLIAlert = true
        }
    }
}
