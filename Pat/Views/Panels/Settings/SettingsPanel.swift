import SwiftUI

struct SettingsPanel: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var errorMessage: String?
    @Binding var showHamburgerMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(
                title: "Settings",
                showAddButton: false,
                onAddTapped: { },
                showHamburgerMenu: $showHamburgerMenu
            )
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            List {
                PanelManagementSection(errorMessage: $errorMessage)
                TaskCategoriesSection(errorMessage: $errorMessage)
                TaskTypesSection(errorMessage: $errorMessage)
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))
        }
    }
}
