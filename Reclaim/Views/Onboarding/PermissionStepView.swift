//
//  PermissionStepView.swift
//  Reclaim
//
//  Screen Time permission request step
//

import SwiftUI

struct PermissionStepView: View {
    @Binding var isRequesting: Bool
    @Binding var error: Error?
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @State private var screenTimeAuthorized = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            VStack(spacing: Spacing.lg) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ReclaimColors.primary)
                
                Text("Enable System-Wide Blocking")
                    .font(ReclaimTypography.h1)
                    .foregroundColor(ReclaimColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Reclaim needs Screen Time permission to block distracting websites and apps across all browsers and applications on your device.")
                    .font(ReclaimTypography.body)
                    .foregroundColor(ReclaimColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
            
            // Benefits
            VStack(alignment: .leading, spacing: Spacing.md) {
                PermissionBenefit(
                    icon: "safari",
                    text: "Blocks sites in Safari, Chrome, Firefox, and more"
                )
                
                PermissionBenefit(
                    icon: "app.badge",
                    text: "Blocks distracting apps system-wide"
                )
                
                PermissionBenefit(
                    icon: "lock.fill",
                    text: "Cannot be easily bypassed"
                )
            }
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
            
            // Status
            if screenTimeAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ReclaimColors.success)
                    Text("Screen Time enabled")
                        .font(ReclaimTypography.label)
                        .foregroundColor(ReclaimColors.success)
                }
                .padding(.bottom, Spacing.md)
            }
            
            // Error
            if let error = error {
                Text(error.localizedDescription)
                    .font(ReclaimTypography.caption)
                    .foregroundColor(ReclaimColors.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.md)
            }
            
            // Buttons
            VStack(spacing: Spacing.md) {
                if #available(iOS 16.0, *), ScreenTimeManager.shared.isAvailable {
                    Button {
                        requestScreenTimePermission()
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(screenTimeAuthorized ? "Permission Granted" : "Enable Screen Time")
                            }
                        }
                        .modifier(PrimaryButtonStyle(isEnabled: !isRequesting && !screenTimeAuthorized))
                    }
                    .disabled(isRequesting || screenTimeAuthorized)
                } else {
                    // Screen Time not available (requires paid Apple Developer account)
                    VStack(spacing: Spacing.sm) {
                        Text("Screen Time requires Apple Developer account")
                            .font(ReclaimTypography.body)
                            .foregroundColor(ReclaimColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Safari Content Blocker is still active")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, Spacing.md)
                }
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip for Now")
                        .modifier(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            checkScreenTimeStatus()
        }
    }
    
    @available(iOS 16.0, *)
    private func requestScreenTimePermission() {
        isRequesting = true
        error = nil
        
        Task {
            do {
                try await ScreenTimeManager.shared.requestAuthorization()
                await MainActor.run {
                    screenTimeAuthorized = true
                    isRequesting = false
                    
                    // Auto-continue after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onContinue()
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isRequesting = false
                }
            }
        }
    }
    
    @available(iOS 16.0, *)
    private func checkScreenTimeStatus() {
        screenTimeAuthorized = ScreenTimeManager.shared.isAuthorized
    }
}

struct PermissionBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(ReclaimColors.primary)
                .frame(width: 32)
            
            Text(text)
                .font(ReclaimTypography.body)
                .foregroundColor(ReclaimColors.textSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionStepView(
        isRequesting: .constant(false),
        error: .constant(nil),
        onContinue: {},
        onSkip: {}
    )
}

