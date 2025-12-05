//
//  WelcomeStepView.swift
//  Reclaim
//
//  First step of onboarding - welcome screen
//

import SwiftUI

struct WelcomeStepView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Logo and Icon
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(ReclaimColors.primaryGradient)
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                
                Text("Welcome to Reclaim")
                    .font(ReclaimTypography.h1)
                    .foregroundColor(ReclaimColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Break free from pornography addiction with intelligent blocking, AI support, and progress tracking.")
                    .font(ReclaimTypography.body)
                    .foregroundColor(ReclaimColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
            
            // Features
            VStack(spacing: Spacing.md) {
                OnboardingFeatureRow(
                    icon: "shield.fill",
                    title: "Smart Blocking",
                    description: "Blocks porn sites across all browsers"
                )
                
                OnboardingFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Companion",
                    description: "24/7 support when you need it most"
                )
                
                OnboardingFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Tracking",
                    description: "See your recovery journey"
                )
            }
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
            
            // Continue Button
            Button {
                onContinue()
            } label: {
                Text("Get Started")
                    .modifier(PrimaryButtonStyle())
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(ReclaimColors.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(ReclaimTypography.labelLarge)
                    .foregroundColor(ReclaimColors.textPrimary)
                
                Text(description)
                    .font(ReclaimTypography.bodySmall)
                    .foregroundColor(ReclaimColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(ReclaimColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    WelcomeStepView(onContinue: {})
}

