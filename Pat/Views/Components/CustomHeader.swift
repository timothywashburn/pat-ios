import SwiftUI

struct CustomHeader: View {
    let title: String
    let showAddButton: Bool
    let onAddTapped: () -> Void
    var showFilterButton = false
    var isFilterActive = false
    var onFilterTapped: (() -> Void)?
    @Binding var showHamburgerMenu: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showHamburgerMenu = true
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding(.leading, 8)
            
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .padding(.leading, 8)
            
            Spacer()
            
            if showFilterButton {
                Button(action: {
                    onFilterTapped?()
                }) {
                    Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
            }
            
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
