//
//  AnalyticsView.swift
//  Reclaim
//
//  Detailed analytics dashboard with charts
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                ReclaimColors.background.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.analytics == nil {
                    ProgressView()
                } else if let analytics = viewModel.analytics {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Overall Stats Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: Spacing.md) {
                                StatCard(
                                    title: "Success Rate",
                                    value: String(format: "%.0f%%", analytics.successRate),
                                    icon: "chart.pie.fill",
                                    color: ReclaimColors.primary
                                )
                                
                                StatCard(
                                    title: "Clean Days",
                                    value: "\(analytics.totalCleanDays)",
                                    icon: "calendar.badge.checkmark",
                                    color: ReclaimColors.success
                                )
                                
                                StatCard(
                                    title: "Avg Streak",
                                    value: String(format: "%.1f days", analytics.averageStreakLength),
                                    icon: "clock.arrow.circlepath",
                                    color: ReclaimColors.info
                                )
                                
                                StatCard(
                                    title: "Relapses",
                                    value: "\(analytics.totalRelapses)",
                                    icon: "exclamationmark.triangle.fill",
                                    color: ReclaimColors.danger
                                )
                            }
                            .padding(.horizontal, Spacing.lg)
                            
                            // Recent Streaks Chart
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Recent Streaks")
                                    .font(ReclaimTypography.h4)
                                    .foregroundColor(ReclaimColors.textPrimary)
                                
                                if #available(iOS 16.0, *) {
                                    Chart(viewModel.getRecentStreaks()) { streak in
                                        BarMark(
                                            x: .value("Date", streak.date),
                                            y: .value("Days", streak.streakLength)
                                        )
                                        .foregroundStyle(ReclaimColors.primaryGradient)
                                        .cornerRadius(4)
                                    }
                                    .frame(height: 200)
                                    .chartYAxis {
                                        AxisMarks(position: .leading)
                                    }
                                } else {
                                    Text("Charts require iOS 16.0+")
                                        .foregroundColor(ReclaimColors.textSecondary)
                                }
                            }
                            .padding(Spacing.lg)
                            .background(ReclaimColors.cardBackground)
                            .cornerRadius(CornerRadius.md)
                            .padding(.horizontal, Spacing.lg)
                            
                            // Top Triggers
                            if !analytics.topTriggers.isEmpty {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    Text("Common Triggers")
                                        .font(ReclaimTypography.h4)
                                        .foregroundColor(ReclaimColors.textPrimary)
                                    
                                    if #available(iOS 16.0, *) {
                                        Chart(viewModel.getTopTriggers()) { item in
                                            BarMark(
                                                x: .value("Count", item.count),
                                                y: .value("Trigger", item.trigger)
                                            )
                                            .foregroundStyle(ReclaimColors.dangerGradient)
                                            .cornerRadius(4)
                                            .annotation(position: .trailing) {
                                                Text("\(item.count)")
                                                    .font(ReclaimTypography.caption)
                                                    .foregroundColor(ReclaimColors.textSecondary)
                                            }
                                        }
                                        .frame(height: CGFloat(analytics.topTriggers.count * 40 + 50))
                                    }
                                }
                                .padding(Spacing.lg)
                                .background(ReclaimColors.cardBackground)
                                .cornerRadius(CornerRadius.md)
                                .padding(.horizontal, Spacing.lg)
                            }
                            
                            // Top Moods
                            if !analytics.topMoods.isEmpty {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    Text("Relapse Moods")
                                        .font(ReclaimTypography.h4)
                                        .foregroundColor(ReclaimColors.textPrimary)
                                    
                                    if #available(iOS 16.0, *) {
                                        Chart(viewModel.getTopMoods()) { item in
                                            BarMark(
                                                x: .value("Count", item.count),
                                                y: .value("Mood", item.mood)
                                            )
                                            .foregroundStyle(ReclaimColors.primaryGradient)
                                            .cornerRadius(4)
                                            .annotation(position: .trailing) {
                                                Text("\(item.count)")
                                                    .font(ReclaimTypography.caption)
                                                    .foregroundColor(ReclaimColors.textSecondary)
                                            }
                                        }
                                        .frame(height: CGFloat(analytics.topMoods.count * 40 + 50))
                                    }
                                }
                                .padding(Spacing.lg)
                                .background(ReclaimColors.cardBackground)
                                .cornerRadius(CornerRadius.md)
                                .padding(.horizontal, Spacing.lg)
                            }
                            
                            Spacer().frame(height: Spacing.xl)
                        }
                        .padding(.vertical, Spacing.lg)
                    }
                } else {
                    // Error or Empty
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundColor(ReclaimColors.textTertiary)
                        Text("No analytics data yet")
                            .font(ReclaimTypography.h3)
                            .foregroundColor(ReclaimColors.textSecondary)
                        Text("Start tracking your streaks to see insights here.")
                            .font(ReclaimTypography.body)
                            .foregroundColor(ReclaimColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadAnalytics()
        }
        .errorAlert($viewModel.error)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(ReclaimTypography.h2)
                .foregroundColor(ReclaimColors.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text(title)
                .font(ReclaimTypography.caption)
                .foregroundColor(ReclaimColors.textSecondary)
        }
        .padding(Spacing.md)
        .background(ReclaimColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

