//
//  Config.swift
//  Reclaim
//
//  App configuration based on build environment
//

import Foundation

enum Config {
    // MARK: - Backend URL

    nonisolated static var apiBaseURL: String {
        #if DEBUG
        // Check if running on simulator or physical device
        #if targetEnvironment(simulator)
        // Simulator: use localhost
        return "http://localhost:3000/api/v1"
        #else
        // Physical Device: use your Mac's local IP address
        // TODO: Replace with your Mac's IP address (find it with: ifconfig | grep "inet " | grep -v 127.0.0.1)
        // Example: return "http://192.168.1.5:3000/api/v1"
        
        // Try to get IP from environment variable first (useful for CI/CD)
        if let customIP = ProcessInfo.processInfo.environment["RECLAIM_API_IP"] {
            return "http://\(customIP):3000/api/v1"
        }
        
        // Default fallback - your Mac's local IP address
        // Find your Mac's IP: System Settings > Network > Wi-Fi > Details (or run: ipconfig getifaddr en0)
        return "http://192.168.18.37:3000/api/v1"
        #endif
        #else
        // PRODUCTION: Replace with your Railway backend URL
        // Example: "https://reclaim-api-production.up.railway.app/api/v1"
        // Get your Railway URL from: Railway Dashboard → Your Service → Settings → Domains
        return "https://api.reclaim.app/api/v1"  // TODO: Update with Railway URL
        #endif
    }

    // MARK: - App Settings

    static let appName = "Reclaim"
    static let appGroupIdentifier = "group.reclaim-app.Reclaim"

    // MARK: - Feature Flags

    nonisolated static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    nonisolated static var enableLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
