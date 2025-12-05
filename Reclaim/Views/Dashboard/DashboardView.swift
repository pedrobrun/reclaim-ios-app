//
//  DashboardView.swift
//  Reclaim
//
//  Main dashboard screen
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @State private var showAIChat = false
    @State private var showBlocklist = false
    @State private var showProgress = false
    @State private var showLogRelapse = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ReclaimColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        if let user = authService.currentUser {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    Text("Welcome back,")
                                        .font(ReclaimTypography.body)
                                        .foregroundColor(ReclaimColors.textSecondary)
                                    Text(user.name)
                                        .font(ReclaimTypography.h3)
                                        .foregroundColor(ReclaimColors.textPrimary)
                                }
                                Spacer()

                                // Profile button
                                Button {
                                    authService.logout()
                                } label: {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                        .foregroundColor(ReclaimColors.textSecondary)
                                        .padding(Spacing.sm)
                                        .background(ReclaimColors.backgroundSecondary)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)
                        }
                        
                        // Panic Button - Prominent, always visible
                        PanicButton {
                            performPremiumAction {
                                showAIChat = true
                            }
                        }
                        .padding(.horizontal, Spacing.lg)

                        // Current Streak Card
                        if let streak = viewModel.currentStreak {
                            StreakCard(streak: streak)
                                .padding(.horizontal, Spacing.lg)
                        }

                        // Log Relapse button
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Slip up? Log it and keep moving forward.")
                                .font(ReclaimTypography.caption)
                                .foregroundColor(ReclaimColors.textSecondary)
                                .padding(.horizontal, Spacing.lg)

                            Button {
                                showLogRelapse = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.uturn.left.circle.fill")
                                    Text("Log a Relapse")
                                        .fontWeight(.semibold)
                                }
                                .primaryButton()
                            }
                            .padding(.horizontal, Spacing.lg)
                        }

                        // Analytics
                        if let analytics = viewModel.analytics {
                            Button {
                                performPremiumAction {
                                    showProgress = true
                                }
                            } label: {
                                StatsGrid(analytics: analytics)
                            }
                            .padding(.horizontal, Spacing.lg)
                        }
                        
                        // Bottom padding for floating menu
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top, Spacing.xs)
                }
                .refreshable {
                    await viewModel.loadData()
                }
                
                // Floating Quick Actions Menu
                VStack {
                    Spacer()
                    
                    FloatingQuickActionsMenu(
                        onAIChat: { performPremiumAction { showAIChat = true } },
                        onBlocklist: { performPremiumAction { showBlocklist = true } },
                        onProgress: { performPremiumAction { showProgress = true } }
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadData()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAIChat) {
            AIChatView(initialMessage: "I'm struggling right now")
        }
        .sheet(isPresented: $showBlocklist) {
            BlocklistView()
        }
        .sheet(isPresented: $showProgress) {
            AnalyticsView()
        }
        .sheet(isPresented: $showLogRelapse) {
            LogRelapseSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $subscriptionViewModel.showPaywall) {
            SubscriptionPaywallView(allowDismiss: true)
                .environmentObject(subscriptionViewModel)
        }
    }
    
    private func performPremiumAction(_ action: () -> Void) {
        if subscriptionViewModel.isSubscribed {
            action()
        } else {
            subscriptionViewModel.requireSubscription()
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: StreakResponse

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Badge - show if streak is active (currentStreak > 0)
            if streak.currentStreak > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("ACTIVE STREAK")
                        .font(ReclaimTypography.labelSmall)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(ReclaimColors.warningGradient)
                .cornerRadius(CornerRadius.xs)
            }

            // Streak count with gradient
            ZStack {
                // Glow effect
                Text("\(streak.currentStreak)")
                    .font(ReclaimTypography.displayLarge)
                    .foregroundStyle(ReclaimColors.successGradient)
                    .blur(radius: 20)

                // Main number
                Text("\(streak.currentStreak)")
                    .font(ReclaimTypography.displayLarge)
                    .foregroundStyle(ReclaimColors.successGradient)
            }

            Text(streak.currentStreak == 1 ? "Day Clean" : "Days Clean")
                .font(ReclaimTypography.h4)
                .foregroundColor(ReclaimColors.textPrimary)

            // Progress indicator (visual element)
            HStack(spacing: Spacing.xxs) {
                ForEach(0..<min(streak.currentStreak, 7), id: \.self) { _ in
                    Circle()
                        .fill(ReclaimColors.successGradient)
                        .frame(width: 6, height: 6)
                }
                if streak.currentStreak > 7 {
                    Text("+\(streak.currentStreak - 7)")
                        .font(ReclaimTypography.captionSmall)
                        .foregroundColor(ReclaimColors.textSecondary)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .glassCard()
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let analytics: Analytics

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                StatBox(
                    title: "Longest Streak",
                    value: "\(analytics.longestStreak)",
                    unit: "days",
                    icon: "trophy.fill",
                    gradient: LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                StatBox(
                    title: "Total Clean Days",
                    value: "\(analytics.totalCleanDays)",
                    unit: "days",
                    icon: "calendar.badge.checkmark",
                    gradient: ReclaimColors.successGradient
                )
            }

            HStack(spacing: Spacing.md) {
                StatBox(
                    title: "Success Rate",
                    value: "\(Int(analytics.successRate))",
                    unit: "%",
                    icon: "chart.line.uptrend.xyaxis",
                    gradient: ReclaimColors.primaryGradient
                )

                StatBox(
                    title: "Achievements",
                    value: "\(analytics.achievements.values.filter { $0 }.count)",
                    unit: "/\(analytics.achievements.count)",
                    icon: "star.fill",
                    gradient: LinearGradient(
                        colors: [Color(hex: "A855F7"), Color(hex: "EC4899")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(ReclaimTypography.h3)
                    .foregroundColor(ReclaimColors.textPrimary)
                Text(unit)
                    .font(ReclaimTypography.caption)
                    .foregroundColor(ReclaimColors.textTertiary)
            }

            // Title
            Text(title)
                .font(ReclaimTypography.labelSmall)
                .foregroundColor(ReclaimColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .padding(Spacing.md)
        .cardStyle()
    }
}

// MARK: - Floating Quick Actions Menu

struct FloatingQuickActionsMenu: View {
    let onAIChat: () -> Void
    let onBlocklist: () -> Void
    let onProgress: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            FloatingActionButton(
                title: "AI Chat",
                icon: "sparkles",
                gradient: ReclaimColors.primaryGradient,
                action: onAIChat
            )
            
            FloatingActionButton(
                title: "Blocklist",
                icon: "shield.fill",
                gradient: ReclaimColors.dangerGradient,
                action: onBlocklist
            )
            
            FloatingActionButton(
                title: "Progress",
                icon: "chart.bar.fill",
                gradient: ReclaimColors.successGradient,
                action: onProgress
            )
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(ReclaimColors.backgroundSecondary)
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(ReclaimColors.border, lineWidth: 1)
        )
    }
}

struct FloatingActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: Color.purple.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Title
                Text(title)
                    .font(ReclaimTypography.caption)
                    .foregroundColor(ReclaimColors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthService.shared)
}
