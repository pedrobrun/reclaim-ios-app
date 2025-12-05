//
//  BlockScreensViewModel.swift
//  Reclaim
//
//  ViewModel for managing block screens
//

import Foundation
import Combine
import UIKit

@MainActor
class BlockScreensViewModel: ObservableObject {
    @Published var blockScreens: [BlockScreen] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isUploading = false
    
    private let service = BlockScreenService.shared
    
    func loadBlockScreens() async {
        isLoading = true
        error = nil
        
        do {
            blockScreens = try await service.getBlockScreens()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func createBlockScreen(image: UIImage?, message: String?, isActive: Bool) async {
        isUploading = true
        error = nil
        
        do {
            var imageDataString: String? = nil
            
            if let image = image {
                // Compress image and convert to base64
                // Limit size to avoid payload too large errors
                if let jpegData = image.jpegData(compressionQuality: 0.7) {
                    // Prefix for data URI
                    imageDataString = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                }
            }
            
            let request = CreateBlockScreenRequest(
                message: message,
                isActive: isActive,
                imageData: imageDataString
            )
            
            let newBlockScreen = try await service.createBlockScreen(request: request)
            
            // If active, deactivate others locally for immediate UI update
            if isActive {
                blockScreens = blockScreens.map { screen in
                    // Create a copy with isActive = false
                    // Since BlockScreen is a struct, this creates a new instance
                     BlockScreen(
                        id: screen.id,
                        message: screen.message,
                        imageUrl: screen.imageUrl,
                        isActive: false,
                        createdAt: screen.createdAt,
                        updatedAt: screen.updatedAt
                    )
                }
            }
            
            blockScreens.insert(newBlockScreen, at: 0)
        } catch {
            self.error = error
        }
        
        isUploading = false
    }
    
    func deleteBlockScreen(_ blockScreen: BlockScreen) async {
        do {
            try await service.deleteBlockScreen(id: blockScreen.id)
            blockScreens.removeAll { $0.id == blockScreen.id }
        } catch {
            self.error = error
        }
    }
    
    func activateBlockScreen(_ blockScreen: BlockScreen) async {
        do {
            let request = UpdateBlockScreenRequest(message: nil, isActive: true)
            let updatedScreen = try await service.updateBlockScreen(id: blockScreen.id, request: request)
            
            // Update local list
            blockScreens = blockScreens.map { screen in
                if screen.id == updatedScreen.id {
                    return updatedScreen
                } else {
                    // Deactivate others
                    return BlockScreen(
                        id: screen.id,
                        message: screen.message,
                        imageUrl: screen.imageUrl,
                        isActive: false,
                        createdAt: screen.createdAt,
                        updatedAt: screen.updatedAt
                    )
                }
            }
        } catch {
            self.error = error
        }
    }
}

