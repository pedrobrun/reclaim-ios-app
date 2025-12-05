//
//  BlocklistView.swift
//  Reclaim
//
//  Manage blocked domains and templates
//

import SwiftUI

struct BlocklistView: View {
    @StateObject private var viewModel = BlocklistViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddDomain = false
    @State private var newDomain = ""
    @State private var showAIChat = false
    @State private var showBlockScreens = false

    var body: some View {
        ZStack {
            // Background
            ReclaimColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Blocklist")
                                .font(ReclaimTypography.h2)
                                .foregroundColor(ReclaimColors.textPrimary)
                            Text("\(viewModel.domains.count) domains blocked")
                                .font(ReclaimTypography.body)
                                .foregroundColor(ReclaimColors.textSecondary)
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
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                    // Content Blocker Status
                    ContentBlockerStatusView()
                        .padding(.horizontal, Spacing.lg)

                    // Panic Button - If user is trying to add a domain, they might be struggling
                    PanicButton {
                        showAIChat = true
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    // Add Domain Button
                    Button {
                        showAddDomain = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Domain")
                        }
                    }
                    .primaryButton()
                    .padding(.horizontal, Spacing.lg)

                    // Screen Time Authorization (iOS 16+)
                    if #available(iOS 16.0, *) {
                        ScreenTimeAuthView()
                            .padding(.horizontal, Spacing.lg)
                    }
                    
                    // Block Screens
                    Button {
                        showBlockScreens = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(ReclaimColors.primary)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Custom Block Screens")
                                    .font(ReclaimTypography.label)
                                    .foregroundColor(ReclaimColors.textPrimary)
                                Text("Customize what you see when blocked")
                                    .font(ReclaimTypography.caption)
                                    .foregroundColor(ReclaimColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(ReclaimColors.textTertiary)
                        }
                        .padding(Spacing.md)
                        .background(ReclaimColors.backgroundSecondary)
                        .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal, Spacing.lg)

                    // Info Card - Essential Protection
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(ReclaimColors.success)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Essential porn blocking is always active")
                                    .font(ReclaimTypography.label)
                                    .foregroundColor(ReclaimColors.textPrimary)
                                Text("Cannot be disabled for your protection")
                                    .font(ReclaimTypography.caption)
                                    .foregroundColor(ReclaimColors.textSecondary)
                            }

                            Spacer()
                        }

                        // Essential domains count note
                        let essentialCount = viewModel.domains.filter { $0.isPredefined && $0.category == nil }.count
                        if essentialCount > 0 {
                            Text("\(essentialCount) porn sites blocked (too many to display)")
                                .font(ReclaimTypography.caption)
                                .foregroundColor(ReclaimColors.textTertiary)
                                .italic()
                        }
                    }
                    .padding(Spacing.md)
                    .background(ReclaimColors.backgroundSecondary)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(ReclaimColors.success.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.lg)

                    // Optional Templates (Social Media, Maximum)
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        let optionalTemplates = viewModel.templates.filter { $0.id != "essential" }

                        if !optionalTemplates.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Add More Protection")
                                    .font(ReclaimTypography.h5)
                                    .foregroundColor(ReclaimColors.textPrimary)
                                Text("Block social media and streaming platforms")
                                    .font(ReclaimTypography.caption)
                                    .foregroundColor(ReclaimColors.textSecondary)
                            }
                            .padding(.horizontal, Spacing.lg)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(optionalTemplates) { template in
                                        TemplateCard(
                                            name: template.name,
                                            description: descriptionForTemplate(template.id),
                                            icon: iconForTemplate(template.id),
                                            gradient: gradientForTemplate(template.id),
                                            isApplied: viewModel.appliedTemplates.contains(template.id),
                                            isLoading: viewModel.isApplyingTemplate
                                        ) {
                                            Task {
                                                await viewModel.toggleTemplate(template.id)
                                            }
                                        }
                                        .id(template.id)
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                            }
                            .animation(.none, value: viewModel.domains.count)
                        }
                    }

                    // Optional Blocked Domains (organized by category)
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Optional Blocked Domains")
                                .font(ReclaimTypography.h5)
                                .foregroundColor(ReclaimColors.textPrimary)
                            Text("From Recommended and Maximum templates")
                                .font(ReclaimTypography.caption)
                                .foregroundColor(ReclaimColors.textSecondary)
                        }
                        .padding(.horizontal, Spacing.lg)

                        // Filter out Essential category, only show optional categories
                        let optionalDomains = viewModel.domains.filter { domain in
                            // Include domains with categories (Social Media, Streaming, Dating)
                            // or custom domains (non-predefined)
                            domain.category != nil || !domain.isPredefined
                        }

                        if optionalDomains.isEmpty {
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "square.stack")
                                    .font(.system(size: 48))
                                    .foregroundColor(ReclaimColors.textTertiary)

                                Text("No optional domains blocked")
                                    .font(ReclaimTypography.body)
                                    .foregroundColor(ReclaimColors.textSecondary)

                                Text("Apply Recommended or Maximum to add more")
                                    .font(ReclaimTypography.caption)
                                    .foregroundColor(ReclaimColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xl)
                        } else {
                            // Group optional domains by category
                            let groupedDomains = Dictionary(grouping: optionalDomains) { domain -> String in
                                if let category = domain.category {
                                    return category
                                }
                                return "Custom"
                            }

                            // Sort categories: Social Media, Streaming, Dating, Custom
                            let categoryOrder = ["Social Media", "Streaming", "Dating", "Custom"]
                            let sortedCategories = groupedDomains.keys.sorted { cat1, cat2 in
                                let index1 = categoryOrder.firstIndex(of: cat1) ?? 999
                                let index2 = categoryOrder.firstIndex(of: cat2) ?? 999
                                return index1 < index2
                            }

                            ForEach(sortedCategories, id: \.self) { category in
                                if let domains = groupedDomains[category], !domains.isEmpty {
                                    DomainCategorySection(
                                        title: category,
                                        count: domains.count,
                                        templateSource: templateSourceForCategory(category),
                                        domains: domains,
                                        onDelete: { domainId in
                                            Task {
                                                await viewModel.removeDomain(domainId)
                                            }
                                        }
                                    )
                                    .padding(.horizontal, Spacing.lg)
                                    .id(category)
                                }
                            }
                            .animation(.none, value: viewModel.domains.count)
                        }
                    }
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .errorAlert($viewModel.error)
        .transaction { transaction in
            transaction.animation = nil
        }
        .sheet(isPresented: $showAddDomain) {
            AddDomainSheet(newDomain: $newDomain) {
                Task {
                    await viewModel.addDomain(newDomain)
                    newDomain = ""
                    showAddDomain = false
                }
            }
        }
        .sheet(isPresented: $showAIChat) {
            AIChatView(initialMessage: "I'm struggling right now and thinking about adding a domain to my blocklist")
        }
        .sheet(isPresented: $showBlockScreens) {
            BlockScreensListView()
        }
        .task {
            await viewModel.loadBlocklist()
        }
    }

    // MARK: - Helper Functions

    private func iconForTemplate(_ templateId: String) -> String {
        switch templateId {
        case "essential":
            return "eye.slash.fill"
        case "recommended":
            return "bubble.left.and.bubble.right.fill"
        case "maximum":
            return "sparkles"
        default:
            return "shield.fill"
        }
    }

    private func descriptionForTemplate(_ templateId: String) -> String {
        switch templateId {
        case "recommended":
            return "Social media platforms"
        case "maximum":
            return "Social + streaming + dating"
        default:
            return ""
        }
    }

    private func gradientForTemplate(_ templateId: String) -> LinearGradient {
        switch templateId {
        case "essential":
            return ReclaimColors.dangerGradient
        case "recommended":
            return ReclaimColors.primaryGradient
        case "maximum":
            return LinearGradient(
                colors: [Color(hex: "EC4899"), Color(hex: "F43F5E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return ReclaimColors.successGradient
        }
    }

    private func templateSourceForCategory(_ category: String) -> String {
        switch category {
        case "Social Media":
            return "Recommended"
        case "Streaming", "Dating":
            return "Maximum"
        case "Custom":
            return "Your Domains"
        default:
            return ""
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let name: String
    let description: String
    let icon: String
    let gradient: LinearGradient
    let isApplied: Bool
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(gradient)
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ReclaimColors.textSecondary))
                            .scaleEffect(0.8)
                    } else if isApplied {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ReclaimColors.success)
                    }
                }

                Text(name)
                    .font(ReclaimTypography.label)
                    .foregroundColor(ReclaimColors.textPrimary)

                Text(description)
                    .font(ReclaimTypography.caption)
                    .foregroundColor(ReclaimColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.md)
            .frame(width: 180, height: 120)
            .cardStyle()
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
}

// MARK: - Domain Row

struct DomainRow: View {
    let domain: BlocklistDomain
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(domain.domain)
                    .font(ReclaimTypography.label)
                    .foregroundColor(ReclaimColors.textPrimary)

                if let category = domain.category {
                    Text(category)
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textTertiary)
                }
            }

            Spacer()

            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(ReclaimColors.danger)
                }
            }
        }
        .padding(Spacing.sm)
        .background(ReclaimColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Add Domain Sheet

struct AddDomainSheet: View {
    @Binding var newDomain: String
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                ReclaimColors.background.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Text("Add Domain")
                        .font(ReclaimTypography.h3)
                        .foregroundColor(ReclaimColors.textPrimary)

                    TextField("", text: $newDomain)
                        .placeholder(when: newDomain.isEmpty) {
                            Text("example.com").foregroundColor(ReclaimColors.textTertiary)
                        }
                        .autocapitalization(.none)
                        .inputField(icon: "globe")

                    Text("Enter domain without http:// or www.")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)

                    Button {
                        onAdd()
                        dismiss()
                    } label: {
                        Text("Add Domain")
                    }
                    .primaryButton(isEnabled: !newDomain.isEmpty)
                    .disabled(newDomain.isEmpty)

                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Domain Category Section

struct DomainCategorySection: View {
    let title: String
    let count: Int
    let templateSource: String
    let domains: [BlocklistDomain]
    let onDelete: (String) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category header (collapsible)
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack(spacing: Spacing.xs) {
                            Text(title)
                                .font(ReclaimTypography.label)
                                .foregroundColor(ReclaimColors.textPrimary)

                            // Template source badge
                            if !templateSource.isEmpty {
                                Text(templateSource)
                                    .font(ReclaimTypography.captionSmall)
                                    .foregroundColor(ReclaimColors.textTertiary)
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(ReclaimColors.background)
                                    .cornerRadius(CornerRadius.xs)
                            }
                        }

                        Text("\(count) domains")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textTertiary)
                    }

                    Spacer()

                    // Lock icon for predefined categories
                    if domains.first?.isPredefined == true {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(ReclaimColors.textTertiary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(ReclaimColors.textSecondary)
                }
                .padding(Spacing.md)
                .background(ReclaimColors.backgroundSecondary)
                .cornerRadius(CornerRadius.md)
            }

            // Domain list (expandable)
            if isExpanded {
                VStack(spacing: Spacing.xs) {
                    ForEach(domains, id: \.id) { domain in
                        DomainRow(domain: domain, canDelete: !domain.isPredefined) {
                            onDelete(domain.id)
                        }
                    }
                }
                .padding(.leading, Spacing.xs)
            }
        }
    }
}

#Preview {
    BlocklistView()
}
