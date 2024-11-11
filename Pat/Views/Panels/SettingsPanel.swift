import SwiftUI

struct SettingsPanel: View {
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(title: "Settings", showAddButton: false) {
                print("Add tapped")  // Placeholder action
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(height: 50)
                            .overlay(
                                Text("Setting Option Placeholder")
                                    .foregroundColor(.gray)
                            )
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
    }
}
