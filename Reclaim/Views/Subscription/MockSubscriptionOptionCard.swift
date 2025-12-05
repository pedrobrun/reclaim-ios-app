//
//  MockSubscriptionOptionCard.swift
//  Reclaim
//
//  Visual mock for subscription card during development
//

import SwiftUI

struct MockSubscriptionOptionCard: View {
    let title: String
    let description: String
    let price: String
    let subPrice: String?
    let savings: String?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(title)
                                .font(ReclaimTypography.h4)
                                .foregroundColor(ReclaimColors.textPrimary)
                            
                            if let savings = savings {
                                Text(savings)
                                    .font(ReclaimTypography.captionSmall)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, 4)
                                    .background(ReclaimColors.success)
                                    .cornerRadius(CornerRadius.xs)
                            }
                        }
                        
                        Text(description)
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text(price)
                            .font(ReclaimTypography.h3)
                            .foregroundColor(ReclaimColors.textPrimary)
                        
                        if let subPrice = subPrice {
                            Text(subPrice)
                                .font(ReclaimTypography.caption)
                                .foregroundColor(ReclaimColors.textTertiary)
                        }
                    }
                }
                
                Text("Subscribe")
                    .font(ReclaimTypography.label)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(ReclaimColors.primaryGradient)
                    .cornerRadius(CornerRadius.md)
            }
            .padding(Spacing.md)
            .background(ReclaimColors.backgroundSecondary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        title == "Yearly" ? ReclaimColors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

