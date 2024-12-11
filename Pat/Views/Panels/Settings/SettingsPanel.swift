import SwiftUI

struct SettingsPanel: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var errorMessage: String?
    @Binding var editMode: EditMode
    @Binding var showHamburgerMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(
                title: "Settings",
                showAddButton: false,
                onAddTapped: { },
                showHamburgerMenu: $showHamburgerMenu,
                trailing: {
                    AnyView(
                        Button(editMode.isEditing ? "Done" : "Edit") {
                            withAnimation {
                                editMode = editMode.isEditing ? .inactive : .active
                            }
                        }
                    )
                }
            )
            .environment(\.editMode, $editMode)
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            List {
                PanelManagementSection(errorMessage: $errorMessage)
                ItemCategoriesSection(errorMessage: $errorMessage)
                ItemTypesSection(errorMessage: $errorMessage)
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, $editMode)
        }
        .onChange(of: showHamburgerMenu) { _, newValue in
            if !newValue && editMode.isEditing {
                editMode = .inactive
            }
        }
    }
}
