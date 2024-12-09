import SwiftUI

@main
struct PatApp: App {
    @StateObject private var authState = AuthState.shared
    @StateObject private var socketService = SocketService.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authState.isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else if !authState.isAuthenticated {
                    SignInView()
                        .environmentObject(authState)
                        .preloadKeyboard()
                        .transition(.opacity)
                } else if !authState.isEmailVerified {
                    VerifyEmailView()
                        .environmentObject(authState)
                        .transition(.opacity)
                } else {
                    HomeView()
                        .environmentObject(authState)
                        .preloadKeyboard()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: authState.isLoading)
            .animation(.easeOut(duration: 0.3), value: authState.isAuthenticated)
            .animation(.easeOut(duration: 0.3), value: authState.isEmailVerified)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    if authState.isAuthenticated {
                        Task {
                            do {
                                try await authState.refreshTokensIfNeeded()
                                try await settingsManager.loadConfig()
                            } catch {
                                if case AuthError.refreshFailed = error {
                                    await MainActor.run {
                                        authState.signOut()
                                    }
                                }
                                print("token refresh error: \(error)")
                            }
                        }
                    }
                case .background:
                    socketService.disconnect()
                default:
                    break
                }
            }
            .onChange(of: authState.isAuthenticated, initial: true) { oldValue, newValue in
                if newValue {
                    socketService.connect()
                    Task {
                        do {
                            try await settingsManager.loadConfig()
                        } catch {
                            print("settings load error: \(error)")
                        }
                    }
                } else if oldValue {
                    socketService.disconnect()
                }
            }
        }
    }
}
