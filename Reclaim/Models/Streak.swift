//
//  Streak.swift
//  Reclaim
//
//  Streak and progress tracking models
//

import Foundation

struct Streak: Codable, Identifiable {
    let id: String
    let daysCount: Int
    let startDate: Date
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
}

// Response DTO matching backend StreakResponseDto
struct StreakResponse: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalCleanDays: Int
    let currentStreakStartDate: String?
    let achievements: [String]
    let totalRelapses: Int
    
    // Computed property to convert to Streak if needed
    var startDate: Date? {
        guard let dateString = currentStreakStartDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
}

struct Achievement: Codable, Identifiable {
    let id: String
    let achievementType: AchievementType
    let name: String
    let description: String
    let daysRequired: Int
    let unlockedAt: Date?
    let createdAt: Date

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    enum AchievementType: String, Codable {
        case milestone
    }
}

struct Analytics: Codable {
    let overall: OverallStats
    let topTriggers: [String: Int]
    let topMoods: [String: Int]
    let recentStreaks: [RecentStreak]
    let achievements: [String: Bool]

    // Convenience properties for backward compatibility
    var currentStreak: Int { overall.currentStreak }
    var longestStreak: Int { overall.longestStreak }
    var totalCleanDays: Int { overall.totalCleanDays }
    var totalRelapses: Int { overall.totalRelapses }
    var successRate: Double { overall.successRate }
    var averageStreakLength: Double { overall.averageStreakLength }
}

struct OverallStats: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalCleanDays: Int
    let totalRelapses: Int
    let averageStreakLength: Double
    let successRate: Double
}

struct RecentStreak: Codable, Identifiable {
    var id: String { date }
    let date: String
    let streakLength: Int
}

struct TriggerCount: Codable, Identifiable {
    var id: String { trigger }
    let trigger: String
    let count: Int
}

struct MoodCount: Codable, Identifiable {
    var id: String { mood }
    let mood: String
    let count: Int
}

// MARK: - Request DTOs

struct LogRelapseRequest: Codable {
    let trigger: String?
    let mood: String?
    let notes: String?
    let relapsedAt: String?

    init(trigger: String?, mood: String?, notes: String?, relapsedAt: Date?) {
        self.trigger = trigger
        self.mood = mood
        self.notes = notes

        if let relapsedAt = relapsedAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.relapsedAt = formatter.string(from: relapsedAt)
        } else {
            self.relapsedAt = nil
        }
    }
}
