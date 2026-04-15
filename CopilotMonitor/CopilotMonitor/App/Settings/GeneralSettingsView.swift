import SwiftUI
import os.log

private let generalSettingsLogger = Logger(subsystem: "com.opencodeproviders", category: "GeneralSettingsView")

struct GeneralSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared

    @State private var cliInstalled = CLIService.isInstalled
    @State private var cliActionMessage: String?
    @State private var showingCLIAlert = false

    var body: some View {
        SettingsPage {
            SettingsSectionCard(
                title: L("Usage Updates")
            ) {
                VStack(spacing: 0) {
                    SettingsRow(
                        title: L("Auto Refresh Period")
                    ) {
                        Picker("", selection: $prefs.refreshInterval) {
                            ForEach(RefreshInterval.allCases, id: \.self) { interval in
                                Text(interval.title).tag(interval)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .onChange(of: prefs.refreshInterval) { newValue in
                            generalSettingsLogger.debug("Selected refresh interval \(newValue.title, privacy: .public)")
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    SettingsRow(
                        title: L("Prediction Period")
                    ) {
                        Picker("", selection: $prefs.predictionPeriod) {
                            ForEach(PredictionPeriod.allCases, id: \.self) { period in
                                Text(period.title).tag(period)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .onChange(of: prefs.predictionPeriod) { newValue in
                            generalSettingsLogger.debug("Selected prediction period \(newValue.title, privacy: .public)")
                        }
                    }
                }
            }

            SettingsSectionCard(
                title: L("App Behavior")
            ) {
                VStack(spacing: 0) {
                    SettingsRow(
                        title: L("App Language")
                    ) {
                        Picker("", selection: $prefs.appLanguageMode) {
                            ForEach(AppLanguageMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .onChange(of: prefs.appLanguageMode) { newValue in
                            generalSettingsLogger.debug("Selected app language \(newValue.rawValue, privacy: .public)")
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    SettingsRow(
                        title: L("Appearance")
                    ) {
                        Picker("", selection: $prefs.appAppearanceMode) {
                            ForEach(AppAppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .onChange(of: prefs.appAppearanceMode) { newValue in
                            generalSettingsLogger.debug("Selected app appearance \(newValue.rawValue, privacy: .public)")
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    SettingsRow(
                        title: L("Launch at Login")
                    ) {
                        Toggle("", isOn: $prefs.launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    SettingsRow(
                        title: L("Critical Badge")
                    ) {
                        Toggle("", isOn: $prefs.criticalBadge)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }

            SettingsSectionCard(
                title: L("Command Line Tool")
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
            generalSettingsLogger.debug("Rendering general settings with native picker controls")
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
