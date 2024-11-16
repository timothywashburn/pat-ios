import SwiftUI

struct PatConfig {
    static let apiURL = "https://mac.timothyw.dev"
}

@main
struct PatApp: App {
    @StateObject private var authState = AuthState()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authState.isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else if authState.isAuthenticated {
                    HomeView()
                        .environmentObject(authState)
                        .preloadKeyboard()
                        .transition(.opacity)
                } else {
                    SignInView()
                        .environmentObject(authState)
                        .preloadKeyboard()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: authState.isLoading)
            .animation(.easeOut(duration: 0.3), value: authState.isAuthenticated)
        }
    }
}

#Preview("Loading") {
    LoadingView()
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
