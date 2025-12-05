//
//  SetYourWhyStepView.swift
//  Reclaim
//
//  Optional step to set user's motivation
//

import SwiftUI

struct SetYourWhyStepView: View {
    @Binding var whyText: String
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    private let placeholder = "Why do you want to quit? What are you fighting for?\n\nThis will help remind you when things get tough..."
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: Spacing.md) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ReclaimColors.primary)
                
                Text("Set Your Why")
                    .font(ReclaimTypography.h1)
                    .foregroundColor(ReclaimColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Remind yourself why you're on this journey. This will help you stay strong when things get tough.")
                    .font(ReclaimTypography.body)
                    .foregroundColor(ReclaimColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            // Text Editor
            ZStack(alignment: .topLeading) {
                if whyText.isEmpty {
                    Text(placeholder)
                        .font(ReclaimTypography.body)
                        .foregroundColor(ReclaimColors.textTertiary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.md)
                }
                
                TextEditor(text: $whyText)
                    .font(ReclaimTypography.body)
                    .foregroundColor(ReclaimColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(ReclaimColors.backgroundSecondary)
                    .cornerRadius(CornerRadius.md)
                    .frame(minHeight: 200)
            }
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
            
            // Buttons
            VStack(spacing: Spacing.md) {
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .modifier(PrimaryButtonStyle())
                }
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .modifier(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
}

#Preview {
    SetYourWhyStepView(
        whyText: .constant(""),
        onContinue: {},
        onSkip: {}
    )
}

