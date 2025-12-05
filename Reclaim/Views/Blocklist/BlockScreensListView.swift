//
//  BlockScreensListView.swift
//  Reclaim
//
//  List of user's block screens
//

import SwiftUI

struct BlockScreensListView: View {
    @StateObject private var viewModel = BlockScreensViewModel()
    @State private var showCreateSheet = false
    
    var body: some View {
        ZStack {
            ReclaimColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Block Screens")
                        .font(ReclaimTypography.h2)
                        .foregroundColor(ReclaimColors.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(ReclaimColors.primary)
                            .clipShape(Circle())
                    }
                }
                .padding(Spacing.lg)
                
                if viewModel.isLoading && viewModel.blockScreens.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.blockScreens.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Spacer()
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(ReclaimColors.textTertiary)
                        
                        VStack(spacing: Spacing.sm) {
                            Text("No Block Screens")
                                .font(ReclaimTypography.h3)
                                .foregroundColor(ReclaimColors.textPrimary)
                            
                            Text("Create your first custom block screen to motivate yourself when blocked content is accessed.")
                                .font(ReclaimTypography.body)
                                .foregroundColor(ReclaimColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.lg)
                        }
                        
                        Button {
                            showCreateSheet = true
                        } label: {
                            Text("Create Block Screen")
                        }
                        .primaryButton()
                        .padding(.horizontal, Spacing.lg)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(viewModel.blockScreens) { screen in
                                BlockScreenCard(
                                    screen: screen,
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteBlockScreen(screen)
                                        }
                                    },
                                    onActivate: {
                                        Task {
                                            await viewModel.activateBlockScreen(screen)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(Spacing.lg)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateBlockScreenView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadBlockScreens()
        }
        .errorAlert($viewModel.error)
    }
}

struct BlockScreenCard: View {
    let screen: BlockScreen
    let onDelete: () -> Void
    let onActivate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let imageUrl = screen.imageUrl {
                AsyncImage(url: URL(string: Config.apiBaseURL.replacingOccurrences(of: "/api/v1", with: "") + imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(ReclaimColors.backgroundSecondary)
                            .frame(height: 160)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(ReclaimColors.backgroundSecondary)
                            .frame(height: 160)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(ReclaimColors.textTertiary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Message
                if let message = screen.message, !message.isEmpty {
                    Text(message)
                        .font(ReclaimTypography.h4)
                        .foregroundColor(ReclaimColors.textPrimary)
                        .lineLimit(2)
                } else {
                    Text("No message")
                        .font(ReclaimTypography.body)
                        .foregroundColor(ReclaimColors.textTertiary)
                        .italic()
                }
                
                HStack {
                    if screen.isActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(ReclaimTypography.captionSmall)
                            .foregroundColor(ReclaimColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ReclaimColors.success.opacity(0.1))
                            .cornerRadius(CornerRadius.xs)
                    } else {
                        Button(action: onActivate) {
                            Text("Set Active")
                                .font(ReclaimTypography.caption)
                                .foregroundColor(ReclaimColors.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(ReclaimColors.textSecondary)
                            .padding(8)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(ReclaimColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(screen.isActive ? ReclaimColors.primary : Color.clear, lineWidth: 2)
        )
    }
}

