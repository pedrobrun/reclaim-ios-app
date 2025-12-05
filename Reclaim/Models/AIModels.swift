//
//  AIModels.swift
//  Reclaim
//
//  AI companion and chat models
//

import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let role: MessageRole
    let content: String
    let createdAt: Date

    enum MessageRole: String, Codable {
        case user
        case assistant
    }

    // Convenience properties
    var isUser: Bool {
        role == .user
    }

    var timestamp: Date {
        createdAt
    }

    init(id: String = UUID().uuidString, role: MessageRole, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }

    // Alternative initializer with timestamp parameter
    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: Date) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = timestamp
    }
}

struct Conversation: Codable, Identifiable {
    let id: String
    let title: String
    let messages: [ChatMessage]
    let createdAt: Date
    let updatedAt: Date
}

struct AIInsight: Codable, Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let content: String
    let createdAt: Date

    enum InsightType: String, Codable {
        case triggerPattern = "trigger_pattern"
        case progressMilestone = "progress_milestone"
        case recommendation
    }
}

struct RateLimits: Codable {
    let daily: LimitInfo

    struct LimitInfo: Codable {
        let limit: Int
        let remaining: Int
        let canSend: Bool
    }
}

// MARK: - Request DTOs

struct SendMessageRequest: Codable {
    let message: String
    let conversationHistory: [MessageDto]?

    struct MessageDto: Codable {
        let role: String
        let content: String
    }
}
