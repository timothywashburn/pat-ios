import SwiftUI

enum AuthError: Error {
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    case keychainError(KeychainError)
    case refreshFailed
}

class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    private var userId: String?
    private let keychainHelper = KeychainHelper.standard
    private let tokenService = "dev.timothyw.pat"
    
    private var authToken: String? {
        didSet {
            do {
                if let token = authToken {
                    try keychainHelper.save(Data(token.utf8), service: tokenService, account: "authToken")
                } else {
                    try keychainHelper.delete(service: tokenService, account: "authToken")
                }
            } catch {
                print("Keychain error saving auth token: \(error)")
            }
        }
    }
    
    private var refreshToken: String? {
        didSet {
            do {
                if let token = refreshToken {
                    try keychainHelper.save(Data(token.utf8), service: tokenService, account: "refreshToken")
                } else {
                    try keychainHelper.delete(service: tokenService, account: "refreshToken")
                }
            } catch {
                print("Keychain error saving refresh token: \(error)")
            }
        }
    }
    
    init() {
        Task {
            await loadAndValidateStoredTokens()
        }
    }
    
    private func loadAndValidateStoredTokens() async {
        let hasAuthToken = (try? keychainHelper.read(service: tokenService, account: "authToken")) != nil
        let hasRefreshToken = (try? keychainHelper.read(service: tokenService, account: "refreshToken")) != nil
        
        guard hasAuthToken && hasRefreshToken,
              let authData = try? keychainHelper.read(service: tokenService, account: "authToken"),
              let refreshData = try? keychainHelper.read(service: tokenService, account: "refreshToken"),
              let auth = String(data: authData, encoding: .utf8),
              let refresh = String(data: refreshData, encoding: .utf8) else {
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        self.authToken = auth
        self.refreshToken = refresh
        
        do {
            try await refreshAuthToken()
        } catch AuthError.refreshFailed {
            await MainActor.run {
                self.signOut()
            }
        } catch {
            print("An error occurred: \(error)")
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func refreshTokensIfNeeded() async throws {
        guard refreshToken != nil else {
            throw AuthError.refreshFailed
        }
        
        try await refreshAuthToken()
    }
    
    private func refreshAuthToken() async throws {
        guard let refreshToken = self.refreshToken else {
            throw AuthError.refreshFailed
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refreshToken": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.invalidResponse
        }
        
        guard let success = json["success"] as? Bool,
              let responseData = json["data"] as? [String: Any],
              let newToken = responseData["token"] as? String,
              let newRefreshToken = responseData["refreshToken"] as? String,
              let user = responseData["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw AuthError.invalidResponse
        }
        
        if !success {
            throw AuthError.refreshFailed
        }
        
        await MainActor.run {
            self.authToken = newToken
            self.refreshToken = newRefreshToken
            self.userId = userId
            self.isAuthenticated = true
        }
    }
    
    func createAccount(name: String, email: String, password: String) async throws {
        let url = URL(string: "\(PatConfig.apiURL)/api/account/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let success = json?["success"] as? Bool else {
                throw AuthError.invalidResponse
            }
            
            if !success {
                let errorMessage = (json?["error"] as? String) ?? "Failed to create account"
                throw AuthError.serverError(errorMessage)
            }
            
            try await signIn(email: email, password: password)
            
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let url = URL(string: "\(PatConfig.apiURL)/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let success = json?["success"] as? Bool,
                  let responseData = json?["data"] as? [String: Any],
                  let token = responseData["token"] as? String,
                  let refreshToken = responseData["refreshToken"] as? String,
                  let user = responseData["user"] as? [String: Any],
                  let userId = user["id"] as? String else {
                throw AuthError.invalidResponse
            }
            
            if !success {
                let errorMessage = (json?["error"] as? String) ?? "Invalid credentials"
                throw AuthError.serverError(errorMessage)
            }
            
            await MainActor.run {
                self.authToken = token
                self.refreshToken = refreshToken
                self.userId = userId
                self.isAuthenticated = true
            }
            
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    func signOut() {
        isAuthenticated = false
        authToken = nil
        refreshToken = nil
        userId = nil
        isLoading = false
    }
}
