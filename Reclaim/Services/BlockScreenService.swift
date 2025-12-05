//
//  BlockScreenService.swift
//  Reclaim
//
//  Service for managing block screens
//

import Foundation

class BlockScreenService {
    static let shared = BlockScreenService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - Block Screens
    
    func getBlockScreens() async throws -> [BlockScreen] {
        return try await apiClient.request(.getBlockScreens)
    }
    
    func createBlockScreen(request: CreateBlockScreenRequest) async throws -> BlockScreen {
        return try await apiClient.request(.createBlockScreen, body: request)
    }
    
    func updateBlockScreen(id: String, request: UpdateBlockScreenRequest) async throws -> BlockScreen {
        return try await apiClient.request(.updateBlockScreen(id), body: request)
    }
    
    func deleteBlockScreen(id: String) async throws {
        try await apiClient.request(.deleteBlockScreen(id))
    }
}






