//
//  User.swift
//  Reclaim
//
//  User model matching backend User entity
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let subscriptionStatus: SubscriptionStatus
    let emailVerifiedAt: Date?
    let timezone: String
    let createdAt: Date
    let updatedAt: Date
    
    // Computed property for backward compatibility
    var name: String {
        displayName ?? ""
    }

    enum SubscriptionStatus: String, Codable {
        case inactive
        case trialing
        case active
        case pastDue = "past_due"
        case cancelled
        case unpaid
    }
}

// MARK: - Auth DTOs

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case displayName = "display_name"
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
        case user
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

// MARK: - Profile DTOs

struct UpdateProfileRequest: Codable {
    let name: String?
    let email: String?
    let why: String?
    let preferredTemplate: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "displayName"
        case email
        case why
        case preferredTemplate = "preferred_template"
    }
}

struct CreateDeviceRequest: Codable {
    let token: String
    let type: String // "ios" or "android"
}
