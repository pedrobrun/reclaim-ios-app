//
//  OnboardingView.swift
//  Reclaim
//
//  Multi-step onboarding flow for new users
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissions = 1
    case setYourWhy = 2
    case uploadBlockScreen = 3
    case commitment = 4
    case startTrial = 5
    
    var isLast: Bool {
        self == .startTrial
    }
}

struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedTemplate: String? = nil
    @State private var whyText: String = ""
    @State private var blockScreenImage: UIImage? = nil
    @State private var isRequestingPermission = false
    @State private var permissionError: Error?
    
    @EnvironmentObject var authService: AuthService
    private let blocklistService = BlocklistService.shared
    private let blockScreenService = BlockScreenService.shared
    private let userDefaults = UserDefaultsManager.shared
    
    var body: some View {
        ZStack {
            // Background
            ReclaimColors.background.ignoresSafeArea()
            
            TabView(selection: $currentStep) {
                WelcomeStepView(
                    onContinue: { moveToNextStep() }
                )
                .tag(OnboardingStep.welcome)
                
                PermissionStepView(
                    isRequesting: $isRequestingPermission,
                    error: $permissionError,
                    onContinue: { moveToNextStep() },
                    onSkip: { moveToNextStep() }
                )
                .tag(OnboardingStep.permissions)
                
                SetYourWhyStepView(
                    whyText: $whyText,
                    onContinue: { moveToNextStep() },
                    onSkip: { moveToNextStep() }
                )
                .tag(OnboardingStep.setYourWhy)
                
                UploadBlockScreenStepView(
                    selectedImage: $blockScreenImage,
                    onContinue: { moveToNextStep() },
                    onSkip: { moveToNextStep() }
                )
                .tag(OnboardingStep.uploadBlockScreen)
                
                CommitmentStepView(
                    selectedTemplate: $selectedTemplate,
                    onContinue: { moveToNextStep() }
                )
                .tag(OnboardingStep.commitment)
                
                SubscriptionPaywallView(
                    selectedTemplate: selectedTemplate ?? "essential",
                    onSubscribe: { completeOnboarding() }
                )
                .tag(OnboardingStep.startTrial)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
    
    // MARK: - Navigation
    
    private func moveToNextStep() {
        withAnimation {
            if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }
    
    private func completeOnboarding() {
        Task {
            do {
                // 1. Save profile data (why and preferred template)
                try await authService.updateProfile(
                    name: nil,
                    email: nil,
                    why: whyText.isEmpty ? nil : whyText,
                    preferredTemplate: selectedTemplate
                )
                
                // 2. Upload block screen image if provided
                if let image = blockScreenImage {
                    var imageDataString: String? = nil
                    if let jpegData = image.jpegData(compressionQuality: 0.7) {
                        imageDataString = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                    }
                    
                    let blockScreenRequest = CreateBlockScreenRequest(
                        message: nil,
                        isActive: true,
                        imageData: imageDataString
                    )
                    
                    do {
                        _ = try await blockScreenService.createBlockScreen(request: blockScreenRequest)
                    } catch {
                        print("Failed to upload block screen: \(error)")
                        // Don't block onboarding if block screen upload fails
                    }
                }
                
                // 3. Apply selected template if any
                if let template = selectedTemplate {
                    do {
                        try await blocklistService.applyTemplate(template)
                    } catch {
                        print("Failed to apply template: \(error)")
                        // Don't block onboarding if template fails
                    }
                }
                
                // 4. Mark onboarding as complete
                userDefaults.hasCompletedOnboarding = true
                
                // 5. Notify app that onboarding is complete
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
                }
            } catch {
                print("Failed to complete onboarding: \(error)")
                // Still mark as complete to avoid blocking user
                userDefaults.hasCompletedOnboarding = true
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(AuthService.shared)
}

