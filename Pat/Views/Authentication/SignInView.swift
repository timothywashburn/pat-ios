import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome Back")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.bottom, 30)
                
                AuthField(title: "Email",
                         placeholder: "Enter your email",
                         isSecure: false,
                         text: $email)
                         
                AuthField(title: "Password",
                         placeholder: "Enter your password",
                         isSecure: true,
                         text: $password)
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                AuthButton(title: isLoading ? "Signing In..." : "Sign In") {
                    Task {
                        isLoading = true
                        errorMessage = nil
                        
                        do {
                            try await authState.signIn(email: email, password: password)
                        } catch AuthError.serverError(let message) {
                            errorMessage = message
                        } catch AuthError.invalidResponse {
                            errorMessage = "Invalid response from server"
                        } catch AuthError.networkError {
                            errorMessage = "Network error. Please try again"
                        } catch {
                            errorMessage = "An unexpected error occurred"
                        }
                        
                        isLoading = false
                    }
                }
                .disabled(!isValidForm || isLoading)
                
                Spacer()
                
                NavigationLink(destination: CreateAccountView()) {
                    Text("Don't have an account? Create one")
                        .foregroundColor(.blue)
                }
                .padding(.bottom)
            }
            .padding()
        }
    }
}
