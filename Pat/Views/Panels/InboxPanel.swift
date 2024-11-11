import SwiftUI

struct InboxPanel: View {
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(title: "Inbox", showAddButton: true) {
                print("Add tapped")  // Placeholder action
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(height: 60)
                            .overlay(
                                Text("Quick Note Placeholder")
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
