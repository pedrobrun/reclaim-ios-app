//
//  LoginView.swift
//  Reclaim
//
//  Login screen
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showRegister = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ReclaimColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        Spacer()
                            .frame(height: Spacing.huge)

                        // Logo and Title
                        VStack(spacing: Spacing.md) {
                            // Gradient icon
                            ZStack {
                                Circle()
                                    .fill(ReclaimColors.primaryGradient)
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 20)

                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }

                            Text("Welcome Back")
                                .font(ReclaimTypography.h1)
                                .foregroundColor(ReclaimColors.textPrimary)

                            Text("Continue your recovery journey")
                                .font(ReclaimTypography.body)
                                .foregroundColor(ReclaimColors.textSecondary)
                        }

                        // Login Form
                        VStack(spacing: Spacing.md) {
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
                                .textContentType(.password)
                                .inputField(icon: "lock.fill")

                            Button {
                                Task {
                                    await viewModel.login()
                                }
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Text("Log In")
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                }
                            }
                            .primaryButton(isEnabled: !viewModel.isLoading)
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.lg)

                        // Register Link
                        Button {
                            showRegister = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(ReclaimColors.textSecondary)
                                Text("Sign Up")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .font(ReclaimTypography.body)
                        }
                        .padding(.top, Spacing.md)

                        Spacer()
                    }
                }
            }
            .errorAlert($viewModel.error)
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Placeholder Modifier

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
}
