import SwiftUI

class AuthState: ObservableObject {
    static let shared = AuthState()
    
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published private(set) var userInfo: UserInfo?
    
    private var tokens: AuthTokens?
    private let keychain = KeychainHelper.standard
    private let tokenService = "dev.timothyw.pat"
    
    var authToken: String? {
        tokens?.accessToken
    }
    
    var isEmailVerified: Bool {
        userInfo?.isEmailVerified ?? false
    }
    
    private init() {
        Task {
            await loadStoredAuth()
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let request = NetworkRequest(
            endpoint: "/api/auth/login",
            method: .post,
            body: ["email": email, "password": password]
        )
        
        let response = try await NetworkManager.shared.perform(request)
        let loginData = try extractAuthData(from: response)
        
        await MainActor.run {
            updateAuthState(user: loginData.user, tokens: loginData.tokens)
        }
    }
    
    func registerAccount(name: String, email: String, password: String) async throws {
        let request = NetworkRequest(
            endpoint: "/api/auth/register",
            method: .post,
            body: ["name": name, "email": email, "password": password]
        )
        
        _ = try await NetworkManager.shared.perform(request)
        try await signIn(email: email, password: password)
    }
    
    func resendVerificationEmail() async throws {
        guard let token = tokens?.accessToken else { return }
        
        let request = NetworkRequest(
            endpoint: "/api/auth/resend-verification",
            method: .post,
            token: token
        )
        
        _ = try await NetworkManager.shared.perform(request)
    }
    
    func refreshTokensIfNeeded() async throws {
        guard let refreshToken = tokens?.refreshToken else {
            throw AuthError.refreshFailed
        }
        
        let request = NetworkRequest(
            endpoint: "/api/auth/refresh",
            method: .post,
            body: ["refreshToken": refreshToken]
        )
        
        let response = try await NetworkManager.shared.perform(request)
        let authData = try extractAuthData(from: response)
        
        await MainActor.run {
            updateAuthState(user: authData.user, tokens: authData.tokens)
        }
    }
    
    func signOut() {
        clearAuthState()
    }
    
    func updateUserInfo(_ update: (inout UserInfo) -> Void) {
        guard var currentUser = userInfo else { return }
        update(&currentUser)
        self.userInfo = currentUser
        saveUserInfo(currentUser)
    }
    
    private func loadStoredAuth() async {
        if let userData = try? keychain.read(service: tokenService, account: "userInfo") {
            do {
                userInfo = try JSONDecoder().decode(UserInfo.self, from: userData)
            } catch {
                // Failed to decode user info
            }
        }
        
        if let tokenData = try? keychain.read(service: tokenService, account: "tokens") {
            do {
                tokens = try JSONDecoder().decode(AuthTokens.self, from: tokenData)
                try await refreshTokensIfNeeded()
            } catch {
                clearAuthState()
            }
        }
        
        await MainActor.run {
            self.isLoading = false
            self.isAuthenticated = self.tokens != nil
        }
    }
    
    private func updateAuthState(user: UserInfo, tokens: AuthTokens) {
        self.userInfo = user
        self.tokens = tokens
        self.isAuthenticated = true
        
        saveUserInfo(user)
        saveTokens(tokens)
    }
    
    private func clearAuthState() {
        userInfo = nil
        tokens = nil
        isAuthenticated = false
        isLoading = false
        
        try? keychain.delete(service: tokenService, account: "userInfo")
        try? keychain.delete(service: tokenService, account: "tokens")
    }
    
    private func saveUserInfo(_ user: UserInfo) {
        guard let encoded = try? JSONEncoder().encode(user) else { return }
        try? keychain.save(encoded, service: tokenService, account: "userInfo")
    }
    
    private func saveTokens(_ tokens: AuthTokens) {
        guard let encoded = try? JSONEncoder().encode(tokens) else { return }
        try? keychain.save(encoded, service: tokenService, account: "tokens")
    }
    
    private func decodeUser(from dictionary: [String: Any]) throws -> UserInfo {
        guard let id = dictionary["id"] as? String,
              let email = dictionary["email"] as? String,
              let name = dictionary["name"] as? String,
              let isEmailVerified = dictionary["isEmailVerified"] as? Bool else {
            throw AuthError.invalidResponse
        }
        
        return UserInfo(
            id: id,
            email: email,
            name: name,
            isEmailVerified: isEmailVerified
        )
    }
    
    private func extractAuthData(from response: [String: Any]) throws -> (user: UserInfo, tokens: AuthTokens) {
        if let token = response["token"] as? String,
           let refreshToken = response["refreshToken"] as? String,
           let currentUser = userInfo {
            return (currentUser, AuthTokens(accessToken: token, refreshToken: refreshToken))
        }
        
        guard let userData = response["user"] as? [String: Any],
              let token = response["token"] as? String,
              let refreshToken = response["refreshToken"] as? String else {
            throw AuthError.invalidResponse
        }
        
        let user = try decodeUser(from: userData)
        let tokens = AuthTokens(accessToken: token, refreshToken: refreshToken)
        
        return (user, tokens)
    }
}
