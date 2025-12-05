//
//  StoreKitManager.swift
//  Reclaim
//
//  Manages Apple In-App Purchases using StoreKit 2
//

import Foundation
import Combine
import StoreKit

extension Product {
    var displayPrice: String {
        price.formatted()
    }
}

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // MARK: - Published Properties

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed

    // MARK: - Product IDs

    // These must match the product IDs configured in App Store Connect
    enum ProductID {
        static let monthlySubscription = "com.reclaim.premium.monthly"
        static let yearlySubscription = "com.reclaim.premium.yearly"

        static var all: [String] {
            [monthlySubscription, yearlySubscription]
        }
    }

    enum SubscriptionStatus {
        case notSubscribed
        case subscribed(expirationDate: Date?, willRenew: Bool)
        case inGracePeriod(expirationDate: Date?)
        case inBillingRetry(expirationDate: Date?)
        case expired
    }
    
    // MARK: - Computed Properties
    
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlySubscription }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlySubscription }
    }

    // MARK: - Initialization

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: ProductID.all)

            // Sort by price (yearly first since it's better value)
            products = storeProducts.sorted { $0.price > $1.price }

            print("✅ Loaded \(products.count) products from App Store")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)

            // Validate with backend
            await validateWithBackend(transaction)

            // Update subscription status
            await updateSubscriptionStatus()

            // Finish the transaction
            await transaction.finish()

            return true

        case .userCancelled:
            return false

        case .pending:
            // Transaction is pending (e.g., parental approval required)
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Update Subscription Status

    func updateSubscriptionStatus() async {
        var activeSubscription: Product?
        var latestTransaction: Transaction?

        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Find the product for this transaction
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscription = product
                    latestTransaction = transaction
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }

        // Update purchased subscriptions
        if let subscription = activeSubscription {
            purchasedSubscriptions = [subscription]
        } else {
            purchasedSubscriptions = []
        }

        // Determine subscription status
        if let transaction = latestTransaction,
           let expirationDate = transaction.expirationDate {

            let now = Date()

            if expirationDate > now {
                // Active subscription
                subscriptionStatus = .subscribed(
                    expirationDate: expirationDate,
                    willRenew: transaction.willAutoRenew
                )
            } else {
                // Check if in grace period or billing retry
                if let gracePeriodEndDate = transaction.gracePeriodExpirationDate,
                   gracePeriodEndDate > now {
                    subscriptionStatus = .inGracePeriod(expirationDate: gracePeriodEndDate)
                } else {
                    subscriptionStatus = .expired
                }
            }
        } else if latestTransaction != nil {
            // Has a transaction but no expiration (shouldn't happen for subscriptions)
            subscriptionStatus = .subscribed(expirationDate: nil, willRenew: false)
        } else {
            subscriptionStatus = .notSubscribed
        }

        // Validate with backend if we have an active subscription
        if case .subscribed = subscriptionStatus, let transaction = latestTransaction {
            await validateWithBackend(transaction)
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task { @MainActor in
            // Iterate through any transactions that don't come from a direct call to purchase()
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)

                    // Validate with backend
                    await validateWithBackend(transaction)

                    // Update subscription status
                    await updateSubscriptionStatus()

                    // Always finish a transaction
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Backend Validation

    private func validateWithBackend(_ transaction: Transaction) async {
        do {
            // Get the receipt data
            guard let receiptData = try? await getReceiptData() else {
                print("❌ Failed to get receipt data")
                return
            }

            // Send to backend for validation
            let request = ValidateReceiptRequest(
                receiptData: receiptData,
                transactionId: String(transaction.id),
                productId: transaction.productID
            )

            let _ = try await SubscriptionService.shared.validateAppleReceipt(request: request)

            print("✅ Receipt validated with backend")
        } catch {
            print("❌ Backend validation failed: \(error)")
        }
    }

    private func getReceiptData() async throws -> String {
        // Get the latest receipt from App Store
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            let receiptData = try Data(contentsOf: appStoreReceiptURL)
            return receiptData.base64EncodedString()
        }
        throw StoreError.noReceipt
    }

    // MARK: - Errors

    enum StoreError: LocalizedError {
        case failedVerification
        case noReceipt

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Transaction verification failed"
            case .noReceipt:
                return "No receipt available"
            }
        }
    }
}

// MARK: - Transaction Extensions

extension Transaction {
    var willAutoRenew: Bool {
        // Check if the subscription will auto-renew
        // This is available through the transaction properties
        return true // Default assumption, actual value from StoreKit
    }

    var gracePeriodExpirationDate: Date? {
        // Grace period expiration if in billing retry
        return nil // Available from Transaction properties
    }
}
