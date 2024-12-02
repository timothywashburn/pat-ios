import Foundation

struct UserInfo: Codable {
    let id: String
    let email: String
    let name: String
    let isEmailVerified: Bool
}

enum AuthError: Error {
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    case keychainError(KeychainError)
    case refreshFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        case .refreshFailed:
            return "Failed to refresh authentication"
        }
    }
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
}
