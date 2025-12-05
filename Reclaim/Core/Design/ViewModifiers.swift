//
//  ViewModifiers.swift
//  Reclaim
//
//  Reusable view modifiers for consistent UI
//

import SwiftUI

// MARK: - Button Styles

struct PrimaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(ReclaimTypography.labelLarge)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isEnabled ?
                    ReclaimColors.primaryGradient :
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .cornerRadius(CornerRadius.md)
            .shadow(
                color: isEnabled ? Color.purple.opacity(0.3) : Color.clear,
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ReclaimTypography.labelLarge)
            .fontWeight(.semibold)
            .foregroundColor(ReclaimColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(ReclaimColors.backgroundTertiary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(ReclaimColors.border, lineWidth: 1)
            )
    }
}

struct GhostButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ReclaimTypography.label)
            .fontWeight(.medium)
            .foregroundColor(ReclaimColors.textSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Card Styles

struct CardStyle: ViewModifier {
    var padding: CGFloat = Spacing.md
    var showBorder: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(ReclaimColors.cardBackground)
            )
            .overlay(
                showBorder ?
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(ReclaimColors.border, lineWidth: 1) :
                    nil
            )
            .shadow(
                color: Shadows.medium.color,
                radius: Shadows.medium.radius,
                x: Shadows.medium.x,
                y: Shadows.medium.y
            )
    }
}

struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(ReclaimColors.cardBackgroundElevated)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Shadows.large.color,
                radius: Shadows.large.radius,
                x: Shadows.large.x,
                y: Shadows.large.y
            )
    }
}

// MARK: - Input Field Styles

struct InputFieldStyle: ViewModifier {
    var icon: String? = nil

    func body(content: Content) -> some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(ReclaimColors.textTertiary)
                    .frame(width: 20)
            }

            content
                .font(ReclaimTypography.body)
                .foregroundColor(ReclaimColors.textPrimary)
        }
        .padding(Spacing.md)
        .background(ReclaimColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(ReclaimColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Loading Overlay

struct LoadingModifier: ViewModifier {
    var isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)

            if isLoading {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(ReclaimColors.backgroundSecondary.opacity(0.9))
                    .frame(width: 100, height: 100)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
                    .shadow(
                        color: Shadows.large.color,
                        radius: Shadows.large.radius,
                        x: Shadows.large.x,
                        y: Shadows.large.y
                    )
            }
        }
    }
}

// MARK: - Error Alert

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

// MARK: - Badge

struct BadgeStyle: ViewModifier {
    var color: Color = ReclaimColors.primary

    func body(content: Content) -> some View {
        content
            .font(ReclaimTypography.captionSmall)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color)
            .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Gradient Border

struct GradientBorderStyle: ViewModifier {
    var gradient: LinearGradient
    var lineWidth: CGFloat = 2
    var cornerRadius: CGFloat = CornerRadius.md

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(gradient, lineWidth: lineWidth)
            )
    }
}

// MARK: - Shimmer Effect (for loading states)

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    // Button Styles
    func primaryButton(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonStyle(isEnabled: isEnabled))
    }

    func secondaryButton() -> some View {
        modifier(SecondaryButtonStyle())
    }

    func ghostButton() -> some View {
        modifier(GhostButtonStyle())
    }

    // Card Styles
    func cardStyle(padding: CGFloat = Spacing.md, showBorder: Bool = true) -> some View {
        modifier(CardStyle(padding: padding, showBorder: showBorder))
    }

    func glassCard() -> some View {
        modifier(GlassCardStyle())
    }

    // Input Style
    func inputField(icon: String? = nil) -> some View {
        modifier(InputFieldStyle(icon: icon))
    }

    // Loading
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }

    // Error Alert
    func errorAlert(_ error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }

    // Badge
    func badge(color: Color = ReclaimColors.primary) -> some View {
        modifier(BadgeStyle(color: color))
    }

    // Gradient Border
    func gradientBorder(
        gradient: LinearGradient = ReclaimColors.primaryGradient,
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = CornerRadius.md
    ) -> some View {
        modifier(GradientBorderStyle(
            gradient: gradient,
            lineWidth: lineWidth,
            cornerRadius: cornerRadius
        ))
    }

    // Shimmer
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
