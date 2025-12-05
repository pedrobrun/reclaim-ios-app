//
//  APIClient.swift
//  Reclaim
//
//  HTTP client for communicating with NestJS backend
//

import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession

    private init() {
        self.baseURL = Config.apiBaseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Request Methods

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws -> T {
        return try await performRequest(endpoint: endpoint, body: body, retryOn401: true)
    }
    
    private func performRequest<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable?,
        retryOn401: Bool
    ) async throws -> T {
        let request = try buildRequest(endpoint, body: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Re-throw cancellation errors as-is (they're expected when navigating away)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw error
            }
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle 401 Unauthorized - try to refresh token and retry once
        if httpResponse.statusCode == 401 && retryOn401 && endpoint.requiresAuth {
            if Config.enableLogging {
                print("🔄 Received 401, attempting to refresh token...")
            }
            
            // Try to refresh token
            if let refreshToken = KeychainManager.shared.getRefreshToken() {
                do {
                    let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
                    let refreshResponse: AuthResponse = try await performRequest(
                        endpoint: .refreshToken,
                        body: refreshRequest,
                        retryOn401: false // Don't retry refresh token request
                    )
                    
                    // Save new tokens
                    KeychainManager.shared.saveAccessToken(refreshResponse.accessToken)
                    KeychainManager.shared.saveRefreshToken(refreshResponse.refreshToken)
                    
                    if Config.enableLogging {
                        print("✅ Token refreshed, retrying original request...")
                    }
                    
                    // Retry original request with new token
                    return try await performRequest(endpoint: endpoint, body: body, retryOn401: false)
                } catch {
                    if Config.enableLogging {
                        print("❌ Token refresh failed: \(error)")
                    }
                    // Refresh failed, throw original 401 error
                }
            }
        }

        try validateResponse(httpResponse, data: data)

        // Log raw response for debugging
        if Config.enableLogging {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 Raw response (\(data.count) bytes):")
                print(jsonString.prefix(500)) // First 500 chars
            } else {
                print("⚠️ Response is not valid UTF-8 string")
            }
        }
        
        do {
            let decoder = JSONDecoder()
            
            // Backend auth endpoints return camelCase, other endpoints return snake_case
            // Check if we're decoding AuthResponse (or any type that expects camelCase)
            let typeName = String(describing: T.self)
            if typeName.contains("AuthResponse") {
                // Auth endpoints return camelCase - use default keys
                decoder.keyDecodingStrategy = .useDefaultKeys
            } else {
                // Other endpoints return snake_case - convert to camelCase
                decoder.keyDecodingStrategy = .convertFromSnakeCase
            }
            
            // Custom date decoder that handles ISO8601 with fractional seconds
            // Backend returns: "2025-11-15T22:31:01.607Z"
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try ISO8601 with fractional seconds first
                let formatterWithFractional = ISO8601DateFormatter()
                formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = formatterWithFractional.date(from: dateString) {
                    return date
                }
                
                // Fallback to standard ISO8601
                let formatterStandard = ISO8601DateFormatter()
                formatterStandard.formatOptions = [.withInternetDateTime]
                
                if let date = formatterStandard.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            // Log detailed decoding error for debugging
            if Config.enableLogging {
                print("❌ Decoding error: \(decodingError)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Response JSON: \(jsonString)")
                }
                
                // Print detailed decoding error info
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: \(key.stringValue)")
                    print("   Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: expected \(type)")
                    print("   Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type)")
                    print("   Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
            throw APIError.decodingError(decodingError)
        } catch {
            if Config.enableLogging {
                print("❌ Decoding error (non-DecodingError): \(error)")
            }
            throw APIError.decodingError(error)
        }
    }

    func request(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws {
        let request = try buildRequest(endpoint, body: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle 401 Unauthorized - try to refresh token and retry once
        if httpResponse.statusCode == 401 && endpoint.requiresAuth {
            if Config.enableLogging {
                print("🔄 Received 401, attempting to refresh token...")
            }
            
            // Try to refresh token
            if let refreshToken = KeychainManager.shared.getRefreshToken() {
                do {
                    let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
                    let refreshResponse: AuthResponse = try await performRequest(
                        endpoint: .refreshToken,
                        body: refreshRequest,
                        retryOn401: false
                    )
                    
                    // Save new tokens
                    KeychainManager.shared.saveAccessToken(refreshResponse.accessToken)
                    KeychainManager.shared.saveRefreshToken(refreshResponse.refreshToken)
                    
                    if Config.enableLogging {
                        print("✅ Token refreshed, retrying original request...")
                    }
                    
                    // Retry original request with new token
                    let retryRequest = try buildRequest(endpoint, body: body)
                    let (retryData, retryResponse) = try await session.data(for: retryRequest)
                    
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    try validateResponse(retryHttpResponse, data: retryData)
                    return
                } catch {
                    if Config.enableLogging {
                        print("❌ Token refresh failed: \(error)")
                    }
                }
            }
        }

        try validateResponse(httpResponse, data: data)
    }

    // MARK: - Streaming (for AI chat)

    func stream(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Build request (this will add auth token if needed)
                    var request = try buildRequest(endpoint, body: body)
                    
                    // Log request details for debugging
                    if Config.enableLogging {
                        print("🌐 Stream request to: \(endpoint.path)")
                        if let authHeader = request.value(forHTTPHeaderField: "Authorization") {
                            print("🔑 Authorization header present: \(String(authHeader.prefix(30)))...")
                        } else {
                            print("⚠️ No Authorization header found!")
                        }
                    }
                    
                    var bytes: URLSession.AsyncBytes
                    var response: URLResponse
                    
                    // First attempt
                    (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    // Handle 401 - try to refresh token and retry FIRST (before other error handling)
                    if httpResponse.statusCode == 401 && endpoint.requiresAuth {
                        if Config.enableLogging {
                            print("🔄 Received 401 in stream, attempting to refresh token...")
                        }
                        
                        // Try to refresh token
                        if let refreshToken = KeychainManager.shared.getRefreshToken() {
                            do {
                                let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
                                let refreshResponse: AuthResponse = try await performRequest(
                                    endpoint: .refreshToken,
                                    body: refreshRequest,
                                    retryOn401: false
                                )
                                
                                // Save new tokens
                                KeychainManager.shared.saveAccessToken(refreshResponse.accessToken)
                                KeychainManager.shared.saveRefreshToken(refreshResponse.refreshToken)
                                
                                if Config.enableLogging {
                                    print("✅ Token refreshed, retrying stream request...")
                                }
                                
                                // Retry with new token
                                request = try buildRequest(endpoint, body: body)
                                (bytes, response) = try await session.bytes(for: request)
                                
                                guard let retryHttpResponse = response as? HTTPURLResponse else {
                                    continuation.finish(throwing: APIError.invalidResponse)
                                    return
                                }
                                
                                guard (200...299).contains(retryHttpResponse.statusCode) else {
                                    continuation.finish(throwing: APIError.serverError(retryHttpResponse.statusCode, nil))
                                    return
                                }
                            } catch {
                                if Config.enableLogging {
                                    print("❌ Token refresh failed in stream: \(error)")
                                }
                                continuation.finish(throwing: APIError.unauthorized)
                                return
                            }
                        } else {
                            continuation.finish(throwing: APIError.unauthorized)
                            return
                        }
                    }

                    // Handle other non-200 status codes after 401 handling
                    if !(200...299).contains(httpResponse.statusCode) {
                        // Try to read error message from response body
                        var errorMessage: String? = nil
                        do {
                            var errorData = Data()
                            for try await chunk in bytes {
                                errorData.append(chunk)
                                // Limit reading to first 1KB to avoid reading too much
                                if errorData.count > 1024 {
                                    break
                                }
                            }
                            
                            if let errorJson = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                                if let message = errorJson["message"] as? String {
                                    errorMessage = message
                                } else if let errorObj = errorJson["error"] as? [String: Any],
                                          let message = errorObj["message"] as? String {
                                    errorMessage = message
                                }
                            }
                        } catch {
                            // Ignore error reading body
                        }
                        
                        if Config.enableLogging {
                            print("❌ Stream failed with status \(httpResponse.statusCode): \(errorMessage ?? "Unknown error")")
                        }
                        
                        continuation.finish(throwing: APIError.serverError(httpResponse.statusCode, errorMessage))
                        return
                    }

                    // Parse Server-Sent Events
                    for try await line in bytes.lines {
                        if Config.enableLogging {
                            print("📥 SSE line: \(line)")
                        }
                        
                        // SSE format: "data: {...}\n\n"
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6)) // Remove "data: " prefix
                            
                            if Config.enableLogging {
                                print("📦 JSON string: \(jsonString)")
                            }
                            
                            guard let data = jsonString.data(using: .utf8) else {
                                if Config.enableLogging {
                                    print("⚠️ Failed to convert JSON string to data")
                                }
                                continue
                            }
                            
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                
                                if let chunk = json?["chunk"] as? String {
                                    if Config.enableLogging {
                                        print("✅ Yielding chunk: \(String(chunk.prefix(50)))...")
                                    }
                                    continuation.yield(chunk)
                                } else if let done = json?["done"] as? Bool, done {
                                    if Config.enableLogging {
                                        print("✅ Stream done signal received")
                                    }
                                    continuation.finish()
                                    return
                                } else if let error = json?["error"] as? String {
                                    if Config.enableLogging {
                                        print("❌ Stream error: \(error)")
                                    }
                                    continuation.finish(throwing: APIError.serverError(500, error))
                                    return
                                } else {
                                    if Config.enableLogging {
                                        print("⚠️ Unknown JSON format: \(json ?? [:])")
                                    }
                                }
                            } catch {
                                if Config.enableLogging {
                                    print("❌ JSON parsing error: \(error)")
                                    print("   Raw JSON string: \(jsonString)")
                                }
                                // Continue to next line instead of failing
                            }
                        } else if !line.isEmpty {
                            // Non-empty line that doesn't start with "data: " - might be part of SSE protocol
                            if Config.enableLogging {
                                print("ℹ️ Non-data line: \(line)")
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func buildRequest(_ endpoint: APIEndpoint, body: Encodable?) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if required
        if endpoint.requiresAuth {
            // KeychainManager is nonisolated, so we can call it directly
            let token = KeychainManager.shared.getAccessToken()
            
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                if Config.enableLogging {
                    print("🔑 Adding auth token to request: \(endpoint.path)")
                    print("🔑 Token (first 20 chars): \(String(token.prefix(20)))...")
                    print("🔑 Full token length: \(token.count) chars")
                }
            } else {
                if Config.enableLogging {
                    print("⚠️ No token found for authenticated endpoint: \(endpoint.path)")
                    print("⚠️ Checking if refresh token exists...")
                    if let refreshToken = KeychainManager.shared.getRefreshToken() {
                        print("⚠️ Refresh token exists (first 20 chars): \(String(refreshToken.prefix(20)))...")
                        print("⚠️ Token may have expired - user needs to login again or refresh token")
                    } else {
                        print("⚠️ No refresh token found - user needs to login")
                    }
                }
            }
        }

        // Add body if present
        if let body = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            // Try to get message from backend
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(response.statusCode, errorResponse.message.stringValue)
            }
            throw APIError.unauthorized
        case 403:
            // Try to get message from backend
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(response.statusCode, errorResponse.message.stringValue)
            }
            throw APIError.forbidden
        case 404:
            // Try to get message from backend
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(response.statusCode, errorResponse.message.stringValue)
            }
            throw APIError.notFound
        case 400...499:
            // Try to decode error message from backend
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                // Prefer validationErrors if available, otherwise use message
                let errorMessage = errorResponse.validationErrors?.joined(separator: ", ") ?? errorResponse.message.stringValue
                throw APIError.serverError(response.statusCode, errorMessage)
            }
            throw APIError.serverError(response.statusCode, nil)
        case 500...599:
            // Try to get message from backend
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(response.statusCode, errorResponse.message.stringValue)
            }
            throw APIError.serverError(response.statusCode, nil)
        default:
            throw APIError.unknown
        }
    }
}
