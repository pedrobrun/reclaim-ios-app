//
//  SubscriptionViewModel.swift
//  Reclaim
//
//  ViewModel for subscription state and paywall management
//

import Foundation
import Combine

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var showPaywall = false
    @Published var isSubscribed = false
    @Published var subscriptionInfo: SubscriptionInfo?
    @Published var isLoading = false
    @Published var error: Error?

    private let storeManager = StoreKitManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe StoreKit subscription status
        storeManager.$subscriptionStatus
            .sink { [weak self] status in
                self?.updateSubscriptionState(status)
            }
            .store(in: &cancellables)
            
    }

    // MARK: - Update Subscription State

    private func updateSubscriptionState(_ status: StoreKitManager.SubscriptionStatus) {
        switch status {
        case .subscribed(let expirationDate, let willRenew):
            isSubscribed = true
            subscriptionInfo = SubscriptionInfo(
                status: .active,
                periodEnd: expirationDate,
                isTrialing: false,
                trialEnd: nil,
                billingPeriod: nil,
                cancelAtPeriodEnd: !willRenew
            )

        case .inGracePeriod(let expirationDate):
            isSubscribed = true
            subscriptionInfo = SubscriptionInfo(
                status: .active,
                periodEnd: expirationDate,
                isTrialing: false,
                trialEnd: nil,
                billingPeriod: nil,
                cancelAtPeriodEnd: true
            )

        case .inBillingRetry(let expirationDate):
            isSubscribed = false
            subscriptionInfo = SubscriptionInfo(
                status: .pastDue,
                periodEnd: expirationDate,
                isTrialing: false,
                trialEnd: nil,
                billingPeriod: nil,
                cancelAtPeriodEnd: true
            )

        case .expired, .notSubscribed:
            isSubscribed = false
            subscriptionInfo = nil
        }
    }

    // MARK: - Show Paywall

    func requireSubscription() {
        if !isSubscribed {
            showPaywall = true
        }
    }

    // MARK: - Load Subscription Status

    func loadSubscriptionStatus() async {
        isLoading = true
        error = nil

        // Force update from StoreKit
        await storeManager.updateSubscriptionStatus()

        isLoading = false
    }

#if DEBUG
    func completeDebugPurchase(plan: String) {
        isSubscribed = true
        showPaywall = false
        subscriptionInfo = SubscriptionInfo(
            status: .active,
            periodEnd: nil,
            isTrialing: false,
            trialEnd: nil,
            billingPeriod: plan,
            cancelAtPeriodEnd: false
        )
        print("⚡️ DEBUG: Simulated \(plan) subscription unlocked")
    }
#endif
}
