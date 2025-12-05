//
//  APIEndpoint.swift
//  Reclaim
//
//  API endpoint definitions matching NestJS backend
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let requiresAuth: Bool

    // MARK: - Auth Endpoints
    static let register = APIEndpoint(path: "/auth/register", method: .post, requiresAuth: false)
    static let login = APIEndpoint(path: "/auth/login", method: .post, requiresAuth: false)
    static let refreshToken = APIEndpoint(path: "/auth/refresh", method: .post, requiresAuth: false)

    // MARK: - User Endpoints
    static let getProfile = APIEndpoint(path: "/users/profile", method: .get, requiresAuth: true)
    static let updateProfile = APIEndpoint(path: "/users/profile", method: .patch, requiresAuth: true)
    static let deleteAccount = APIEndpoint(path: "/users/account", method: .delete, requiresAuth: true)
    static let registerDevice = APIEndpoint(path: "/users/device", method: .post, requiresAuth: true)

    // MARK: - Streak Endpoints
    static let getCurrentStreak = APIEndpoint(path: "/streak/current", method: .get, requiresAuth: true)
    static let logRelapse = APIEndpoint(path: "/streak/relapse", method: .post, requiresAuth: true)
    static let getAnalytics = APIEndpoint(path: "/streak/analytics", method: .get, requiresAuth: true)

    // MARK: - Blocklist Endpoints
    static let getDomains = APIEndpoint(path: "/blocklist/domains", method: .get, requiresAuth: true)
    static let addDomain = APIEndpoint(path: "/blocklist/domains", method: .post, requiresAuth: true)
    static func deleteDomain(_ id: String) -> APIEndpoint {
        APIEndpoint(path: "/blocklist/domains/\(id)", method: .delete, requiresAuth: true)
    }
    static let getTemplates = APIEndpoint(path: "/blocklist/templates", method: .get, requiresAuth: true)
    static func applyTemplate(_ templateName: String) -> APIEndpoint {
        APIEndpoint(path: "/blocklist/templates/\(templateName)", method: .post, requiresAuth: true)
    }
    
    // MARK: - Block Screen Endpoints
    static let getBlockScreens = APIEndpoint(path: "/blocklist/block-screens", method: .get, requiresAuth: true)
    static let createBlockScreen = APIEndpoint(path: "/blocklist/block-screens", method: .post, requiresAuth: true)
    static func updateBlockScreen(_ id: String) -> APIEndpoint {
        APIEndpoint(path: "/blocklist/block-screens/\(id)", method: .patch, requiresAuth: true)
    }
    static func deleteBlockScreen(_ id: String) -> APIEndpoint {
        APIEndpoint(path: "/blocklist/block-screens/\(id)", method: .delete, requiresAuth: true)
    }

    // MARK: - Subscription Endpoints (Apple IAP)
    static let validateAppleReceipt = APIEndpoint(path: "/subscription/apple/validate", method: .post, requiresAuth: true)
    static let getSubscriptionStatus = APIEndpoint(path: "/subscription/status", method: .get, requiresAuth: true)

    // MARK: - Deprecated Stripe Endpoints (to be removed)
    static let createCheckout = APIEndpoint(path: "/subscription/checkout", method: .post, requiresAuth: true)
    static let getPortal = APIEndpoint(path: "/subscription/portal", method: .get, requiresAuth: true)

    // MARK: - AI Endpoints
    static let chat = APIEndpoint(path: "/ai/chat", method: .post, requiresAuth: true)
    static let getConversations = APIEndpoint(path: "/ai/conversations", method: .get, requiresAuth: true)
    static let getInsights = APIEndpoint(path: "/ai/insights", method: .get, requiresAuth: true)
    static func acknowledgeInsight(_ id: String) -> APIEndpoint {
        APIEndpoint(path: "/ai/insights/\(id)/acknowledge", method: .patch, requiresAuth: true)
    }
    static let getLimits = APIEndpoint(path: "/ai/limits", method: .get, requiresAuth: true)
}
