//
//  APIError.swift
//  Reclaim
//
//  Core networking errors
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, String?)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError(let code, let message):
            // Use backend message if available, otherwise show generic error
            return message ?? "Server error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// Backend error response structure
nonisolated struct ErrorResponse: Codable {
    let statusCode: Int
    let message: MessageValue
    let error: String?
    let validationErrors: [String]?
    
    // Handle both string and array messages
    nonisolated enum MessageValue: Codable {
        case string(String)
        case array([String])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                throw DecodingError.typeMismatch(MessageValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Message must be String or [String]"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let string):
                try container.encode(string)
            case .array(let array):
                try container.encode(array)
            }
        }
        
        nonisolated var stringValue: String {
            switch self {
            case .string(let str):
                return str
            case .array(let arr):
                return arr.joined(separator: ", ")
            }
        }
    }
}
