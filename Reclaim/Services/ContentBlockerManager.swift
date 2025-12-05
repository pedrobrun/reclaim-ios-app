//
//  ContentBlockerManager.swift
//  Reclaim
//
//  Manages Safari Content Blocker extension and syncs blocked domains
//

import Foundation
import SafariServices

class ContentBlockerManager {
    static let shared = ContentBlockerManager()

    // App Group identifier for sharing data with the extension
    private let appGroupIdentifier = "group.reclaim-app.Reclaim"
    private let blockerListFilename = "blockerList.json"

    // Content Blocker extension identifier (must match bundle identifier in Xcode)
    private let contentBlockerIdentifier = "reclaim-app.Reclaim.ReclaimContentBlocker"

    private init() {}

    // MARK: - Update Blocker List

    /// Update the Content Blocker with new domain list
    func updateBlockerList(domains: [BlocklistDomain]) async throws {
        // Convert domains to Content Blocker rules format
        let rules = convertDomainsToRules(domains)

        // Write to shared container
        try writeRulesToSharedContainer(rules)

        // Reload the Content Blocker
        try await reloadContentBlocker()
    }

    // MARK: - Convert Domains to Rules

    private func convertDomainsToRules(_ domains: [BlocklistDomain]) -> [[String: Any]] {
        var rules: [[String: Any]] = []

        for domain in domains {
            // Create a blocking rule for each domain
            let rule: [String: Any] = [
                "action": [
                    "type": "block"
                ],
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": ["*\(domain.domain)"]
                ]
            ]

            rules.append(rule)
        }

        return rules
    }

    // MARK: - Write to Shared Container

    private func writeRulesToSharedContainer(_ rules: [[String: Any]]) throws {
        guard let sharedContainerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw ContentBlockerError.sharedContainerNotFound
        }

        let blockerListURL = sharedContainerURL.appendingPathComponent(blockerListFilename)

        // Convert rules to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: rules, options: .prettyPrinted)

        // Write to file
        try jsonData.write(to: blockerListURL, options: .atomic)

        print("✅ Content Blocker list updated with \(rules.count) rules")
        print("📁 Written to: \(blockerListURL.path)")
    }

    // MARK: - Reload Content Blocker

    private func reloadContentBlocker() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            SFContentBlockerManager.reloadContentBlocker(
                withIdentifier: contentBlockerIdentifier
            ) { error in
                if let error = error {
                    let nsError = error as NSError
                    print("⚠️ Error reloading Content Blocker:")
                    print("   Domain: \(nsError.domain)")
                    print("   Code: \(nsError.code)")
                    print("   Description: \(error.localizedDescription)")
                    
                    // SFErrorDomain error 1: Content Blocker not enabled
                    // SFErrorDomain error 3: Usually means extension is busy or JSON issue (non-critical)
                    if nsError.domain == "SFErrorDomain" {
                        if nsError.code == 1 {
                            print("⚠️ Content Blocker not enabled. Please enable it in Settings → Safari → Extensions")
                            // Don't throw error - just log it
                            continuation.resume()
                        } else if nsError.code == 3 {
                            print("⚠️ Content Blocker reload failed (error 3) - extension may be busy or updating")
                            print("   This is usually non-critical. The blocker will update automatically.")
                            // Don't throw error - extension will reload automatically
                            continuation.resume()
                        } else {
                            print("❌ Failed to reload Content Blocker: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    } else {
                        print("❌ Failed to reload Content Blocker: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else {
                    print("✅ Content Blocker reloaded successfully")
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Check if Content Blocker is Enabled

    func getContentBlockerState() async throws -> SFContentBlockerState {
        print("🔍 Checking Content Blocker state with identifier: \(contentBlockerIdentifier)")
        return try await withCheckedThrowingContinuation { continuation in
            SFContentBlockerManager.getStateOfContentBlocker(
                withIdentifier: contentBlockerIdentifier
            ) { state, error in
                if let error = error {
                    let nsError = error as NSError
                    print("❌ Error checking Content Blocker state:")
                    print("   Domain: \(nsError.domain)")
                    print("   Code: \(nsError.code)")
                    print("   Description: \(error.localizedDescription)")
                    
                    // SFErrorDomain error 1 usually means Content Blocker is not enabled
                    // This is expected in simulator - user needs to enable it in Settings
                    if nsError.domain == "SFErrorDomain" && nsError.code == 1 {
                        print("⚠️ Content Blocker not enabled. Please enable it in Settings → Safari → Extensions")
                        // Throw a custom error that can be handled gracefully
                        continuation.resume(throwing: ContentBlockerError.notEnabled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let state = state {
                    print("✅ Content Blocker state retrieved:")
                    print("   isEnabled: \(state.isEnabled)")
                    continuation.resume(returning: state)
                } else {
                    print("❌ No state returned from Content Blocker")
                    continuation.resume(throwing: ContentBlockerError.unknownError)
                }
            }
        }
    }

    // MARK: - Errors

    enum ContentBlockerError: LocalizedError {
        case sharedContainerNotFound
        case notEnabled
        case unknownError

        var errorDescription: String? {
            switch self {
            case .sharedContainerNotFound:
                return "Could not access shared container for Content Blocker"
            case .notEnabled:
                return "Content Blocker is not enabled. Please enable it in Settings → Safari → Extensions"
            case .unknownError:
                return "An unknown error occurred with Content Blocker"
            }
        }
    }
}
