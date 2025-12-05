//
//  KeychainManager.swift
//  Reclaim
//
//  Secure storage for JWT tokens using iOS Keychain
//

import Foundation
import Security

class KeychainManager {
    nonisolated static let shared = KeychainManager()

    private let serviceName = "com.reclaim.app"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"

    private init() {}

    // MARK: - Access Token

    nonisolated func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }

    nonisolated func getAccessToken() -> String? {
        return retrieve(forKey: accessTokenKey)
    }

    nonisolated func deleteAccessToken() {
        delete(forKey: accessTokenKey)
    }

    // MARK: - Refresh Token

    nonisolated func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }

    nonisolated func getRefreshToken() -> String? {
        return retrieve(forKey: refreshTokenKey)
    }

    nonisolated func deleteRefreshToken() {
        delete(forKey: refreshTokenKey)
    }

    // MARK: - Clear All

    nonisolated func clearAll() {
        deleteAccessToken()
        deleteRefreshToken()
    }

    // MARK: - Private Helpers

    nonisolated private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item
        delete(forKey: key)

        // Create new keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    nonisolated private func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    nonisolated private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
