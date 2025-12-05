//
//  SubscriptionPaywallView.swift
//  Reclaim
//
//  Subscription paywall with Apple In-App Purchase
//

import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    var selectedTemplate: String = "essential"
    var allowDismiss: Bool = false
    var onSubscribe: (() -> Void)?
    
    @StateObject private var storeManager = StoreKitManager.shared
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedPlan: PlanType = .yearly
    @State private var animateCheckmarks = false
    
    enum PlanType {
        case monthly
        case yearly
    }
    
    var body: some View {
        ZStack {
            // Premium background with gradient
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    // Header with close button if allowed
                    if allowDismiss {
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(Spacing.sm)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, Spacing.md)
                    } else {
                        Spacer()
                            .frame(height: Spacing.xl)
                    }
                    
                    // Hero section
                    heroSection
                    
                    // Features list
                    featuresSection
                    
                    // Pricing cards
                    pricingSection
                    
                    // CTA Button
                    subscribeButton
                    
                    // Fine print
                    finePrint
                    
                    Spacer()
                        .frame(height: Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await storeManager.loadProducts()
            // Animate checkmarks after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateCheckmarks = true
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            ReclaimColors.background.ignoresSafeArea()
            
            // Subtle gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "667EEA").opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 60)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "38EF7D").opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 400)
                .blur(radius: 50)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            // Premium badge
            HStack(spacing: Spacing.xs) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("PREMIUM")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
            }
            .foregroundColor(Color(hex: "FFD700"))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(Color(hex: "FFD700").opacity(0.15))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(hex: "FFD700").opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Title
            Text("Unlock Your\nFull Potential")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Subtitle
            Text("Get unlimited access to AI support, advanced blocking, and progress tracking.")
                .font(ReclaimTypography.body)
                .foregroundColor(ReclaimColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: Spacing.sm) {
            FeatureCheckRow(
                text: "24/7 AI companion for urge support",
                isAnimated: animateCheckmarks,
                delay: 0
            )
            
            FeatureCheckRow(
                text: "Block 10,000+ adult sites & apps",
                isAnimated: animateCheckmarks,
                delay: 0.1
            )
            
            FeatureCheckRow(
                text: "Detailed progress analytics",
                isAnimated: animateCheckmarks,
                delay: 0.2
            )
            
            FeatureCheckRow(
                text: "Custom motivational block screens",
                isAnimated: animateCheckmarks,
                delay: 0.3
            )
            
            FeatureCheckRow(
                text: "Relapse prevention strategies",
                isAnimated: animateCheckmarks,
                delay: 0.4
            )
        }
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: Spacing.md) {
            #if DEBUG
            // Debug mode - show mock pricing
            PricingCard(
                planType: .yearly,
                title: "Yearly",
                price: "$99.99",
                perMonth: "$8.33/month",
                savings: "SAVE 44%",
                isSelected: selectedPlan == .yearly,
                onTap: { selectedPlan = .yearly }
            )
            
            PricingCard(
                planType: .monthly,
                title: "Monthly",
                price: "$14.99",
                perMonth: nil,
                savings: nil,
                isSelected: selectedPlan == .monthly,
                onTap: { selectedPlan = .monthly }
            )
            #else
            // Production mode - show real products
            if let monthlyProduct = storeManager.monthlyProduct,
               let yearlyProduct = storeManager.yearlyProduct {
                
                PricingCard(
                    planType: .yearly,
                    title: "Yearly",
                    price: yearlyProduct.displayPrice,
                    perMonth: formatMonthlyPrice(yearlyProduct.price),
                    savings: "SAVE \(calculateSavings(monthly: monthlyProduct, yearly: yearlyProduct) ?? 0)%",
                    isSelected: selectedPlan == .yearly,
                    onTap: { selectedPlan = .yearly }
                )
                
                PricingCard(
                    planType: .monthly,
                    title: "Monthly",
                    price: monthlyProduct.displayPrice,
                    perMonth: nil,
                    savings: nil,
                    isSelected: selectedPlan == .monthly,
                    onTap: { selectedPlan = .monthly }
                )
            } else {
                // Fallback mock while loading
                PricingCard(
                    planType: .yearly,
                    title: "Yearly",
                    price: "$99.99",
                    perMonth: "$8.33/month",
                    savings: "SAVE 44%",
                    isSelected: selectedPlan == .yearly,
                    onTap: { selectedPlan = .yearly }
                )
                
                PricingCard(
                    planType: .monthly,
                    title: "Monthly",
                    price: "$14.99",
                    perMonth: nil,
                    savings: nil,
                    isSelected: selectedPlan == .monthly,
                    onTap: { selectedPlan = .monthly }
                )
            }
            #endif
        }
    }
    
    // MARK: - Subscribe Button
    
    private var subscribeButton: some View {
        Button {
            handleSubscribe()
        } label: {
            HStack(spacing: Spacing.sm) {
                if isPurchasing {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Start Your Journey")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: "667EEA").opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .disabled(isPurchasing)
        .padding(.top, Spacing.md)
    }
    
    // MARK: - Fine Print
    
    private var finePrint: some View {
        VStack(spacing: Spacing.xs) {
            Text("Cancel anytime. No commitment required.")
                .font(ReclaimTypography.caption)
                .foregroundColor(ReclaimColors.textTertiary)
            
            HStack(spacing: Spacing.xs) {
                Button {
                    // Open terms
                } label: {
                    Text("Terms")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textSecondary)
                        .underline()
                }
                
                Text("•")
                    .font(ReclaimTypography.caption)
                    .foregroundColor(ReclaimColors.textTertiary)
                
                Button {
                    // Open privacy
                } label: {
                    Text("Privacy")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textSecondary)
                        .underline()
                }
                
                Text("•")
                    .font(ReclaimTypography.caption)
                    .foregroundColor(ReclaimColors.textTertiary)
                
                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    Text("Restore")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textSecondary)
                        .underline()
                }
            }
        }
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Actions
    
    private func handleSubscribe() {
        #if DEBUG
        subscriptionViewModel.completeDebugPurchase(plan: selectedPlan == .yearly ? "yearly" : "monthly")
        finishSubscription()
        #else
        guard let product = selectedPlan == .yearly ? storeManager.yearlyProduct : storeManager.monthlyProduct else {
            // Fallback for when products haven't loaded
            subscriptionViewModel.completeDebugPurchase(plan: selectedPlan == .yearly ? "yearly" : "monthly")
            finishSubscription()
            return
        }
        purchaseProduct(product)
        #endif
    }
    
    private func finishSubscription() {
        if let onSubscribe = onSubscribe {
            onSubscribe()
        } else {
            dismiss()
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        isPurchasing = true
        errorMessage = ""
        
        Task {
            do {
                let result = try await storeManager.purchase(product)
                if result {
                    await MainActor.run {
                        isPurchasing = false
                        finishSubscription()
                    }
                } else {
                    await MainActor.run {
                        isPurchasing = false
                        errorMessage = "Purchase was cancelled"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func restorePurchases() async {
        do {
            try await storeManager.restorePurchases()
            if case .subscribed = storeManager.subscriptionStatus {
                finishSubscription()
            } else {
                errorMessage = "No active subscriptions found"
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func calculateSavings(monthly: Product, yearly: Product) -> Int? {
        let monthlyYearly = monthly.price * 12
        let savings = ((monthlyYearly - yearly.price) / monthlyYearly) * 100
        return Int(NSDecimalNumber(decimal: savings).doubleValue)
    }
    
    private func formatMonthlyPrice(_ yearlyPrice: Decimal) -> String {
        let monthly = yearlyPrice / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        if let formatted = formatter.string(from: NSDecimalNumber(decimal: monthly)) {
            return "\(formatted)/month"
        }
        return "$8.33/month"
    }
}

// MARK: - Feature Check Row

struct FeatureCheckRow: View {
    let text: String
    let isAnimated: Bool
    let delay: Double
    
    @State private var showCheck = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: "10B981").opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                    .scaleEffect(showCheck ? 1 : 0)
            }
            
            Text(text)
                .font(ReclaimTypography.body)
                .foregroundColor(ReclaimColors.textPrimary)
            
            Spacer()
        }
        .onChange(of: isAnimated) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showCheck = true
                    }
                }
            }
        }
        .onAppear {
            if isAnimated {
                showCheck = true
            }
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let planType: SubscriptionPaywallView.PlanType
    let title: String
    let price: String
    let perMonth: String?
    let savings: String?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color(hex: "667EEA") : ReclaimColors.textTertiary,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "667EEA"))
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Plan info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "10B981"))
                                )
                        }
                    }
                    
                    if let perMonth = perMonth {
                        Text(perMonth)
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Price
                Text(price)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ReclaimColors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                    LinearGradient(
                                        colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [ReclaimColors.border, ReclaimColors.border],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SubscriptionPaywallView()
        .environmentObject(SubscriptionViewModel())
}



