import SwiftUI

struct CreateAccountView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
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
                     
            AuthField(title: "Confirm Password",
                     placeholder: "Confirm your password",
                     isSecure: true,
                     text: $confirmPassword)
            
            AuthButton(title: "Create Account") {
                // TODO: Implement account creation
                authState.signIn(email: email, password: password)
            }
            
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
