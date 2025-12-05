//
//  BlocklistViewModel.swift
//  Reclaim
//
//  ViewModel for blocklist management
//

import Foundation
import Combine

@MainActor
class BlocklistViewModel: ObservableObject {
    @Published var domains: [BlocklistDomain] = []
    @Published var templates: [BlocklistTemplate] = []
    @Published var appliedTemplates: Set<String> = []

    @Published var isLoading = false
    @Published var isApplyingTemplate = false
    @Published var error: Error?

    private let blocklistService = BlocklistService.shared
    private let contentBlockerManager = ContentBlockerManager.shared
    private var screenTimeManager: ScreenTimeManager? {
        if #available(iOS 16.0, *) {
            return ScreenTimeManager.shared
        }
        return nil
    }

    // MARK: - Load Blocklist

    func loadBlocklist() async {
        isLoading = true
        error = nil

        do {
            domains = try await blocklistService.getDomains()
            templates = try await blocklistService.getTemplates()

            // Update Safari Content Blocker with all domains
            await updateContentBlocker()

            // Check which templates are applied by checking if their domains exist
            // For now, we'll just track them locally
        } catch {
            self.error = error
            print("Failed to load blocklist: \(error)")
        }

        isLoading = false
    }

    // MARK: - Add Domain

    func addDomain(_ domain: String) async {
        isLoading = true
        error = nil

        do {
            let newDomain = try await blocklistService.addDomain(domain)
            domains.append(newDomain)

            // Update Safari Content Blocker
            await updateContentBlocker()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Remove Domain

    func removeDomain(_ id: String) async {
        isLoading = true
        error = nil

        do {
            try await blocklistService.deleteDomain(id)
            domains.removeAll { $0.id == id }

            // Update Safari Content Blocker
            await updateContentBlocker()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Toggle Template

    func toggleTemplate(_ templateId: String) async {
        error = nil

        do {
            if appliedTemplates.contains(templateId) {
                // Remove template - would need backend endpoint
                appliedTemplates.remove(templateId)
            } else {
                // Apply template
                isApplyingTemplate = true

                // Apply template and reload domains in sequence
                try await blocklistService.applyTemplate(templateId)
                appliedTemplates.insert(templateId)

                // Small delay to let backend finish saving
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

                // Reload domains before clearing loading state to prevent UI flash
                let newDomains = try await blocklistService.getDomains()

                // Update domains and clear loading state atomically
                domains = newDomains
                isApplyingTemplate = false

                // Update Safari Content Blocker with new domains
                try await updateContentBlocker()
            }
        } catch {
            self.error = error
            isApplyingTemplate = false
        }
    }

    // MARK: - Update Content Blocker

    private func updateContentBlocker() async {
        do {
            // Update Safari Content Blocker with current domains
            try await contentBlockerManager.updateBlockerList(domains: domains)
        } catch {
            // Log but don't fail - Content Blocker errors are often non-critical
            // (e.g., extension busy, already updating, etc.)
            print("⚠️ Failed to update Content Blocker (non-critical): \(error)")
            // Don't throw - the blocker will update automatically
        }

        // Update Screen Time blocks if authorized (iOS 16+)
        if #available(iOS 16.0, *) {
            screenTimeManager?.updateBlocks(domains: domains)
        }
    }
}
