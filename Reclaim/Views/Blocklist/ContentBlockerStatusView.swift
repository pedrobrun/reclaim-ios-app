//
//  ContentBlockerStatusView.swift
//  Reclaim
//
//  Shows Safari Content Blocker status and setup instructions
//

import SwiftUI
import SafariServices
import UIKit

struct ContentBlockerStatusView: View {
    @State private var isEnabled = false
    @State private var isLoading = true
    @State private var showInstructions = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: isEnabled ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(isEnabled ? ReclaimColors.success : ReclaimColors.warning)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(isEnabled ? "Safari blocking is active" : "Safari blocking is off")
                        .font(ReclaimTypography.label)
                        .foregroundColor(ReclaimColors.textPrimary)

                    if isLoading {
                        Text("Checking status...")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textTertiary)
                    } else if isEnabled {
                        Text("Domains are blocked in Safari")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textSecondary)
                    } else {
                        Text("Tap to enable")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.warning)
                    }
                }

                Spacer()

                if !isEnabled && !isLoading {
                    Image(systemName: "chevron.right")
                        .foregroundColor(ReclaimColors.textTertiary)
                        .font(.system(size: 14))
                } else if isEnabled && !isLoading {
                    // Refresh button when enabled
                    Button {
                        Task {
                            await checkContentBlockerStatus()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(ReclaimColors.textSecondary)
                            .font(.system(size: 14))
                    }
                }
            }

            // Instructions (shown when tapped and not enabled)
            if showInstructions && !isEnabled {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Divider()

                    Text("To enable Safari blocking:")
                        .font(ReclaimTypography.label)
                        .foregroundColor(ReclaimColors.textPrimary)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        InstructionStep(number: 1, text: "Open Settings app")
                        InstructionStep(number: 2, text: "Go to Apps → Safari (or scroll down to Safari)")
                        InstructionStep(number: 3, text: "Tap Extensions")
                        InstructionStep(number: 4, text: "Find and tap 'Reclaim'")
                        InstructionStep(number: 5, text: "Enable 'Allow Extension' toggle")
                        InstructionStep(number: 6, text: "(Optional) Enable 'Allow in Private Browsing'")
                    }

                    Button {
                        // Open Settings app to Safari settings
                        if let url = URL(string: "App-prefs:SAFARI") {
                            UIApplication.shared.open(url)
                        } else if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Open Settings")
                        }
                        .font(ReclaimTypography.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(ReclaimColors.primaryGradient)
                        .cornerRadius(CornerRadius.md)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(isEnabled ? ReclaimColors.backgroundSecondary : ReclaimColors.warning.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    isEnabled ? ReclaimColors.success.opacity(0.3) : ReclaimColors.warning.opacity(0.5),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            if !isEnabled {
                withAnimation {
                    showInstructions.toggle()
                }
            }
        }
        .task {
            await checkContentBlockerStatus()
        }
        .onAppear {
            // Refresh status when view appears
            Task {
                await checkContentBlockerStatus()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh when app comes back from Settings
            Task {
                await checkContentBlockerStatus()
            }
        }
    }

    // MARK: - Check Status

    private func checkContentBlockerStatus() async {
        isLoading = true

        do {
            let state = try await ContentBlockerManager.shared.getContentBlockerState()
            isEnabled = state.isEnabled
        } catch {
            print("Failed to get Content Blocker state: \(error)")
            isEnabled = false
        }

        isLoading = false
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(ReclaimColors.primary)
                    .frame(width: 24, height: 24)

                Text("\(number)")
                    .font(ReclaimTypography.captionSmall)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(ReclaimTypography.caption)
                .foregroundColor(ReclaimColors.textSecondary)
        }
    }
}

#Preview {
    VStack {
        ContentBlockerStatusView()
        Spacer()
    }
    .padding()
    .background(ReclaimColors.background)
}
