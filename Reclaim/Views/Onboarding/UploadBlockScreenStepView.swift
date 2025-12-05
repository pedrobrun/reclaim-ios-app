//
//  UploadBlockScreenStepView.swift
//  Reclaim
//
//  Step to upload a motivational image for block screens
//

import SwiftUI
import PhotosUI

struct UploadBlockScreenStepView: View {
    @Binding var selectedImage: UIImage?
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: Spacing.md) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(ReclaimColors.primary)
                
                Text("Add a Motivational Image")
                    .font(ReclaimTypography.h1)
                    .foregroundColor(ReclaimColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Choose a photo that reminds you why you're on this journey. This will appear when you try to access blocked content.")
                    .font(ReclaimTypography.body)
                    .foregroundColor(ReclaimColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
            
            // Image Picker
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(CornerRadius.lg)
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button {
                                            selectedImage = nil
                                            selectedItem = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .padding(Spacing.md)
                                    }
                                }
                            )
                    } else {
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(ReclaimColors.backgroundSecondary)
                            .frame(height: 300)
                            .overlay(
                                VStack(spacing: Spacing.md) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 48))
                                        .foregroundColor(ReclaimColors.primary)
                                    Text("Tap to select image")
                                        .font(ReclaimTypography.body)
                                        .foregroundColor(ReclaimColors.textSecondary)
                                    Text("Optional")
                                        .font(ReclaimTypography.caption)
                                        .foregroundColor(ReclaimColors.textTertiary)
                                }
                            )
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
            
            // Buttons
            VStack(spacing: Spacing.md) {
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .modifier(PrimaryButtonStyle())
                }
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .modifier(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    UploadBlockScreenStepView(
        selectedImage: .constant(nil),
        onContinue: {},
        onSkip: {}
    )
}

