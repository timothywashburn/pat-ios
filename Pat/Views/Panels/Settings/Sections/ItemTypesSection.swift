import SwiftUI

struct ItemTypesSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var errorMessage: String?
    @State private var newType = ""
    @State private var typeToDelete: String? = nil
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        Section(header: Text("Item Types")
            .textCase(.none)
            .font(.system(size: 16))) {
            ForEach(settingsManager.types, id: \.self) { type in
                HStack {
                    Text(type)
                    Spacer()
                    if editMode?.wrappedValue.isEditing == true {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if editMode?.wrappedValue.isEditing == true {
                        print("debug: delete triggered for type: \(type)")
                        typeToDelete = type
                    }
                }
            }
            .onMove { source, destination in
                var updatedTypes = settingsManager.types
                updatedTypes.move(fromOffsets: source, toOffset: destination)
                
                Task {
                    do {
                        try await settingsManager.updateItemTypes(updatedTypes)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            
            if editMode?.wrappedValue.isEditing == true {
                AddNewItemRow(
                    placeholder: "New Type",
                    text: $newType,
                    onAdd: addNewType
                )
            }
        }
        .textCase(nil)
        .alert("Delete Type", isPresented: .init(
            get: { typeToDelete != nil },
            set: { if !$0 { typeToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                typeToDelete = nil
            }
            .textCase(nil)
            
            Button("Delete", role: .destructive) {
                if let type = typeToDelete {
                    deleteType(type)
                }
                typeToDelete = nil
            }
            .textCase(nil)
        } message: {
            if let type = typeToDelete {
                Text("Are you sure you want to delete '\(type)'? This will remove the type from all items that use it.")
            }
        }
    }
    
    private func deleteType(_ type: String) {
        var updatedTypes = settingsManager.types
        updatedTypes.removeAll { $0 == type }
        
        Task {
            do {
                try await settingsManager.updateItemTypes(updatedTypes)
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
                try await settingsManager.updateItemTypes(updatedTypes)
                newType = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
