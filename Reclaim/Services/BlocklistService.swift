//
//  BlocklistService.swift
//  Reclaim
//
//  Blocklist management and synchronization service
//

import Foundation

class BlocklistService {
    static let shared = BlocklistService()
    private let apiClient = APIClient.shared
    private let userDefaults = UserDefaultsManager.shared

    private init() {}

    // MARK: - Get Domains

    func getDomains() async throws -> [BlocklistDomain] {
        return try await apiClient.request(.getDomains)
    }

    // MARK: - Add Domain

    func addDomain(_ domain: String) async throws -> BlocklistDomain {
        let request = AddDomainRequest(domain: domain)
        let newDomain: BlocklistDomain = try await apiClient.request(.addDomain, body: request)

        // Sync blocklist with DNS extension
        await syncBlocklist()

        return newDomain
    }

    // MARK: - Delete Domain

    func deleteDomain(_ id: String) async throws {
        try await apiClient.request(.deleteDomain(id))

        // Sync blocklist with DNS extension
        await syncBlocklist()
    }

    // MARK: - Get Templates

    func getTemplates() async throws -> [BlocklistTemplate] {
        return try await apiClient.request(.getTemplates)
    }

    // MARK: - Apply Template

    func applyTemplate(_ templateName: String) async throws {
        try await apiClient.request(.applyTemplate(templateName))

        // Sync blocklist with DNS extension
        await syncBlocklist()
    }

    // MARK: - Sync Blocklist

    /// Fetches the latest blocklist from backend and updates shared storage for extensions
    /// Updates both DNS extension (Content Blocker) and DeviceActivityMonitor extension
    func syncBlocklist() async {
        do {
            let domains = try await getDomains()
            let domainStrings = domains.map { $0.domain }

            // Save to shared UserDefaults for DNS extension and DeviceActivityMonitor
            userDefaults.saveBlocklist(domainStrings)

            print("✅ Synced \(domainStrings.count) domains to extensions")

            // Notify DNS extension to reload (Content Blocker)
            await BlockingService.shared.restartDNSFilter()
            
            // Update Screen Time blocks (DeviceActivityMonitor)
            // This will save domains to App Group and start monitoring if needed
            if #available(iOS 16.0, *) {
                await ScreenTimeManager.shared.updateBlocks(domains: domains)
            }
        } catch {
            print("❌ Failed to sync blocklist: \(error)")
        }
    }
}
