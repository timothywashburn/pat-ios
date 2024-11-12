import SwiftUI

struct CustomHeader: View {
    let title: String
    let showAddButton: Bool
    let onAddTapped: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .padding(.leading)
            Spacer()
            if showAddButton {
                Button(action: onAddTapped) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
            }
            AccountButton()
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
}
