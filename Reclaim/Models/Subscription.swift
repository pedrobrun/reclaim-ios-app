//
//  Subscription.swift
//  Reclaim
//
//  Subscription and payment models
//

import Foundation

struct SubscriptionInfo: Codable {
    let status: User.SubscriptionStatus
    let periodEnd: Date?
    let isTrialing: Bool
    let trialEnd: Date?
    let billingPeriod: String?
    let cancelAtPeriodEnd: Bool
}

struct CheckoutSession: Codable {
    let url: String
    let sessionId: String
}

struct PortalSession: Codable {
    let url: String
}

// MARK: - Request DTOs

struct CreateCheckoutRequest: Codable {
    let period: BillingPeriod
    let successUrl: String?
    let cancelUrl: String?

    enum BillingPeriod: String, Codable {
        case monthly
        case yearly
    }
}

// MARK: - Apple IAP DTOs

struct ValidateReceiptRequest: Codable {
    let receiptData: String
    let transactionId: String
    let productId: String
}

struct ValidateReceiptResponse: Codable {
    let valid: Bool
    let subscription: SubscriptionInfo?
}
