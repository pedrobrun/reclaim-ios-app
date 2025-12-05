//
//  DNSFilterProvider.swift
//  ReclaimDNSFilter
//
//  DNS Proxy Provider for system-wide content blocking
//

import NetworkExtension
import os.log

class DNSFilterProvider: NEDNSProxyProvider {
    private var blocklist: Set<String> = []
    private let logger = Logger(subsystem: "com.reclaim.DNSFilter", category: "DNSFilter")

    // MARK: - Provider Lifecycle

    override func startProxy(options: [String: Any]?, completionHandler: @escaping (Error?) -> Void) {
        logger.log("🚀 DNS Filter starting...")

        // Load blocklist from shared container
        loadBlocklist()

        logger.log("✅ DNS Filter started with \(self.blocklist.count) blocked domains")
        completionHandler(nil)
    }

    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.log("🛑 DNS Filter stopped: \(reason.rawValue)")
        completionHandler()
    }

    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        // This method is called for each DNS request

        guard let hostname = extractHostname(from: flow) else {
            return true // Allow if we can't determine hostname
        }

        // Check if domain should be blocked
        if shouldBlock(hostname) {
            logger.log("🚫 BLOCKED: \(hostname)")
            return false // Block the request
        }

        return true // Allow the request
    }

    // MARK: - Blocking Logic

    private func shouldBlock(_ hostname: String) -> Bool {
        let lowercased = hostname.lowercased()

        // Check exact match
        if blocklist.contains(lowercased) {
            return true
        }

        // Check wildcard domains (e.g., *.pornhub.com matches www.pornhub.com)
        for blocked in blocklist {
            if blocked.hasPrefix("*.") {
                let domain = String(blocked.dropFirst(2)) // Remove "*."
                if lowercased.hasSuffix(domain) || lowercased == domain {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Blocklist Management

    private func loadBlocklist() {
        // Load from shared App Group container
        guard let sharedDefaults = UserDefaults(suiteName: "group.reclaim-app.Reclaim"),
              let domains = sharedDefaults.stringArray(forKey: "blocklist") else {
            logger.warning("⚠️ No blocklist found in shared container")
            return
        }

        blocklist = Set(domains.map { $0.lowercased() })
        logger.log("📋 Loaded \(self.blocklist.count) domains from shared container")
    }

    // MARK: - Helpers

    private func extractHostname(from flow: NEAppProxyFlow) -> String? {
        // Extract hostname from the flow
        // Note: The actual implementation depends on the flow type
        // This is a simplified version
        if let dnsFlow = flow as? NEAppProxyUDPFlow {
            return dnsFlow.remoteEndpoint as? NWHostEndpoint
        }
        return nil
    }
}
