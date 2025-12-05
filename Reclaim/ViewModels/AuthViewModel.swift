//
//  AuthViewModel.swift
//  Reclaim
//
//  ViewModel for authentication (login, register)
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""

    @Published var isLoading = false
    @Published var error: Error?

    private let authService = AuthService.shared

    // MARK: - Register

    func register() async {
        guard validate() else { return }

        isLoading = true
        error = nil

        do {
            try await authService.register(email: email, password: password, name: name)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Login

    func login() async {
        guard validateLogin() else { return }

        isLoading = true
        error = nil

        do {
            try await authService.login(email: email, password: password)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Validation

    private func validate() -> Bool {
        guard !email.isEmpty else {
            error = ValidationError.emptyEmail
            return false
        }

        guard email.contains("@") else {
            error = ValidationError.invalidEmail
            return false
        }

        guard !password.isEmpty else {
            error = ValidationError.emptyPassword
            return false
        }

        guard password.count >= 8 else {
            error = ValidationError.passwordTooShort
            return false
        }

        guard !name.isEmpty else {
            error = ValidationError.emptyName
            return false
        }

        return true
    }

    private func validateLogin() -> Bool {
        guard !email.isEmpty else {
            error = ValidationError.emptyEmail
            return false
        }

        guard !password.isEmpty else {
            error = ValidationError.emptyPassword
            return false
        }

        return true
    }

    // MARK: - Validation Errors

    enum ValidationError: LocalizedError {
        case emptyEmail
        case invalidEmail
        case emptyPassword
        case passwordTooShort
        case emptyName

        var errorDescription: String? {
            switch self {
            case .emptyEmail:
                return "Email is required"
            case .invalidEmail:
                return "Please enter a valid email"
            case .emptyPassword:
                return "Password is required"
            case .passwordTooShort:
                return "Password must be at least 8 characters"
            case .emptyName:
                return "Name is required"
            }
        }
    }
}
