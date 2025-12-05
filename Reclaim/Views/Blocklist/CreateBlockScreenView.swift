//
//  CreateBlockScreenView.swift
//  Reclaim
//
//  Create a new block screen
//

import SwiftUI
import PhotosUI

struct CreateBlockScreenView: View {
    @ObservedObject var viewModel: BlockScreensViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var message = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isActive = true
    
    var body: some View {
        NavigationView {
            ZStack {
                ReclaimColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Image Picker
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Motivational Image")
                                .font(ReclaimTypography.label)
                                .foregroundColor(ReclaimColors.textSecondary)
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack {
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .cornerRadius(CornerRadius.md)
                                            .overlay(
                                                ZStack {
                                                    Color.black.opacity(0.3)
                                                    Image(systemName: "camera.fill")
                                                        .font(.title)
                                                        .foregroundColor(.white)
                                                }
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .fill(ReclaimColors.backgroundSecondary)
                                            .frame(height: 200)
                                            .overlay(
                                                VStack(spacing: Spacing.sm) {
                                                    Image(systemName: "photo.badge.plus")
                                                        .font(.system(size: 32))
                                                        .foregroundColor(ReclaimColors.primary)
                                                    Text("Tap to select image")
                                                        .font(ReclaimTypography.body)
                                                        .foregroundColor(ReclaimColors.textSecondary)
                                                }
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Message Input
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Message")
                                .font(ReclaimTypography.label)
                                .foregroundColor(ReclaimColors.textSecondary)
                            
                            TextField("E.g. Remember why you started", text: $message, axis: .vertical)
                                .inputField()
                                .lineLimit(3...6)
                        }
                        
                        // Active Toggle
                        Toggle(isOn: $isActive) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Set as Active")
                                    .font(ReclaimTypography.body)
                                    .foregroundColor(ReclaimColors.textPrimary)
                                Text("This screen will be shown when you access blocked content")
                                    .font(ReclaimTypography.caption)
                                    .foregroundColor(ReclaimColors.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ReclaimColors.primary))
                        
                        Spacer()
                    }
                    .padding(Spacing.lg)
                }
                
                // Loading Overlay
                if viewModel.isUploading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: Spacing.sm) {
                        ProgressView()
                        Text("Uploading...")
                            .font(ReclaimTypography.caption)
                            .foregroundColor(ReclaimColors.textSecondary)
                    }
                    .padding()
                    .background(ReclaimColors.cardBackground)
                    .cornerRadius(CornerRadius.md)
                }
            }
            .navigationTitle("New Block Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ReclaimColors.textPrimary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(ReclaimTypography.label)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(saveDisabled ? ReclaimColors.backgroundTertiary : ReclaimColors.primary)
                            .cornerRadius(CornerRadius.sm)
                    }
                    .disabled(saveDisabled)
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
        }
    }
    
    private var saveDisabled: Bool {
        selectedImage == nil && message.isEmpty
    }
    
    private func save() {
        Task {
            await viewModel.createBlockScreen(
                image: selectedImage,
                message: message,
                isActive: isActive
            )
            
            if viewModel.error == nil {
                dismiss()
            }
        }
    }
}

