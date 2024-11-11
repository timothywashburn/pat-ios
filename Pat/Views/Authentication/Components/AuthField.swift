import SwiftUI

struct AuthField: View {
    let title: String
    let placeholder: String
    let isSecure: Bool
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.gray)
                .font(.subheadline)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal)
    }
}
