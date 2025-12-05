//
//  SubscriptionService.swift
//  Reclaim
//
//  Subscription and payment service
//

import Foundation

class SubscriptionService {
    static let shared = SubscriptionService()
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Create Checkout Session

    func createCheckoutSession(period: CreateCheckoutRequest.BillingPeriod) async throws -> CheckoutSession {
        let request = CreateCheckoutRequest(
            period: period,
            successUrl: nil, // iOS deep link handling
            cancelUrl: nil
        )
        return try await apiClient.request(.createCheckout, body: request)
    }

    // MARK: - Get Customer Portal

    func getCustomerPortal() async throws -> PortalSession {
        return try await apiClient.request(.getPortal)
    }

    // MARK: - Get Subscription Status

    func getSubscriptionStatus() async throws -> SubscriptionInfo {
        return try await apiClient.request(.getSubscriptionStatus)
    }
    
    // MARK: - Validate Apple Receipt
    
    func validateAppleReceipt(request: ValidateReceiptRequest) async throws -> ValidateReceiptResponse {
        return try await apiClient.request(.validateAppleReceipt, body: request)
    }
}
