//
//  ReclaimApp.swift
//  Reclaim
//
//  Main app entry point
//

import SwiftUI

@main
struct ReclaimApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @State private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    if hasCompletedOnboarding {
                        if subscriptionViewModel.isSubscribed {
                            DashboardView()
                                .environmentObject(authService)
                                .environmentObject(subscriptionViewModel)
                                .onAppear {
                                    NotificationManager.shared.requestAuthorization()
                                }
                        } else {
                            SubscriptionPaywallView(
                                allowDismiss: false,
                                onSubscribe: {
                                    // No-op: ViewModel should update automatically via listener
                                }
                            )
                            .environmentObject(subscriptionViewModel)
                        }
                    } else {
                        OnboardingView()
                            .environmentObject(authService)
                            .environmentObject(subscriptionViewModel)
                            .onAppear {
                                // Listen for onboarding completion
                                NotificationCenter.default.addObserver(
                                    forName: NSNotification.Name("OnboardingCompleted"),
                                    object: nil,
                                    queue: .main
                                ) { _ in
                                    hasCompletedOnboarding = true
                                    // No need to force reload status here as the purchase flow
                                    // or mock debug flow already updated the ViewModel
                                }
                            }
                    }
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
            .onAppear {
                // Load subscription status on app launch
                Task {
                    await subscriptionViewModel.loadSubscriptionStatus()
                }
            }
            .onChange(of: authService.isAuthenticated) { isAuthenticated in
                // Reset onboarding state when user logs in/out
                // This ensures new users see onboarding even if previous user completed it
                if isAuthenticated {
                    // Check if this user has completed onboarding
                    hasCompletedOnboarding = UserDefaultsManager.shared.hasCompletedOnboarding
                } else {
                    // User logged out, reset onboarding state
                    hasCompletedOnboarding = false
                }
            }
            .onChange(of: authService.currentUser?.id) { userId in
                // When user changes (new login/register), reset onboarding
                if userId != nil {
                    // Reset to false so new users see onboarding
                    hasCompletedOnboarding = false
                }
            }
        }
    }
}
