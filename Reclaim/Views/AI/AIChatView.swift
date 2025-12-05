//
//  AIChatView.swift
//  Reclaim
//
//  AI companion chat interface
//

import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    
    var initialMessage: String? = nil

    var body: some View {
        ZStack {
            // Background
            ReclaimColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("AI Companion")
                            .font(ReclaimTypography.h3)
                            .foregroundColor(ReclaimColors.textPrimary)

                        HStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xxs) {
                                Circle()
                                    .fill(ReclaimColors.success)
                                    .frame(width: 8, height: 8)

                                Text("Online")
                                    .font(ReclaimTypography.caption)
                                    .foregroundColor(ReclaimColors.textSecondary)
                            }
                            
                            // Show context limit indicator
                            if !viewModel.messages.isEmpty {
                                Text("• Last \(min(viewModel.messages.count, 20)) messages")
                                    .font(ReclaimTypography.captionSmall)
                                    .foregroundColor(ReclaimColors.textTertiary)
                            }
                        }
                    }

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
                .padding(Spacing.lg)
                .background(ReclaimColors.backgroundSecondary)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            // Welcome message
                            if viewModel.messages.isEmpty {
                                WelcomeMessage()
                            }

                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            // Typing indicator
                            if viewModel.isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding(Spacing.lg)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input
                HStack(spacing: Spacing.sm) {
                    TextField("", text: $messageText)
                        .placeholder(when: messageText.isEmpty) {
                            Text("Type a message...").foregroundColor(ReclaimColors.textTertiary)
                        }
                        .padding(Spacing.md)
                        .background(ReclaimColors.backgroundSecondary)
                        .cornerRadius(CornerRadius.lg)
                        .foregroundColor(ReclaimColors.textPrimary)

                    Button {
                        Task {
                            await viewModel.sendMessage(messageText)
                            messageText = ""
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(messageText.isEmpty ? LinearGradient(colors: [ReclaimColors.backgroundTertiary], startPoint: .top, endPoint: .bottom) : ReclaimColors.primaryGradient)
                                .frame(width: 44, height: 44)

                            Image(systemName: "arrow.up")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .disabled(messageText.isEmpty || viewModel.isLoading)
                }
                .padding(Spacing.lg)
                .background(ReclaimColors.backgroundSecondary)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            // Load conversation history first
            await viewModel.loadConversationHistory()
            
            // Send initial message only if:
            // 1. An initial message is provided (panic button)
            // 2. There's no conversation history (empty chat)
            if let initialMessage = initialMessage, !initialMessage.isEmpty {
                // Only send if there's no existing conversation
                if viewModel.messages.isEmpty {
                    await viewModel.sendMessage(initialMessage)
                }
            }
        }
    }
}

// MARK: - Welcome Message

struct WelcomeMessage: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(ReclaimColors.primaryGradient)
                    .frame(width: 60, height: 60)
                    .blur(radius: 15)

                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }

            Text("Your AI Companion")
                .font(ReclaimTypography.h4)
                .foregroundColor(ReclaimColors.textPrimary)

            Text("I'm here to support you on your recovery journey. Share what's on your mind, and I'll provide guidance and encouragement.")
                .font(ReclaimTypography.body)
                .foregroundColor(ReclaimColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: Spacing.xxs) {
                Text(message.content)
                    .font(ReclaimTypography.body)
                    .foregroundColor(message.isUser ? .white : ReclaimColors.textPrimary)
                    .padding(Spacing.md)
                    .background(
                        message.isUser ?
                            AnyView(ReclaimColors.primaryGradient) :
                            AnyView(ReclaimColors.backgroundSecondary)
                    )
                    .cornerRadius(CornerRadius.md)

                Text(formatTime(message.timestamp))
                    .font(ReclaimTypography.captionSmall)
                    .foregroundColor(ReclaimColors.textTertiary)
                    .padding(.horizontal, Spacing.xs)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(ReclaimColors.textTertiary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(Spacing.md)
        .background(ReclaimColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    AIChatView()
}
