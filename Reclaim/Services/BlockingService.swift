//
//  BlockingService.swift
//  Reclaim
//
//  Network Extension (DNS Filter) management service
//

import Foundation
import NetworkExtension
import Combine

@MainActor
class BlockingService: ObservableObject {
    static let shared = BlockingService()

    @Published var isBlocking = false
    @Published var blockingMode: UserDefaultsManager.BlockingMode = .strict

    private let userDefaults = UserDefaultsManager.shared
    private var manager: NEDNSProxyManager?

    private init() {
        blockingMode = userDefaults.blockingMode
        Task {
            await checkStatus()
        }
    }

    // MARK: - Check Status

    func checkStatus() async {
        do {
            let manager = try await loadManager()
            self.manager = manager
            isBlocking = manager.isEnabled
        } catch {
            print("Failed to load DNS manager: \(error)")
            isBlocking = false
        }
    }

    // MARK: - Enable Blocking

    func enableBlocking() async throws {
        let manager = try await loadManager()

        // Configure DNS proxy provider
        let providerProtocol = NEDNSProxyProviderProtocol()
        providerProtocol.providerBundleIdentifier = "com.reclaim.Reclaim.DNSFilter"
        providerProtocol.serverAddress = "127.0.0.1"

        manager.providerProtocol = providerProtocol
        manager.isEnabled = true
        manager.localizedDescription = "Reclaim Content Filter"

        // Save configuration - this will start the DNS proxy
        try await manager.saveToPreferences()

        self.manager = manager
        isBlocking = true

        print("✅ DNS Filter enabled")
    }

    // MARK: - Disable Blocking

    func disableBlocking() async throws {
        let manager = try await loadManager()

        // Disable the DNS proxy
        manager.isEnabled = false
        try await manager.saveToPreferences()

        // In cooldown mode, re-enable after 5 minutes
        if blockingMode == .cooldown {
            Task {
                try await Task.sleep(for: .seconds(300))
                try await enableBlocking()
            }
        }

        self.manager = manager
        isBlocking = false

        print("⚠️ DNS Filter disabled")
    }

    // MARK: - Restart DNS Filter

    /// Restarts the DNS filter to reload the blocklist
    func restartDNSFilter() async {
        guard isBlocking else { return }

        do {
            // Disable and re-enable to reload blocklist
            let manager = try await loadManager()
            manager.isEnabled = false
            try await manager.saveToPreferences()

            try await Task.sleep(for: .seconds(1))

            manager.isEnabled = true
            try await manager.saveToPreferences()

            print("🔄 DNS Filter restarted")
        } catch {
            print("Failed to restart DNS filter: \(error)")
        }
    }

    // MARK: - Change Blocking Mode

    func setBlockingMode(_ mode: UserDefaultsManager.BlockingMode) async throws {
        blockingMode = mode
        userDefaults.blockingMode = mode

        // Apply mode-specific settings
        switch mode {
        case .strict:
            // Ensure blocking is enabled and cannot be disabled
            if !isBlocking {
                try await enableBlocking()
            }
        case .cooldown:
            // Allow temporary disabling
            break
        }
    }

    // MARK: - Private Helpers

    private func loadManager() async throws -> NEDNSProxyManager {
        let manager = NEDNSProxyManager.shared()
        try await manager.loadFromPreferences()
        return manager
    }
}
