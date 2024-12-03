import SwiftUI

struct CreateAccountView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isValidForm: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 30)
            
            AuthField(title: "Name",
                     placeholder: "Enter your name",
                     isSecure: false,
                     text: $name)
            
            AuthField(title: "Email",
                     placeholder: "Enter your email",
                     isSecure: false,
                     text: $email)
                     
            AuthField(title: "Password",
                     placeholder: "Enter your password",
                     isSecure: true,
                     text: $password)
                     
            AuthField(title: "Confirm Password",
                     placeholder: "Confirm your password",
                     isSecure: true,
                     text: $confirmPassword)
            
            if password != confirmPassword && !confirmPassword.isEmpty {
                Text("Passwords do not match")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            AuthButton(title: isLoading ? "Creating Account..." : "Create Account") {
                Task {
                    isLoading = true
                    errorMessage = nil
                    
                    do {
                        try await authState.registerAccount(name: name, email: email, password: password)
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
            
            Button("Already have an account? Sign in") {
                dismiss()
            }
            .foregroundColor(.blue)
            .padding(.bottom)
        }
        .padding()
        .navigationBarBackButtonHidden(false)
    }
}
