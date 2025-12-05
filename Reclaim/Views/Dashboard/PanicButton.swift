//
//  PanicButton.swift
//  Reclaim
//
//  Prominent panic button for immediate AI support
//

import SwiftUI
import UIKit

struct PanicButton: View {
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Trigger action
            onTap()
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(ReclaimColors.dangerGradient)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: Color.red.opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("I'm Struggling")
                        .font(ReclaimTypography.h4)
                        .foregroundColor(ReclaimColors.textPrimary)
                    
                    Text("Get immediate support from your AI companion")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(ReclaimColors.danger)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(ReclaimColors.danger.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(ReclaimColors.danger.opacity(0.3), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

#Preview {
    PanicButton(onTap: {})
        .padding()
        .background(ReclaimColors.background)
}

