//
//  DeviceActivityMonitorExtension.swift
//  ReclaimActivityMonitor
//
//  DeviceActivityMonitor Extension for system-wide web domain blocking
//  This extension monitors device activity and applies shields to blocked domains
//

import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

@available(iOS 16.0, *)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    // ManagedSettingsStore used to apply shields
    let store = ManagedSettingsStore()
    
    // App Group identifier for sharing data with main app
    private let appGroupIdentifier = "group.reclaim-app.Reclaim"
    private let blockedDomainsKey = "blockedDomains"
    
    // MARK: - DeviceActivityMonitor Lifecycle
    
    /// Called when the monitoring interval starts
    /// This is where we load blocked domains and apply shields
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        print("🟢 ReclaimActivityMonitor: Interval started for activity: \(activity)")
        
        // Load blocked domains from App Group
        let blockedDomains = loadBlockedDomains()
        
        if blockedDomains.isEmpty {
            print("⚠️ ReclaimActivityMonitor: No blocked domains found")
            // Clear any existing shields
            store.clearAllSettings()
            return
        }
        
        print("📋 ReclaimActivityMonitor: Loading \(blockedDomains.count) blocked domains")
        
        // Convert domain strings to WebDomain objects
        let webDomains = Set(blockedDomains.compactMap { domainString -> WebDomain? in
            // Clean the domain string
            let cleanDomain = domainString
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "www.", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty domains
            guard !cleanDomain.isEmpty else { return nil }
            
            // Create WebDomain
            return WebDomain(domain: cleanDomain)
        })
        
        print("✅ ReclaimActivityMonitor: Created \(webDomains.count) WebDomain objects")
        
        // TEMPORARILY DISABLED: Even in DeviceActivityMonitor, shield.webDomains requires WebDomainToken
        // This is a limitation of the API - WebDomainToken can only be obtained via FamilyActivityPicker
        // TODO: Research alternative approach or use FamilyActivityPicker flow
        // store.shield.webDomains = webDomains
        
        print("⚠️ ReclaimActivityMonitor: Web domain blocking temporarily disabled")
        print("   Reason: API requires WebDomainToken (only via FamilyActivityPicker)")
        print("   Domains prepared: \(webDomains.count)")
        
        // Log some example domains for debugging
        if webDomains.count > 0 {
            let exampleDomains = Array(webDomains.prefix(3))
            print("   Example domains: \(exampleDomains.map { $0.domain })")
        }
    }
    
    /// Called when the monitoring interval ends
    /// We can optionally clear shields here, but typically we want them to persist
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        print("🔴 ReclaimActivityMonitor: Interval ended for activity: \(activity)")
        
        // Optionally clear shields when interval ends
        // For blocking, we usually want shields to persist, so we don't clear here
        // If you want shields to only be active during specific times, uncomment:
        // store.clearAllSettings()
    }
    
    /// Called when a threshold event is reached
    /// This can be used for custom logic when certain conditions are met
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        print("⚡ ReclaimActivityMonitor: Event threshold reached: \(event)")
        
        // You can add custom logic here, such as:
        // - Showing additional warnings
        // - Logging attempts to access blocked content
        // - Triggering notifications
    }
    
    // MARK: - Helper Methods
    
    /// Load blocked domains from App Group shared storage
    private func loadBlockedDomains() -> [String] {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ ReclaimActivityMonitor: Failed to access App Group: \(appGroupIdentifier)")
            return []
        }
        
        // Try to get blocked domains from UserDefaults
        if let domains = sharedDefaults.array(forKey: blockedDomainsKey) as? [String] {
            print("✅ ReclaimActivityMonitor: Loaded \(domains.count) domains from UserDefaults")
            return domains
        }
        
        // Fallback: Try to read from a JSON file (if using file-based storage)
        // This matches the Content Blocker approach
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let fileURL = containerURL.appendingPathComponent("blockedDomains.json")
            
            if let data = try? Data(contentsOf: fileURL),
               let domains = try? JSONDecoder().decode([String].self, from: data) {
                print("✅ ReclaimActivityMonitor: Loaded \(domains.count) domains from JSON file")
                return domains
            }
        }
        
        print("⚠️ ReclaimActivityMonitor: No blocked domains found in App Group")
        return []
    }
}
