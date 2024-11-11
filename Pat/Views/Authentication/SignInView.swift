import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            CustomHeader(title: "Sign In", showAddButton: false)
            
            VStack(spacing: 32) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    AuthField(
                        title: "Email",
                        placeholder: "Enter your email",
                        isSecure: false,
                        text: $email
                    )
                    
                    AuthField(
                        title: "Password",
                        placeholder: "Enter your password",
                        isSecure: true,
                        text: $password
                    )
                }
                
                AuthButton(title: "Sign In") {
                    // Handle sign in
                    print("Sign in tapped")
                }
                
                Button("Forgot Password?") {
                    // Handle forgot password
                    print("Forgot password tapped")
                }
                .foregroundColor(.blue)
                
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Button("Create Account") {
                        // Navigate to create account
                        print("Navigate to create account")
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.top, 40)
            
            Spacer()
        }
    }
}

#Preview {
    SignInView()
}
