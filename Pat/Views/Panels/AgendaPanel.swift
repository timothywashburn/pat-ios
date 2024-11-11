import SwiftUI

struct AgendaPanel: View {
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(title: "Agenda", showAddButton: true) {
                print("Add tapped")  // Placeholder action
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(height: 100)
                            .overlay(
                                Text("Agenda Item Placeholder")
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
