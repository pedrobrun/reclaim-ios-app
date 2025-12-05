//
//  UserDefaultsManager.swift
//  Reclaim
//
//  App settings and preferences storage
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: "group.reclaim-app.Reclaim")

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let blockingMode = "blockingMode" // "strict" or "cooldown"
        static let blocklist = "blocklist"
        static let lastSyncDate = "lastSyncDate"
        static let familyActivitySelection = "familyActivitySelection"
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: - Blocking Mode

    enum BlockingMode: String {
        case strict
        case cooldown
    }

    var blockingMode: BlockingMode {
        get {
            if let rawValue = defaults.string(forKey: Keys.blockingMode),
               let mode = BlockingMode(rawValue: rawValue) {
                return mode
            }
            return .strict // Default to strict mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.blockingMode)
        }
    }

    // MARK: - Blocklist (Shared with DNS Extension and DeviceActivityMonitor)

    func saveBlocklist(_ domains: [String]) {
        // Save to shared container so DNS extension and DeviceActivityMonitor can access
        sharedDefaults?.set(domains, forKey: Keys.blocklist)
        sharedDefaults?.set(Date(), forKey: Keys.lastSyncDate)
        
        // Also save with the key that DeviceActivityMonitor expects
        sharedDefaults?.set(domains, forKey: "blockedDomains")
        
        print("💾 Saved \(domains.count) domains to App Group for extensions")
    }

    func getBlocklist() -> [String] {
        return sharedDefaults?.stringArray(forKey: Keys.blocklist) ?? []
    }

    var lastSyncDate: Date? {
        return sharedDefaults?.object(forKey: Keys.lastSyncDate) as? Date
    }

    // MARK: - Family Activity Selection

    func saveFamilyActivitySelection(_ data: Data) {
        defaults.set(data, forKey: Keys.familyActivitySelection)
    }

    func getFamilyActivitySelection() -> Data? {
        return defaults.data(forKey: Keys.familyActivitySelection)
    }

    // MARK: - Clear All

    func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
    }
}
