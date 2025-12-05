//
//  StreakService.swift
//  Reclaim
//
//  Streak and progress tracking service
//

import Foundation

class StreakService {
    static let shared = StreakService()
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Get Current Streak

    func getCurrentStreak() async throws -> StreakResponse {
        return try await apiClient.request(.getCurrentStreak)
    }

    // MARK: - Log Relapse

    func logRelapse(trigger: String?, mood: String?, notes: String?, relapsedAt: Date?) async throws -> StreakResponse {
        let request = LogRelapseRequest(trigger: trigger, mood: mood, notes: notes, relapsedAt: relapsedAt)
        return try await apiClient.request(.logRelapse, body: request)
    }

    // MARK: - Get Analytics

    func getAnalytics() async throws -> Analytics {
        return try await apiClient.request(.getAnalytics)
    }
}
