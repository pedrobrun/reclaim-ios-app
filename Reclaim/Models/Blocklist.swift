//
//  Blocklist.swift
//  Reclaim
//
//  Blocklist models for domain and app blocking
//

import Foundation

struct BlocklistDomain: Codable, Identifiable {
    let id: String
    let domain: String
    let isWildcard: Bool
    let isRegex: Bool
    let isPredefined: Bool
    let category: String?
    let createdAt: Date
}

struct BlocklistApp: Codable, Identifiable {
    let id: String
    let appIdentifier: String
    let appName: String
    let blockStartTime: String?
    let blockEndTime: String?
    let createdAt: Date
}

struct BlocklistTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let count: Int

    // Convenience property for backward compatibility
    var domainCount: Int { count }
}

struct BlockScreen: Codable, Identifiable, Equatable {
    let id: String
    let message: String?
    let imageUrl: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Request DTOs

struct CreateBlockScreenRequest: Codable {
    let message: String?
    let isActive: Bool
    let imageData: String? // Base64 encoded
}

struct AddDomainRequest: Codable {
    let domain: String
}

struct ApplyTemplateRequest: Codable {
    let template: String // "essential" | "recommended" | "maximum"
}

struct UpdateBlockScreenRequest: Codable {
    let message: String?
    let isActive: Bool?
}
