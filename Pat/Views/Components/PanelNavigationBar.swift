import SwiftUI

struct PanelNavigationBar: View {
    @Binding var selectedPanel: Panel
    
    var body: some View {
        HStack {
            ForEach(Panel.allCases, id: \.rawValue) { panel in
                Spacer()
                VStack {
                    Image(systemName: panel.icon)
                        .font(.system(size: 24))
                    Text(panel.title)
                        .font(.caption)
                }
                .foregroundColor(selectedPanel == panel ? .blue : .gray)
                .onTapGesture {
                    withAnimation {
                        selectedPanel = panel
                    }
                }
                Spacer()
            }
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .top
        )
    }
}
