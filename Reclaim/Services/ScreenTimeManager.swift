//
//  ScreenTimeManager.swift
//  Reclaim
//
//  Manages Screen Time API for system-wide domain and app blocking
//  Requires iOS 16.0+ and Family Controls capability
//

import Foundation
import Combine
#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
import DeviceActivity
#endif

@available(iOS 16.0, *)
@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var isAuthorized = false
    @Published var authorizationError: Error?
    @Published var isAvailable = false
    
    #if canImport(FamilyControls)
    @Published var savedSelection = FamilyActivitySelection()
    #endif

    #if canImport(FamilyControls)
    private let authorizationCenter = AuthorizationCenter.shared
    private let managedSettingsStore = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    
    // DeviceActivityName for our monitoring schedule
    private let activityName = DeviceActivityName("reclaimBlocking")
    #endif

    private init() {
        #if canImport(FamilyControls)
        // Try to check if Family Controls is actually available
        // If capability is not in entitlements, this will fail silently
        // We'll detect it when user tries to use it
        isAvailable = checkCapabilityAvailable()
        if isAvailable {
            checkAuthorizationStatus()
        }
        #else
        isAvailable = false
        #endif
    }
    
    // MARK: - Selection Persistence
    
    func saveSelection(_ selection: FamilyActivitySelection) {
        #if canImport(FamilyControls)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(selection)
            UserDefaultsManager.shared.saveFamilyActivitySelection(data)
            self.savedSelection = selection
            
            // Apply blocks immediately
            blockApplications(selection.applicationTokens)
            blockAppCategories(selection.categoryTokens)
            
            print("✅ Saved and applied FamilyActivitySelection")
        } catch {
            print("❌ Failed to save selection: \(error)")
        }
        #endif
    }
    
    func loadSelection() {
        #if canImport(FamilyControls)
        if let data = UserDefaultsManager.shared.getFamilyActivitySelection() {
            do {
                let decoder = JSONDecoder()
                let selection = try decoder.decode(FamilyActivitySelection.self, from: data)
                self.savedSelection = selection
                
                // Re-apply blocks
                blockApplications(selection.applicationTokens)
                blockAppCategories(selection.categoryTokens)
                
                print("✅ Loaded and applied FamilyActivitySelection")
            } catch {
                print("❌ Failed to load selection: \(error)")
            }
        }
        #endif
    }

    // MARK: - Authorization
    
    #if canImport(FamilyControls)
    /// Returns false if capability is not configured in entitlements
    private func checkCapabilityAvailable() -> Bool {
        // Try to access AuthorizationCenter - if capability is missing, this will fail
        // But we can't easily detect it without trying, so we'll let runtime errors handle it
        // For now, assume it's available if framework can be imported
        // The actual check happens when user tries to use it
        return true
    }
    #endif

    // MARK: - Authorization Check

    /// Check if Screen Time authorization is granted
    func checkAuthorizationStatus() {
        #if !canImport(FamilyControls)
        isAuthorized = false
        return
        #endif
        
        #if canImport(FamilyControls)
        let currentStatus = authorizationCenter.authorizationStatus
        let newAuthorized: Bool
        
        switch currentStatus {
        case .approved:
            newAuthorized = true
            print("✅ Screen Time authorized - status: \(currentStatus)")
        case .denied:
            newAuthorized = false
            print("❌ Screen Time denied - status: \(currentStatus)")
        case .notDetermined:
            newAuthorized = false
            print("⚠️ Screen Time not determined - status: \(currentStatus)")
        @unknown default:
            newAuthorized = false
            print("⚠️ Screen Time unknown status: \(currentStatus)")
        }
        
        // Always update to trigger SwiftUI refresh
        // This ensures the UI updates when the view appears
        isAuthorized = newAuthorized
        print("📊 Updated isAuthorized to: \(isAuthorized)")
        #endif
    }

    /// Request Screen Time authorization from user
    func requestAuthorization() async throws {
        #if !canImport(FamilyControls)
        throw ScreenTimeError.authorizationFailed
        #endif
        
        #if canImport(FamilyControls)
        print("🔍 Requesting Screen Time authorization...")
        print("   Current status: \(authorizationCenter.authorizationStatus)")
        
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            
            // Check status after request
            checkAuthorizationStatus()
            
            if isAuthorized {
                print("✅ Screen Time authorization granted")
                // Start monitoring automatically after authorization
                startMonitoring()
            } else {
                let error = NSError(
                    domain: "ScreenTimeManager",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Authorization was not granted"]
                )
                authorizationError = error
                throw error
            }
        } catch {
            isAuthorized = false
            authorizationError = error
            let nsError = error as NSError
            let errorDescription = error.localizedDescription.lowercased()
            
            // Check for specific error indicating missing capability
            if errorDescription.contains("couldn't communicate") || 
               errorDescription.contains("helper application") ||
               nsError.domain.contains("FamilyControls") {
                // Mark as unavailable so UI doesn't show button anymore
                isAvailable = false
                
                let capabilityError = NSError(
                    domain: "ScreenTimeManager",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Screen Time requires Apple Developer account. Family Controls capability must be enabled in entitlements."]
                )
                authorizationError = capabilityError
                throw capabilityError
            }
            
            print("❌ Screen Time authorization failed:")
            print("   Domain: \(nsError.domain)")
            print("   Code: \(nsError.code)")
            print("   Description: \(error.localizedDescription)")
            print("   UserInfo: \(nsError.userInfo)")
            throw error
        }
        #endif
    }

    // MARK: - Web Domain Blocking

    /// Block web domains across all browsers
    /// NOTE: This method is now deprecated - use updateBlocks() instead
    /// DeviceActivityMonitor extension handles blocking automatically
    func blockWebDomains(_ domains: [String]) {
        guard isAuthorized else {
            print("❌ Cannot block domains - not authorized")
            return
        }

        // Save domains to App Group - DeviceActivityMonitor will handle blocking
        saveDomainsToAppGroup(domains)
        
        // Ensure monitoring is active
        startMonitoring()
        
        print("✅ Domains saved to App Group - DeviceActivityMonitor will apply shields")
        print("   Domains: \(domains.count)")
    }

    /// Clear all web domain blocks
    /// NOTE: Now handled by DeviceActivityMonitor extension
    /// We clear domains from App Group, and extension will pick it up
    func clearWebDomainBlocks() {
        guard isAuthorized else {
            print("❌ Cannot clear blocks - not authorized")
            return
        }

        // Clear domains from App Group - DeviceActivityMonitor will handle clearing shields
        saveDomainsToAppGroup([])
        
        // Stop monitoring to ensure shields are cleared
        stopMonitoring()
        
        print("✅ Cleared all web domain blocks (via DeviceActivityMonitor)")
    }

    // MARK: - App Blocking

    /// Block specific applications
    func blockApplications(_ applicationTokens: Set<ApplicationToken>) {
        #if !canImport(FamilyControls)
        return
        #endif
        
        guard isAuthorized else {
            print("❌ Cannot block apps - not authorized")
            return
        }

        #if canImport(FamilyControls)
        managedSettingsStore.shield.applications = applicationTokens
        #endif
        print("✅ Blocked \(applicationTokens.count) applications")
    }

    /// Clear all application blocks
    func clearApplicationBlocks() {
        #if !canImport(FamilyControls)
        return
        #endif
        
        guard isAuthorized else {
            print("❌ Cannot clear app blocks - not authorized")
            return
        }

        #if canImport(FamilyControls)
        managedSettingsStore.shield.applications = nil
        #endif
        print("✅ Cleared all application blocks")
    }

    // MARK: - Category Blocking

    /// Block app categories (e.g., Social Networking, Entertainment)
    func blockAppCategories(_ categories: Set<ActivityCategoryToken>) {
        #if !canImport(FamilyControls)
        return
        #endif
        
        guard isAuthorized else {
            print("❌ Cannot block categories - not authorized")
            return
        }

        #if canImport(FamilyControls)
        managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            categories
        )
        #endif

        print("✅ Blocked \(categories.count) app categories")
    }

    /// Clear all category blocks
    func clearCategoryBlocks() {
        #if !canImport(FamilyControls)
        return
        #endif
        
        guard isAuthorized else {
            print("❌ Cannot clear category blocks - not authorized")
            return
        }

        #if canImport(FamilyControls)
        managedSettingsStore.shield.applicationCategories = nil
        #endif
        print("✅ Cleared all category blocks")
    }

    // MARK: - Shield Configuration

    /// Configure the blocking shield appearance and behavior
    func configureShield() {
        guard isAuthorized else { return }

        // The shield configuration determines what happens when user tries to access blocked content
        // Default behavior shows a system shield that can't be bypassed without password

        // Note: Custom shield messages require a DeviceActivityMonitor extension
        // For now, we use the default system shield
    }

    // MARK: - DeviceActivityMonitor Management
    
    /// Start monitoring device activity for blocking
    /// This activates the DeviceActivityMonitor extension which applies shields
    func startMonitoring() {
        #if !canImport(FamilyControls)
        return
        #endif
        
        #if canImport(FamilyControls)
        guard isAuthorized else {
            print("⚠️ Cannot start monitoring - Screen Time not authorized")
            return
        }
        
        // Create a schedule that runs 24/7
        // The schedule determines when the monitor is active
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0), // Start at midnight
            intervalEnd: DateComponents(hour: 23, minute: 59),   // End at 23:59
            repeats: true                                       // Repeat daily
        )
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            print("✅ DeviceActivityMonitor started - blocking will be active 24/7")
        } catch {
            print("❌ Failed to start DeviceActivityMonitor: \(error)")
            authorizationError = error
        }
        #endif
    }
    
    /// Stop monitoring device activity
    func stopMonitoring() {
        #if canImport(FamilyControls)
        deviceActivityCenter.stopMonitoring([activityName])
        print("🛑 DeviceActivityMonitor stopped")
        #endif
    }

    // MARK: - Update All Blocks

    /// Update all Screen Time blocks based on current blocklist
    /// This saves domains to App Group, which DeviceActivityMonitor will pick up
    func updateBlocks(domains: [BlocklistDomain]) {
        guard isAuthorized else {
            print("⚠️ Screen Time not authorized - skipping block update")
            return
        }

        // Extract domain strings
        let domainStrings = domains.map { $0.domain }

        // Save domains to App Group for DeviceActivityMonitor extension
        // The extension will load these and apply shields automatically
        saveDomainsToAppGroup(domainStrings)
        
        // Ensure monitoring is started
        startMonitoring()

        print("✅ Screen Time blocks updated with \(domainStrings.count) domains")
        print("   DeviceActivityMonitor will apply shields automatically")
    }
    
    /// Save blocked domains to App Group for DeviceActivityMonitor
    private func saveDomainsToAppGroup(_ domains: [String]) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.reclaim-app.Reclaim") else {
            print("❌ Failed to access App Group")
            return
        }
        
        sharedDefaults.set(domains, forKey: "blockedDomains")
        sharedDefaults.synchronize()
        
        print("💾 Saved \(domains.count) domains to App Group for DeviceActivityMonitor")
    }

    // MARK: - Clear All Blocks

    /// Remove all Screen Time restrictions
    func clearAllBlocks() {
        guard isAuthorized else { return }

        clearWebDomainBlocks()
        clearApplicationBlocks()
        clearCategoryBlocks()

        print("✅ All Screen Time blocks cleared")
    }

    // MARK: - Errors

    enum ScreenTimeError: LocalizedError {
        case notAuthorized
        case authorizationFailed

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Screen Time authorization is required to block content"
            case .authorizationFailed:
                return "Failed to obtain Screen Time authorization"
            }
        }
    }
}
