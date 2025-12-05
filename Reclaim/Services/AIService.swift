//
//  AIService.swift
//  Reclaim
//
//  AI companion and chat service
//

import Foundation

class AIService {
    static let shared = AIService()
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Send Message (Streaming)

    func streamMessage(_ message: String, history: [ChatMessage] = []) async -> AsyncThrowingStream<String, Error> {
        // Filter out empty messages and error messages before sending
        // Also ensure content is not empty after trimming
        let filteredHistory = history
            .filter { msg in
                let trimmed = msg.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.isEmpty && !isErrorMessage(msg.content)
            }
        
        // Take last 20 messages (most recent) to reduce context and cost
        let historyDto = filteredHistory.suffix(20).map { msg in
            SendMessageRequest.MessageDto(
                role: msg.role.rawValue,
                content: msg.content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        // Only include history if we have valid messages
        let request = SendMessageRequest(
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            conversationHistory: historyDto.isEmpty ? nil : Array(historyDto)
        )

        return await apiClient.stream(.chat, body: request)
    }
    
    // MARK: - Helper Methods
    
    private func isErrorMessage(_ content: String) -> Bool {
        let errorMessages = [
            "I'm sorry, I'm having trouble connecting right now. Please try again later.",
            "I'm sorry, I didn't receive a response. Please try again.",
            "I'm having trouble connecting right now"
        ]
        return errorMessages.contains { content.contains($0) }
    }

    // MARK: - Get Conversations

    func getConversations() async throws -> [Conversation] {
        return try await apiClient.request(.getConversations)
    }

    // MARK: - Get Insights

    func getInsights() async throws -> [AIInsight] {
        return try await apiClient.request(.getInsights)
    }

    // MARK: - Acknowledge Insight

    func acknowledgeInsight(_ id: String) async throws {
        try await apiClient.request(.acknowledgeInsight(id))
    }

    // MARK: - Get Rate Limits

    func getRateLimits() async throws -> RateLimits {
        return try await apiClient.request(.getLimits)
    }
}
