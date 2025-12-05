//
//  RegisterView.swift
//  Reclaim
//
//  Registration screen
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ReclaimColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Close button
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(ReclaimColors.textSecondary)
                                    .padding(Spacing.sm)
                                    .background(ReclaimColors.backgroundSecondary)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, Spacing.lg)

                        // Logo and Title
                        VStack(spacing: Spacing.md) {
                            // Gradient icon
                            ZStack {
                                Circle()
                                    .fill(ReclaimColors.successGradient)
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 20)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }

                            Text("Begin Your Journey")
                                .font(ReclaimTypography.h1)
                                .foregroundColor(ReclaimColors.textPrimary)

                            Text("Join thousands recovering together")
                                .font(ReclaimTypography.body)
                                .foregroundColor(ReclaimColors.textSecondary)
                        }

                        // Registration Form
                        VStack(spacing: Spacing.md) {
                            TextField("", text: $viewModel.name)
                                .placeholder(when: viewModel.name.isEmpty) {
                                    Text("Full Name").foregroundColor(ReclaimColors.textTertiary)
                                }
                                .textContentType(.name)
                                .inputField(icon: "person.fill")

                            TextField("", text: $viewModel.email)
                                .placeholder(when: viewModel.email.isEmpty) {
                                    Text("Email").foregroundColor(ReclaimColors.textTertiary)
                                }
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .inputField(icon: "envelope.fill")

                            SecureField("", text: $viewModel.password)
                                .placeholder(when: viewModel.password.isEmpty) {
                                    Text("Password").foregroundColor(ReclaimColors.textTertiary)
                                }
                                .textContentType(.newPassword)
                                .inputField(icon: "lock.fill")

                            // Password requirements
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: viewModel.password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.password.count >= 8 ? ReclaimColors.success : ReclaimColors.textTertiary)
                                Text("At least 8 characters")
                                    .font(ReclaimTypography.caption)
                                    .foregroundColor(ReclaimColors.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.xxs)

                            Button {
                                Task {
                                    await viewModel.register()
                                }
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Text("Create Account")
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                }
                            }
                            .primaryButton(isEnabled: !viewModel.isLoading)
                            .disabled(viewModel.isLoading)

                            // Terms and privacy
                            Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                                .font(ReclaimTypography.captionSmall)
                                .foregroundColor(ReclaimColors.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.md)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)

                        Spacer()
                    }
                }
            }
            .errorAlert($viewModel.error)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RegisterView()
}
