import SwiftUI

struct VerifyEmailView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var isResending = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Verify Your Email")
                .font(.title)
                .bold()
            
            Text("Please check your email for a verification link. You'll need to verify your email before continuing.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            if let successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.subheadline)
            }
            
            Button {
                Task {
                    await resendVerification()
                }
            } label: {
                Text(isResending ? "Sending..." : "Resend Verification Email")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isResending)
            .padding(.horizontal)
            
            Button("Sign Out", role: .destructive) {
                authState.signOut()
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func resendVerification() async {
        isResending = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await authState.resendVerificationEmail()
            successMessage = "Verification email sent successfully"
        } catch AuthError.serverError(let message) {
            errorMessage = message
        } catch {
            errorMessage = "Failed to resend verification email"
        }
        
        isResending = false
    }
}
