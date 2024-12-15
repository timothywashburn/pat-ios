import SwiftUI

struct SettingsPropertyKeysSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var errorMessage: String?
    @State private var newKey = ""
    @State private var keyToDelete: String? = nil
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        Section(header: Text("Property Keys")
            .textCase(.none)
            .font(.system(size: 16))) {
            ForEach(settingsManager.propertyKeys, id: \.self) { key in
                HStack {
                    Text(key)
                    Spacer()
                    if editMode?.wrappedValue.isEditing == true {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if editMode?.wrappedValue.isEditing == true {
                        keyToDelete = key
                    }
                }
            }
            .onMove { source, destination in
                var updatedKeys = settingsManager.propertyKeys
                updatedKeys.move(fromOffsets: source, toOffset: destination)
                
                Task {
                    do {
                        try await settingsManager.updatePropertyKeys(updatedKeys)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            
            if editMode?.wrappedValue.isEditing == true {
                AddNewItemRow(
                    placeholder: "New Property Key",
                    text: $newKey,
                    onAdd: addNewKey
                )
            }
        }
        .alert("Delete Property Key", isPresented: .init(
            get: { keyToDelete != nil },
            set: { if !$0 { keyToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                keyToDelete = nil
            }
            .textCase(nil)
            
            Button("Delete", role: .destructive) {
                if let key = keyToDelete {
                    deleteKey(key)
                }
                keyToDelete = nil
            }
            .textCase(nil)
        } message: {
            if let key = keyToDelete {
                Text("Are you sure you want to delete '\(key)'? This will not affect existing properties using this key.")
            }
        }
    }
    
    private func deleteKey(_ key: String) {
        var updatedKeys = settingsManager.propertyKeys
        updatedKeys.removeAll { $0 == key }
        
        Task {
            do {
                try await settingsManager.updatePropertyKeys(updatedKeys)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func addNewKey() {
        guard !newKey.isEmpty else { return }
        var updatedKeys = settingsManager.propertyKeys
        updatedKeys.append(newKey)
        
        Task {
            do {
                try await settingsManager.updatePropertyKeys(updatedKeys)
                newKey = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
