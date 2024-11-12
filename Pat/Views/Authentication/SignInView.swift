import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var email = ""
    @State private var password = ""
    
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
                
                AuthButton(title: "Sign In") {
                    authState.signIn(email: email, password: password)
                }
                
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
