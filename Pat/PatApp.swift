import SwiftUI

@main
struct PatApp: App {
    @StateObject private var authState = AuthState()
    
    var body: some Scene {
        WindowGroup {
            if authState.isAuthenticated {
                HomeView()
                    .environmentObject(authState)
            } else {
                SignInView()
                    .environmentObject(authState)
            }
        }
    }
}

#Preview("Logged In") {
    HomeView()
        .environmentObject({
            let auth = AuthState()
            auth.isAuthenticated = true
            return auth
        }())
}

#Preview("Logged Out") {
    SignInView()
        .environmentObject(AuthState())
}
