//
//  LogRelapseSheet.swift
//  Reclaim
//
//  Quick sheet to record relapse details and reset streak
//

import SwiftUI

struct LogRelapseSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var relapsedAt = Date()
    @State private var selectedTrigger: String?
    @State private var customTrigger = ""
    @State private var mood = ""
    @State private var notes = ""
    @State private var isSaving = false

    private let suggestedTriggers = ["Stress", "Lonely", "Boredom", "Late night", "Social media", "Accidental"]

    var body: some View {
        NavigationView {
            Form {
                Section("When did it happen?") {
                    DatePicker("Relapse Time", selection: $relapsedAt, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                Section("What triggered it?") {
                    WrapChips(
                        options: suggestedTriggers,
                        selectedOption: $selectedTrigger
                    )

                    TextField("Custom trigger", text: $customTrigger)
                        .inputField()
                }

                Section("How were you feeling?") {
                    TextField("Mood (e.g. anxious, tired)", text: $mood)
                        .inputField()
                }

                Section("Any notes?") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .foregroundColor(ReclaimColors.textPrimary)
                        .padding(Spacing.xs)
                        .background(ReclaimColors.backgroundSecondary)
                        .cornerRadius(CornerRadius.md)
                }
            }
            .navigationTitle("Log Relapse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .disabled(isSaving)
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let trigger = customTrigger.isEmpty ? selectedTrigger : customTrigger

        Task {
            await viewModel.logRelapse(
                trigger: trigger,
                mood: mood.isEmpty ? nil : mood,
                notes: notes.isEmpty ? nil : notes,
                relapsedAt: relapsedAt
            )

            isSaving = false

            if viewModel.error == nil {
                dismiss()
            }
        }
    }
}

private struct WrapChips: View {
    let options: [String]
    @Binding var selectedOption: String?

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(options, id: \.self) { option in
                Button {
                    if selectedOption == option {
                        selectedOption = nil
                    } else {
                        selectedOption = option
                    }
                } label: {
                    Text(option)
                        .font(ReclaimTypography.caption)
                        .foregroundColor(selectedOption == option ? .white : ReclaimColors.textSecondary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(selectedOption == option ? ReclaimColors.primary : ReclaimColors.backgroundSecondary)
                        .cornerRadius(CornerRadius.full)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}


