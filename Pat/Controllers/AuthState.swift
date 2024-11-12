import SwiftUI

class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    
    func signIn(email: String, password: String) {
        // TODO: Implement actual authentication
        isAuthenticated = true
    }
    
    func signOut() {
        isAuthenticated = false
    }
}
