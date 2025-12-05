//
//  ProgressDashboardView.swift
//  Reclaim
//
//  Detailed analytics and progress tracking
//

import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            ReclaimColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    HStack {
                        Text("Your Progress")
                            .font(ReclaimTypography.h2)
                            .foregroundColor(ReclaimColors.textPrimary)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ReclaimColors.textSecondary)
                                .padding(Spacing.sm)
                                .background(ReclaimColors.backgroundSecondary)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                    // Current Streak
                    if let streak = viewModel.currentStreak {
                        StreakCard(streak: streak)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Stats Grid
                    if let analytics = viewModel.analytics {
                        StatsGrid(analytics: analytics)
                            .padding(.horizontal, Spacing.lg)

                        // Achievements Section
                        AchievementsSection(analytics: analytics)
                            .padding(.horizontal, Spacing.lg)

                        // Success Rate Chart
                        SuccessRateCard(analytics: analytics)
                            .padding(.horizontal, Spacing.lg)
                    }

                    Spacer()
                }
                .padding(.bottom, Spacing.lg)
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Achievements Section

struct AchievementsSection: View {
    let analytics: Analytics

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Achievements")
                .font(ReclaimTypography.h4)
                .foregroundColor(ReclaimColors.textPrimary)

            VStack(spacing: Spacing.sm) {
                AchievementRow(
                    name: "First Day",
                    description: "Complete 1 day clean",
                    isUnlocked: analytics.achievements["first_day"] ?? false
                )
                AchievementRow(
                    name: "First Week",
                    description: "Complete 7 days clean",
                    isUnlocked: analytics.achievements["first_week"] ?? false
                )
                AchievementRow(
                    name: "30 Days",
                    description: "Complete 30 days clean",
                    isUnlocked: analytics.achievements["30_days"] ?? false
                )
                AchievementRow(
                    name: "60 Days",
                    description: "Complete 60 days clean",
                    isUnlocked: analytics.achievements["60_days"] ?? false
                )
                AchievementRow(
                    name: "90 Days",
                    description: "Complete 90 days clean",
                    isUnlocked: analytics.achievements["90_days"] ?? false
                )
                AchievementRow(
                    name: "6 Months",
                    description: "Complete 180 days clean",
                    isUnlocked: analytics.achievements["6_months"] ?? false
                )
                AchievementRow(
                    name: "1 Year",
                    description: "Complete 365 days clean",
                    isUnlocked: analytics.achievements["1_year"] ?? false
                )
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }
}

struct AchievementRow: View {
    let name: String
    let description: String
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? ReclaimColors.successGradient : LinearGradient(colors: [ReclaimColors.backgroundTertiary], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 44)

                Image(systemName: isUnlocked ? "checkmark" : "lock.fill")
                    .foregroundColor(isUnlocked ? .white : ReclaimColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(ReclaimTypography.label)
                    .foregroundColor(isUnlocked ? ReclaimColors.textPrimary : ReclaimColors.textTertiary)

                Text(description)
                    .font(ReclaimTypography.caption)
                    .foregroundColor(ReclaimColors.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(ReclaimColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Success Rate Card

struct SuccessRateCard: View {
    let analytics: Analytics

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Overall Stats")
                .font(ReclaimTypography.h4)
                .foregroundColor(ReclaimColors.textPrimary)

            VStack(spacing: Spacing.sm) {
                StatRow(label: "Success Rate", value: "\(Int(analytics.successRate))%")
                StatRow(label: "Longest Streak", value: "\(analytics.longestStreak) days")
                StatRow(label: "Total Clean Days", value: "\(analytics.totalCleanDays) days")
                StatRow(label: "Average Streak", value: String(format: "%.1f days", analytics.averageStreakLength))
            }
        }
        .padding(Spacing.md)
        .glassCard()
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(ReclaimTypography.body)
                .foregroundColor(ReclaimColors.textSecondary)

            Spacer()

            Text(value)
                .font(ReclaimTypography.labelLarge)
                .foregroundColor(ReclaimColors.textPrimary)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    ProgressDashboardView()
}
