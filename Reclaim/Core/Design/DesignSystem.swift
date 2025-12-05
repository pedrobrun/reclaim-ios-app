//
//  DesignSystem.swift
//  Reclaim
//
//  Comprehensive design system with colors, typography, and spacing
//  Inspired by Opal and Quittr's premium UI
//

import SwiftUI

// MARK: - Colors

enum ReclaimColors {
    // Primary Brand Colors (Purple-blue gradient tones)
    static let primary = Color(hex: "667EEA")        // Purple-blue
    static let primaryLight = Color(hex: "8B9FF5")   // Lighter purple
    static let primaryDark = Color(hex: "4A5BC7")    // Darker purple

    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [
            Color(hex: "667EEA"),  // Purple-blue
            Color(hex: "764BA2")   // Deep purple
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [
            Color(hex: "11998E"),  // Teal
            Color(hex: "38EF7D")   // Green
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warningGradient = LinearGradient(
        colors: [
            Color(hex: "F2994A"),  // Orange
            Color(hex: "F2C94C")   // Yellow
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dangerGradient = LinearGradient(
        colors: [
            Color(hex: "EB3349"),  // Red
            Color(hex: "F45C43")   // Orange-red
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Semantic Colors
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let danger = Color(hex: "EF4444")
    static let info = Color(hex: "3B82F6")

    // Background Colors (Dark Theme)
    static let background = Color(hex: "0A0A0A")        // Almost black
    static let backgroundSecondary = Color(hex: "1A1A1A")
    static let backgroundTertiary = Color(hex: "2A2A2A")

    // Card Colors
    static let cardBackground = Color(hex: "1A1A1A").opacity(0.6)
    static let cardBackgroundElevated = Color(hex: "2A2A2A").opacity(0.8)

    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)

    // Border Colors
    static let border = Color.white.opacity(0.1)
    static let borderHeavy = Color.white.opacity(0.2)
}

// MARK: - Typography

enum ReclaimTypography {
    // Display
    static let displayLarge = Font.system(size: 72, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 56, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 40, weight: .bold, design: .rounded)

    // Headings
    static let h1 = Font.system(size: 32, weight: .bold, design: .rounded)
    static let h2 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let h3 = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let h4 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let h5 = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let h6 = Font.system(size: 16, weight: .semibold, design: .rounded)

    // Body
    static let bodyLarge = Font.system(size: 18, weight: .regular)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)

    // Labels
    static let labelLarge = Font.system(size: 16, weight: .medium)
    static let label = Font.system(size: 14, weight: .medium)
    static let labelSmall = Font.system(size: 12, weight: .medium)

    // Caption
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionSmall = Font.system(size: 10, weight: .regular)
}

// MARK: - Spacing (8px Grid System)

enum Spacing {
    static let xxxs: CGFloat = 2   // 2px
    static let xxs: CGFloat = 4    // 4px
    static let xs: CGFloat = 8     // 8px (base unit)
    static let sm: CGFloat = 12    // 12px
    static let md: CGFloat = 16    // 16px (2x base)
    static let lg: CGFloat = 24    // 24px (3x base)
    static let xl: CGFloat = 32    // 32px (4x base)
    static let xxl: CGFloat = 40   // 40px (5x base)
    static let xxxl: CGFloat = 48  // 48px (6x base)
    static let huge: CGFloat = 64  // 64px (8x base)
}

// MARK: - Border Radius

enum CornerRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let full: CGFloat = 9999
}

// MARK: - Shadows

enum Shadows {
    static let small = (color: Color.black.opacity(0.1), radius: 4.0, x: 0.0, y: 2.0)
    static let medium = (color: Color.black.opacity(0.15), radius: 8.0, x: 0.0, y: 4.0)
    static let large = (color: Color.black.opacity(0.2), radius: 16.0, x: 0.0, y: 8.0)
    static let glow = (color: Color.purple.opacity(0.3), radius: 20.0, x: 0.0, y: 0.0)
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
