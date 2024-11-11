import SwiftUI

struct CreateAccountView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            CustomHeader(title: "Create Account", showAddButton: false)
            
            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 16) {
                        AuthField(
                            title: "Name",
                            placeholder: "Enter your name",
                            isSecure: false,
                            text: $name
                        )
                        
                        AuthField(
                            title: "Email",
                            placeholder: "Enter your email",
                            isSecure: false,
                            text: $email
                        )
                        
                        AuthField(
                            title: "Password",
                            placeholder: "Create a password",
                            isSecure: true,
                            text: $password
                        )
                        
                        AuthField(
                            title: "Confirm Password",
                            placeholder: "Confirm your password",
                            isSecure: true,
                            text: $confirmPassword
                        )
                    }
                    
                    AuthButton(title: "Create Account") {
                        // Handle account creation
                        print("Create account tapped")
                    }
                    
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        Button("Sign In") {
                            // Navigate to sign in
                            print("Navigate to sign in")
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.top, 40)
            }
        }
    }
}

#Preview {
    CreateAccountView()
}
