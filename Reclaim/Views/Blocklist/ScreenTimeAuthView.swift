//
//  ScreenTimeAuthView.swift
//  Reclaim
//
//  Screen Time authorization prompt and status
//

import SwiftUI

@available(iOS 16.0, *)
struct ScreenTimeAuthView: View {
    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var isRequesting = false
    @State private var showError = false
    @State private var localIsAuthorized = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: localIsAuthorized ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(localIsAuthorized ? ReclaimColors.success : ReclaimColors.warning)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(localIsAuthorized ? "System-wide blocking enabled" : "System-wide blocking disabled")
                        .font(ReclaimTypography.label)
                        .foregroundColor(ReclaimColors.textPrimary)

                    if isRequesting {
                        Text("Requesting permission...")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textTertiary)
                    } else if localIsAuthorized {
                        Text("Blocks all browsers and apps")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textSecondary)
                    } else {
                        Text("Recommended for maximum protection")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.warning)
                    }
                }

                Spacer()

                if !localIsAuthorized && !isRequesting {
                    Image(systemName: "chevron.right")
                        .foregroundColor(ReclaimColors.textTertiary)
                        .font(.system(size: 14))
                }
            }

            // Info about what this enables
            if !localIsAuthorized {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Divider()

                    Text("Enable Screen Time blocking to:")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textSecondary)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        FeatureBullet(text: "Block in ALL browsers (Chrome, Firefox, etc.)")
                        FeatureBullet(text: "Block native apps (social media, streaming)")
                        FeatureBullet(text: "Prevent bypass attempts")
                        FeatureBullet(text: "Strongest protection available")
                    }

                    if screenTimeManager.isAvailable {
                        Button {
                            Task {
                                await requestAuthorization()
                            }
                        } label: {
                            if isRequesting {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Requesting...")
                                }
                            } else {
                                HStack {
                                    Image(systemName: "shield.lefthalf.filled")
                                    Text("Enable System-Wide Blocking")
                                }
                            }
                        }
                        .primaryButton()
                        .disabled(isRequesting)
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Screen Time requires Apple Developer account")
                                .font(ReclaimTypography.caption)
                                .foregroundColor(ReclaimColors.textSecondary)
                            
                            Text("Safari Content Blocker is still active")
                                .font(ReclaimTypography.caption)
                                .foregroundColor(ReclaimColors.textTertiary)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(
            localIsAuthorized
                ? ReclaimColors.backgroundSecondary
                : ReclaimColors.warning.opacity(0.1)
        )
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    localIsAuthorized
                        ? ReclaimColors.success.opacity(0.3)
                        : ReclaimColors.warning.opacity(0.5),
                    lineWidth: 1
                )
        )
        .alert("Authorization Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(screenTimeManager.authorizationError?.localizedDescription ?? "Failed to enable Screen Time blocking")
        }
        .onChange(of: screenTimeManager.isAuthorized) { newValue in
            // Sync local state when manager state changes
            localIsAuthorized = newValue
        }
        .task {
            // Check status when view appears (async)
            await MainActor.run {
                screenTimeManager.checkAuthorizationStatus()
                localIsAuthorized = screenTimeManager.isAuthorized
            }
        }
        .onAppear {
            // Also check synchronously on appear
            screenTimeManager.checkAuthorizationStatus()
            localIsAuthorized = screenTimeManager.isAuthorized
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh status when app comes back from Settings
            Task { @MainActor in
                screenTimeManager.checkAuthorizationStatus()
                localIsAuthorized = screenTimeManager.isAuthorized
            }
        }
    }

    // MARK: - Request Authorization

    private func requestAuthorization() async {
        isRequesting = true

        do {
            try await screenTimeManager.requestAuthorization()
            print("✅ Screen Time authorized successfully")
            // Update local state after successful authorization
            await MainActor.run {
                localIsAuthorized = screenTimeManager.isAuthorized
            }
        } catch {
            print("❌ Screen Time authorization failed: \(error)")
            showError = true
        }

        isRequesting = false
    }
}

// MARK: - Feature Bullet

struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(ReclaimColors.success)
                .font(.system(size: 12))
                .padding(.top, 2)

            Text(text)
                .font(ReclaimTypography.caption)
                .foregroundColor(ReclaimColors.textSecondary)
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        VStack {
            ScreenTimeAuthView()
            Spacer()
        }
        .padding()
        .background(ReclaimColors.background)
    } else {
        Text("iOS 16+ required")
    }
}
