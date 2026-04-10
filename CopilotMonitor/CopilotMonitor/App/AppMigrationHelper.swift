import AppKit
import os.log

private let logger = Logger(subsystem: "com.opencodeproviders", category: "Migration")

/// Handles app bundle name migration from old names to "OpenCode Bar.app"
/// This is needed because Sparkle updates replace bundle contents but keep the folder name,
/// causing "damaged or incomplete" errors when bundle name doesn't match executable name.
@MainActor
final class AppMigrationHelper {
    
    static let shared = AppMigrationHelper()
    
    /// The correct app bundle name that should be used
    private let targetBundleName = "OpenCode Bar.app"
    private let expectedBundleID = "com.copilotmonitor.CopilotMonitor"
    
    /// List of old bundle names that need migration
    private let legacyBundleNames = [
        "CopilotMonitor.app",
        "OpenCodeUsageMonitor.app",
        "ClaudeProvidersMonitor.app"
    ]
    
    private init() {}
    
    /// Check if migration is needed and perform it if necessary
    /// Returns true if migration was initiated (app will restart), false if no migration needed
    func checkAndMigrateIfNeeded() -> Bool {
        let bundlePath = Bundle.main.bundlePath
        let currentBundleName = (bundlePath as NSString).lastPathComponent
        
        logger.info("📦 [Migration] Current bundle: \(currentBundleName) at \(bundlePath)")
        
        if currentBundleName == targetBundleName {
            logger.info("✅ [Migration] Bundle name is correct, no migration needed")
            return false
        }
        
        guard legacyBundleNames.contains(currentBundleName) else {
            logger.info("ℹ️ [Migration] Unknown bundle name '\(currentBundleName)', skipping migration")
            return false
        }
        
        logger.warning("⚠️ [Migration] Legacy bundle detected: \(currentBundleName) → \(self.targetBundleName)")
        
        return performMigration(from: bundlePath, currentName: currentBundleName)
    }
    
    private func performMigration(from currentPath: String, currentName: String) -> Bool {
        let parentDirectory = (currentPath as NSString).deletingLastPathComponent
        let targetPath = (parentDirectory as NSString).appendingPathComponent(targetBundleName)
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: targetPath) {
            if let targetBundle = Bundle(path: targetPath),
               let targetBundleID = targetBundle.bundleIdentifier,
               targetBundleID == expectedBundleID {
                let targetVersion = targetBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
                let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
                
                if let targetVer = targetVersion, let currentVer = currentVersion,
                   targetVer.compare(currentVer, options: .numeric) != .orderedAscending {
                    logger.info("✅ [Migration] Target already exists and is same/newer version, launching it")
                    NSWorkspace.shared.openApplication(
                        at: URL(fileURLWithPath: targetPath),
                        configuration: NSWorkspace.OpenConfiguration()
                    ) { _, error in
                        if let error = error {
                            logger.error("❌ [Migration] Failed to launch target: \(error.localizedDescription)")
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApp.terminate(nil)
                    }
                    return true
                }
                
                logger.info("🔄 [Migration] Target exists but is older version, removing it")
                do {
                    try fileManager.removeItem(atPath: targetPath)
                } catch {
                    logger.error("❌ [Migration] Failed to remove existing target: \(error.localizedDescription)")
                    showMigrationError(message: "Failed to remove existing app at:\n\(targetPath)\n\nPlease remove it manually and restart.")
                    return false
                }
            } else {
                logger.warning("⚠️ [Migration] Target exists but has unexpected bundle ID, skipping migration")
                showMigrationError(message: "An app already exists at:\n\(targetPath)\n\nBut it appears to be a different application. Please remove it manually if you want to proceed with migration.")
                return false
            }
        }
        
        logger.info("📋 [Migration] Copying \(currentPath) → \(targetPath)")
        do {
            try fileManager.copyItem(atPath: currentPath, toPath: targetPath)
        } catch {
            logger.error("❌ [Migration] Failed to copy app: \(error.localizedDescription)")
            showMigrationError(message: "Failed to migrate app:\n\(error.localizedDescription)\n\nPlease reinstall from the DMG.")
            return false
        }
        
        logger.info("🚀 [Migration] Launching migrated app at \(targetPath)")
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
            let fm = FileManager.default
            do {
                try fm.removeItem(atPath: currentPath)
                logger.info("🗑️ [Migration] Removed old bundle at \(currentPath)")
            } catch {
                logger.error("❌ [Migration] Failed to remove old bundle: \(error.localizedDescription)")
            }
            
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: targetPath),
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, error in
                if let error = error {
                    logger.error("❌ [Migration] Failed to launch new app: \(error.localizedDescription)")
                }
            }
        }
        
        logger.info("👋 [Migration] Quitting old app instance")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
        
        return true
    }
    
    private func showMigrationError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Migration Failed"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    
    /// Called by the newly launched app to clean up after migration
    /// Checks if there's an old bundle that should be removed
    func cleanupLegacyBundlesIfNeeded() {
        let bundlePath = Bundle.main.bundlePath
        let currentBundleName = (bundlePath as NSString).lastPathComponent
        guard currentBundleName == targetBundleName else { return }
        
        let parentDirectory = (bundlePath as NSString).deletingLastPathComponent
        let fileManager = FileManager.default
        
        for legacyName in legacyBundleNames {
            let legacyPath = (parentDirectory as NSString).appendingPathComponent(legacyName)
            guard fileManager.fileExists(atPath: legacyPath) else { continue }
            
            if let legacyBundle = Bundle(path: legacyPath),
               let bundleID = legacyBundle.bundleIdentifier,
               bundleID == expectedBundleID {
                logger.info("🧹 [Migration] Found validated legacy bundle to clean up: \(legacyName)")
                
                do {
                    try fileManager.removeItem(atPath: legacyPath)
                    logger.info("✅ [Migration] Removed legacy bundle: \(legacyName)")
                } catch {
                    logger.warning("⚠️ [Migration] Could not remove legacy bundle: \(error.localizedDescription)")
                }
            } else {
                logger.warning("⚠️ [Migration] Skipping \(legacyName) - bundle ID mismatch or unreadable")
            }
        }
    }

    // MARK: - OpenCode Zen → OpenCode Provider Identity Migration

    /// Migrates persisted UserDefaults settings from the removed `opencode_zen` provider
    /// identity to the unified `open_code` identity. Also cleans up stale subscription keys.
    /// This is idempotent and safe to call on every launch.
    func migrateOpenCodeZenSettings() {
        let defaults = UserDefaults.standard
        let legacyRaw = "opencode_zen"
        let canonicalRaw = "open_code"

        // 1. Migrate provider enabled flag
        let legacyEnabledKey = "provider.\(legacyRaw).enabled"
        let canonicalEnabledKey = "provider.\(canonicalRaw).enabled"
        if defaults.object(forKey: legacyEnabledKey) != nil {
            if defaults.object(forKey: canonicalEnabledKey) == nil {
                let value = defaults.bool(forKey: legacyEnabledKey)
                defaults.set(value, forKey: canonicalEnabledKey)
                logger.info("✅ [Migration] Migrated \(legacyEnabledKey) → \(canonicalEnabledKey) = \(value)")
            }
            defaults.removeObject(forKey: legacyEnabledKey)
        }

        // 2. Migrate pinned provider
        let pinnedKey = "statusBarDisplay.provider"
        if let pinnedValue = defaults.string(forKey: pinnedKey), pinnedValue == legacyRaw {
            defaults.set(canonicalRaw, forKey: pinnedKey)
            logger.info("✅ [Migration] Migrated pinned provider from \(legacyRaw) → \(canonicalRaw)")
        }

        // 3. Migrate multi-provider selection
        let multiKey = "statusBarDisplay.multiProviderProviders"
        if var providers = defaults.array(forKey: multiKey) as? [String] {
            if let idx = providers.firstIndex(of: legacyRaw) {
                if !providers.contains(canonicalRaw) {
                    providers[idx] = canonicalRaw
                } else {
                    providers.remove(at: idx)
                }
                // Deduplicate
                let deduped = Array(NSOrderedSet(array: providers)) as? [String] ?? providers
                defaults.set(deduped, forKey: multiKey)
                logger.info("✅ [Migration] Migrated multi-provider selection: replaced \(legacyRaw) with \(canonicalRaw)")
            }
        }

        // 4. Clean up stale OpenCode subscription keys
        let subscriptionPrefix = "subscription_v2."
        let allKeys = defaults.dictionaryRepresentation().keys
        let staleKeys = allKeys.filter { key in
            guard key.hasPrefix(subscriptionPrefix) else { return false }
            let suffix = String(key.dropFirst(subscriptionPrefix.count))
            return suffix == legacyRaw || suffix.hasPrefix("\(legacyRaw).") ||
                   suffix == canonicalRaw || suffix.hasPrefix("\(canonicalRaw).")
        }
        for key in staleKeys {
            defaults.removeObject(forKey: key)
            logger.info("🧹 [Migration] Removed stale subscription key: \(key)")
        }
    }
}
