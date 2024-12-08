import SwiftUI

struct TasksPanel: View {
    @Binding var showHamburgerMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(
                title: "Tasks",
                showAddButton: true,
                onAddTapped: { print("Add tapped") },
                showHamburgerMenu: $showHamburgerMenu
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(height: 80)
                            .overlay(
                                Text("Task Item Placeholder")
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
