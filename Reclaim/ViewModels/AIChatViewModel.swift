//
//  AIChatViewModel.swift
//  Reclaim
//
//  ViewModel for AI chat
//

import Foundation
import Combine

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isTyping = false
    @Published var error: Error?

    private let aiService = AIService.shared

    // MARK: - Load Conversation History

    func loadConversationHistory() async {
        isLoading = true
        
        do {
            let conversations = try await aiService.getConversations()
            
            // Get messages from the first conversation (or all messages if multiple conversations)
            if let firstConversation = conversations.first {
                // Convert Conversation messages to ChatMessage format
                // Backend already returns messages in chronological order (oldest first)
                // Filter out empty messages and error messages
                // Limit to last 20 messages to reduce context and cost
                let allMessages = firstConversation.messages
                    .filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .filter { !isErrorMessage($0.content) }
                
                // Take only the last 20 messages (most recent)
                messages = Array(allMessages.suffix(20)).map { msg in
                    ChatMessage(
                        id: msg.id,
                        role: msg.role,
                        content: msg.content,
                        timestamp: msg.createdAt
                    )
                }
                print("✅ Loaded \(messages.count) messages from conversation history (showing last 20)")
            } else {
                print("ℹ️ No conversation history found")
            }
        } catch {
            print("⚠️ Failed to load conversation history: \(error)")
            // Don't show error to user, just start with empty chat
        }
        
        isLoading = false
    }

    // MARK: - Send Message

    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)

        isLoading = true
        isTyping = true

        // Prepare AI message
        var aiMessageContent = ""
        let aiMessageId = UUID().uuidString
        var aiMessageIndex: Int?
        var hasReceivedFirstChunk = false

        do {
            // Stream response
            let stream = await aiService.streamMessage(text, history: messages)

            print("📡 Starting to receive stream chunks...")

            for try await chunk in stream {
                print("📨 Received chunk: \(String(chunk.prefix(50)))...")
                
                if !hasReceivedFirstChunk {
                    // Create AI message only when first chunk arrives
                    hasReceivedFirstChunk = true
                    let aiMessage = ChatMessage(
                        id: aiMessageId,
                        role: .assistant,
                        content: chunk,
                        timestamp: Date()
                    )
                    messages.append(aiMessage)
                    aiMessageIndex = messages.count - 1
                    aiMessageContent = chunk
                } else {
                    // Update existing message
                    aiMessageContent += chunk
                    if let index = aiMessageIndex {
                        messages[index] = ChatMessage(
                            id: aiMessageId,
                            role: .assistant,
                            content: aiMessageContent,
                            timestamp: messages[index].timestamp
                        )
                    }
                }
            }

            print("✅ Stream completed. Total content length: \(aiMessageContent.count)")
            
            // If no chunks were received, show error message to user
            if !hasReceivedFirstChunk {
                print("⚠️ No chunks received from stream")
                // Add error message so user knows what happened
                messages.append(ChatMessage(
                    id: aiMessageId,
                    role: .assistant,
                    content: "I'm sorry, I didn't receive a response from the server. Please check your connection and try again.",
                    timestamp: Date()
                ))
            } else {
                // Ensure the final message has all content
                if let index = aiMessageIndex, !aiMessageContent.isEmpty {
                    messages[index] = ChatMessage(
                        id: aiMessageId,
                        role: .assistant,
                        content: aiMessageContent,
                        timestamp: messages[index].timestamp
                    )
                }
            }

            isTyping = false
        } catch {
            self.error = error
            print("❌ Failed to send message: \(error)")
            
            // Show error message to user
            var errorMessage = "I'm sorry, I'm having trouble connecting right now. Please try again."
            
            if let apiError = error as? APIError {
                switch apiError {
                case .serverError(let code, let message):
                    if let msg = message {
                        // Check if it's a rate limit error and make it more friendly
                        if msg.contains("limit reached") || msg.contains("limit") {
                            errorMessage = msg // Use backend's friendly message
                        } else {
                            errorMessage = "Server error (\(code)): \(msg)"
                        }
                    } else {
                        errorMessage = "Server error (\(code)). Please try again."
                    }
                case .unauthorized:
                    errorMessage = "Your session expired. Please log in again."
                case .networkError(let underlyingError):
                    errorMessage = "Network error. Please check your connection."
                    print("   Underlying error: \(underlyingError)")
                default:
                    break
                }
            }
            
            messages.append(ChatMessage(
                id: aiMessageId,
                role: .assistant,
                content: errorMessage,
                timestamp: Date()
            ))
            
            isTyping = false
        }

        isLoading = false
    }

    // MARK: - Clear Chat

    func clearChat() {
        messages.removeAll()
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
}
