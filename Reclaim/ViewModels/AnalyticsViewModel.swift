//
//  AnalyticsViewModel.swift
//  Reclaim
//
//  ViewModel for analytics dashboard
//

import Foundation
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var analytics: Analytics?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service = StreakService.shared
    
    func loadAnalytics() async {
        isLoading = true
        error = nil
        
        do {
            analytics = try await service.getAnalytics()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // Helper to convert dictionary to array for charts
    func getTopTriggers() -> [TriggerCount] {
        guard let analytics = analytics else { return [] }
        return analytics.topTriggers.map { TriggerCount(trigger: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    func getTopMoods() -> [MoodCount] {
        guard let analytics = analytics else { return [] }
        return analytics.topMoods.map { MoodCount(mood: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    func getRecentStreaks() -> [RecentStreak] {
        guard let analytics = analytics else { return [] }
        // Parse date strings and sort chronologically
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate] // Assuming YYYY-MM-DD
        
        // If simple date format YYYY-MM-DD
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        
        return analytics.recentStreaks.sorted { s1, s2 in
            // Try to parse dates, default to string comparison
            let d1 = simpleFormatter.date(from: s1.date) ?? Date()
            let d2 = simpleFormatter.date(from: s2.date) ?? Date()
            return d1 < d2
        }
    }
}






