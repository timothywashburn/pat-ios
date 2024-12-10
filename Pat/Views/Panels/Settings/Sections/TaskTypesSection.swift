import SwiftUI

struct TaskTypesSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var errorMessage: String?
    @State private var newType = ""
    
    var body: some View {
        Section("Task Types") {
            ForEach(settingsManager.types, id: \.self) { type in
                SettingsItemRow(
                    title: type,
                    onDelete: { deleteType(type) }
                )
            }
            
            AddNewItemRow(
                placeholder: "New Type",
                text: $newType,
                onAdd: addNewType
            )
        }
    }
    
    private func deleteType(_ type: String) {
        var updatedTypes = settingsManager.types
        updatedTypes.removeAll { $0 == type }
        
        Task {
            do {
                try await settingsManager.updateTaskTypes(updatedTypes)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func addNewType() {
        guard !newType.isEmpty else { return }
        var updatedTypes = settingsManager.types
        updatedTypes.append(newType)
        
        Task {
            do {
                try await settingsManager.updateTaskTypes(updatedTypes)
                newType = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
