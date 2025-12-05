//
//  DashboardViewModel.swift
//  Reclaim
//
//  ViewModel for the main dashboard
//

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentStreak: StreakResponse?
    @Published var analytics: Analytics?
    @Published var subscriptionInfo: SubscriptionInfo?

    @Published var isLoading = false
    @Published var error: Error?

    private let streakService = StreakService.shared
    private let subscriptionService = SubscriptionService.shared

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        error = nil

        // Load data concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadStreak() }
            group.addTask { await self.loadAnalytics() }
            group.addTask { await self.loadSubscription() }
        }

        isLoading = false
    }

    private func loadStreak() async {
        do {
            currentStreak = try await streakService.getCurrentStreak()
        } catch {
            // Ignore cancellation errors (code -999) - these are normal when navigating away
            if isCancellationError(error) {
                return
            }
            print("Failed to load streak: \(error)")
        }
    }

    private func loadAnalytics() async {
        do {
            analytics = try await streakService.getAnalytics()
        } catch {
            // Ignore cancellation errors (code -999) - these are normal when navigating away
            if isCancellationError(error) {
                return
            }
            print("Failed to load analytics: \(error)")
        }
    }

    private func loadSubscription() async {
        do {
            subscriptionInfo = try await subscriptionService.getSubscriptionStatus()
        } catch {
            // Ignore cancellation errors (code -999) - these are normal when navigating away
            if isCancellationError(error) {
                return
            }
            print("Failed to load subscription: \(error)")
        }
    }
    
    // MARK: - Helper
    
    private func isCancellationError(_ error: Error) -> Bool {
        // Check if it's a direct URLError cancellation
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        // Check if it's an APIError.networkError wrapping a URLError cancellation
        if case .networkError(let underlyingError) = error as? APIError,
           let urlError = underlyingError as? URLError,
           urlError.code == .cancelled {
            return true
        }
        return false
    }

    // MARK: - Log Relapse

    func logRelapse(trigger: String?, mood: String?, notes: String?, relapsedAt: Date?) async {
        isLoading = true
        error = nil

        do {
            currentStreak = try await streakService.logRelapse(
                trigger: trigger,
                mood: mood,
                notes: notes,
                relapsedAt: relapsedAt
            )

            // Reload analytics
            await loadAnalytics()
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
