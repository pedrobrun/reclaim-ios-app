//
//  AppBlockingView.swift
//  Reclaim
//
//  View for selecting apps and categories to block using Screen Time API
//

import SwiftUI
import FamilyControls

@available(iOS 16.0, *)
struct AppBlockingView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Block Apps & Browsers")
                    .font(ReclaimTypography.h2)
                    .foregroundColor(ReclaimColors.textPrimary)
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

            // Explanation
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Select apps and categories to block.")
                    .font(ReclaimTypography.body)
                    .foregroundColor(ReclaimColors.textSecondary)
                
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(ReclaimColors.primary)
                        .font(.system(size: 14))
                        .padding(.top, 2)
                    Text("To block all browsers (Chrome, Firefox, etc.), make sure to select the 'Web Browsers' category in the picker.")
                        .font(ReclaimTypography.caption)
                        .foregroundColor(ReclaimColors.textPrimary)
                }
                .padding(Spacing.sm)
                .background(ReclaimColors.primary.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
            .padding(.horizontal, Spacing.lg)

            // Select Apps Button
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: "plus.app.fill")
                    Text("Select Apps & Categories")
                }
                .primaryButton()
            }
            .padding(.horizontal, Spacing.lg)
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            
            // List of blocked items (Summary)
            List {
                if !selection.categoryTokens.isEmpty {
                    Section("Blocked Categories") {
                        Text("\(selection.categoryTokens.count) categories selected")
                    }
                }
                if !selection.applicationTokens.isEmpty {
                    Section("Blocked Apps") {
                        Text("\(selection.applicationTokens.count) apps selected")
                    }
                }
                if !selection.webDomainTokens.isEmpty {
                    Section("Blocked Websites") {
                        Text("\(selection.webDomainTokens.count) websites selected")
                    }
                }
                
                if selection.categoryTokens.isEmpty && selection.applicationTokens.isEmpty && selection.webDomainTokens.isEmpty {
                    Section {
                        Text("No apps or categories selected yet.")
                            .foregroundColor(ReclaimColors.textSecondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)

            Spacer()
            
            // Save Button
            Button {
                saveSelection()
                dismiss()
            } label: {
                Text("Save & Block")
                    .primaryButton()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .background(ReclaimColors.background.ignoresSafeArea())
        .onChange(of: selection) { newSelection in
            // We can auto-save if desired, but let's wait for "Save & Block"
        }
        .onAppear {
            // Load existing selection from ScreenTimeManager
            screenTimeManager.loadSelection()
            selection = screenTimeManager.savedSelection
        }
    }

    private func saveSelection() {
        screenTimeManager.saveSelection(selection)
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        AppBlockingView()
    }
}

