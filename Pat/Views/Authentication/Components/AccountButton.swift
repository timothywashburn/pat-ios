import SwiftUI

struct AccountButton: View {
    @EnvironmentObject var authState: AuthState
    @State private var showingActionSheet = false
    
    var body: some View {
        Button(action: {
            showingActionSheet = true
        }) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
        }
        .padding(.trailing)
        .confirmationDialog(
            "Account Options",
            isPresented: $showingActionSheet,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                authState.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
