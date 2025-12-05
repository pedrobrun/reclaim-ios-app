//
//  AuthService.swift
//  Reclaim
//
//  Authentication service for login, register, token management
//

import Foundation
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private let apiClient = APIClient.shared
    private let keychainManager = KeychainManager.shared

    private init() {
        // Check if user has valid tokens on app launch
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Auth Status

    func checkAuthStatus() async {
        guard keychainManager.getAccessToken() != nil else {
            isAuthenticated = false
            currentUser = nil
            return
        }

        // Try to fetch current user profile
        do {
            currentUser = try await apiClient.request(.getProfile)
            isAuthenticated = true
        } catch {
            // Token might be expired, try to refresh
            await refreshToken()
        }
    }

    // MARK: - Register

    func register(email: String, password: String, name: String) async throws {
        let request = RegisterRequest(email: email, password: password, displayName: name)
        let response: AuthResponse = try await apiClient.request(.register, body: request)

        print("📝 Register response received")
        print("📝 Access token (first 20 chars): \(String(response.accessToken.prefix(20)))...")
        print("📝 Refresh token (first 20 chars): \(String(response.refreshToken.prefix(20)))...")

        // Save tokens
        keychainManager.saveAccessToken(response.accessToken)
        keychainManager.saveRefreshToken(response.refreshToken)

        // Verify tokens were saved
        if let savedToken = keychainManager.getAccessToken() {
            print("✅ Token saved successfully (first 20 chars): \(String(savedToken.prefix(20)))...")
        } else {
            print("❌ Failed to save token to keychain")
        }

        // Reset onboarding for new user registration
        UserDefaultsManager.shared.hasCompletedOnboarding = false

        // Update state
        currentUser = response.user
        isAuthenticated = true
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await apiClient.request(.login, body: request)

        print("📝 Login response received")
        print("📝 Access token (first 20 chars): \(String(response.accessToken.prefix(20)))...")
        print("📝 Refresh token (first 20 chars): \(String(response.refreshToken.prefix(20)))...")

        // Save tokens
        keychainManager.saveAccessToken(response.accessToken)
        keychainManager.saveRefreshToken(response.refreshToken)

        // Verify tokens were saved
        if let savedToken = keychainManager.getAccessToken() {
            print("✅ Token saved successfully (first 20 chars): \(String(savedToken.prefix(20)))...")
        } else {
            print("❌ Failed to save token to keychain")
        }

        // Update state
        currentUser = response.user
        isAuthenticated = true
    }

    // MARK: - Logout

    func logout() {
        keychainManager.clearAll()
        currentUser = nil
        isAuthenticated = false
        // Reset onboarding state on logout
        UserDefaultsManager.shared.hasCompletedOnboarding = false
    }

    // MARK: - Refresh Token

    func refreshToken() async {
        guard let refreshToken = keychainManager.getRefreshToken() else {
            logout()
            return
        }

        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await apiClient.request(.refreshToken, body: request)

            // Save new tokens
            keychainManager.saveAccessToken(response.accessToken)
            keychainManager.saveRefreshToken(response.refreshToken)

            // Update state
            currentUser = response.user
            isAuthenticated = true
        } catch {
            // Refresh failed, logout
            logout()
        }
    }

    // MARK: - Update Profile

    func updateProfile(name: String?, email: String?, why: String? = nil, preferredTemplate: String? = nil) async throws {
        let request = UpdateProfileRequest(name: name, email: email, why: why, preferredTemplate: preferredTemplate)
        let updatedUser: User = try await apiClient.request(.updateProfile, body: request)
        currentUser = updatedUser
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        try await apiClient.request(.deleteAccount)
        logout()
    }
}
