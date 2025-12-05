//
//  CommitmentStepView.swift
//  Reclaim
//
//  Choose commitment level (template selection)
//

import SwiftUI

struct CommitmentStepView: View {
    @Binding var selectedTemplate: String?
    let onContinue: () -> Void
    
    @State private var templates: [BlocklistTemplate] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: Spacing.md) {
                Text("Choose Your Commitment Level")
                    .font(ReclaimTypography.h1)
                    .foregroundColor(ReclaimColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Select a blocklist that matches your recovery goals. You can always customize it later.")
                    .font(ReclaimTypography.body)
                    .foregroundColor(ReclaimColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
            
            // Templates
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ReclaimColors.primary))
            } else {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(templates) { template in
                            TemplateSelectionCard(
                                template: template,
                                isSelected: selectedTemplate == template.id,
                                onSelect: {
                                    selectedTemplate = template.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            
            Spacer()
            
            // Continue Button
            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .modifier(PrimaryButtonStyle(isEnabled: selectedTemplate != nil))
            }
            .disabled(selectedTemplate == nil)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .task {
            await loadTemplates()
        }
    }
    
    private func loadTemplates() async {
        isLoading = true
        do {
            templates = try await BlocklistService.shared.getTemplates()
        } catch {
            print("Failed to load templates: \(error)")
            // Fallback templates
            templates = [
                BlocklistTemplate(
                    id: "essential",
                    name: "Starter",
                    description: "Blocks top 100 porn sites",
                    count: 100
                ),
                BlocklistTemplate(
                    id: "recommended",
                    name: "Strict",
                    description: "Blocks top 1,000 porn sites",
                    count: 1000
                ),
                BlocklistTemplate(
                    id: "maximum",
                    name: "Nuclear",
                    description: "Blocks everything, maximum protection",
                    count: 10000
                )
            ]
        }
        isLoading = false
    }
}

struct TemplateSelectionCard: View {
    let template: BlocklistTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(template.name)
                        .font(ReclaimTypography.h4)
                        .foregroundColor(ReclaimColors.textPrimary)
                    
                    Text(template.description)
                        .font(ReclaimTypography.bodySmall)
                        .foregroundColor(ReclaimColors.textSecondary)
                    
                    Text("\(template.count) domains")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textTertiary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ReclaimColors.success)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(ReclaimColors.textTertiary)
                }
            }
            .padding(Spacing.lg)
            .background(
                isSelected ?
                    ReclaimColors.primary.opacity(0.1) :
                    ReclaimColors.backgroundSecondary
            )
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        isSelected ? ReclaimColors.primary : ReclaimColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CommitmentStepView(
        selectedTemplate: .constant(nil),
        onContinue: {}
    )
}

