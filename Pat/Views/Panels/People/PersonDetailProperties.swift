import SwiftUI

struct PersonDetailProperties: View {
    @Binding var properties: [PersonProperty]
    @Binding var newPropertyKey: String
    @Binding var newPropertyValue: String
    let addProperty: () -> Void
    @Environment(\.editMode) private var editMode
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var editingProperty: PersonProperty?
    @State private var editedValue: String = ""
    
    var body: some View {
        Section {
            ForEach(properties) { property in
                HStack {
                    if editingProperty?.id == property.id {
                        VStack(alignment: .leading) {
                            Text(property.key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Value", text: $editedValue, onCommit: {
                                savePropertyEdit(property: property)
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text(property.key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(property.value)
                        }
                        .onTapGesture {
                            if editMode?.wrappedValue == .active {
                                editingProperty = property
                                editedValue = property.value
                            }
                        }
                    }
                    
                    if editMode?.wrappedValue == .active {
                        Spacer()
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .onTapGesture {
                                if let index = properties.firstIndex(where: { $0.id == property.id }) {
                                    properties.remove(at: index)
                                }
                            }
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onMove { source, destination in
                if editMode?.wrappedValue == .active {
                    properties.move(fromOffsets: source, toOffset: destination)
                }
            }
            
            if editMode?.wrappedValue == .active {
                NewPropertyInput(
                    newPropertyKey: $newPropertyKey,
                    newPropertyValue: $newPropertyValue,
                    propertyKeys: settingsManager.propertyKeys,
                    onAdd: addProperty
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .editingDidEnd)) { _ in
            editingProperty = nil
        }
    }
    
    private func savePropertyEdit(property: PersonProperty) {
        if let index = properties.firstIndex(where: { $0.id == property.id }) {
            let updatedProperty = PersonProperty(
                id: property.id,
                key: property.key,
                value: editedValue
            )
            properties[index] = updatedProperty
        }
        editingProperty = nil
    }
}

struct NewPropertyInput: View {
    @Binding var newPropertyKey: String
    @Binding var newPropertyValue: String
    let propertyKeys: [String]
    let onAdd: () -> Void
    
    @State private var selectedKeyType: KeyType = .predefined
    @State private var selectedPredefinedKey = ""
    @State private var customKey = ""
    
    enum KeyType {
        case predefined
        case custom
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Picker("Key Type", selection: $selectedKeyType) {
                Text("Predefined").tag(KeyType.predefined)
                Text("Custom").tag(KeyType.custom)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 4)
            
            HStack {
                if selectedKeyType == .predefined {
                    Menu {
                        ForEach(propertyKeys, id: \.self) { key in
                            Button(key) {
                                selectedPredefinedKey = key
                                newPropertyKey = key
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedPredefinedKey.isEmpty ? "Select Key" : selectedPredefinedKey)
                                .foregroundColor(selectedPredefinedKey.isEmpty ? .gray : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                } else {
                    TextField("Key", text: $customKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: customKey) { newValue in
                            newPropertyKey = newValue
                        }
                }
                
                TextField("Value", text: $newPropertyValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    onAdd()
                    // Reset fields after adding
                    selectedPredefinedKey = ""
                    customKey = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(
                    (selectedKeyType == .predefined && selectedPredefinedKey.isEmpty) ||
                    (selectedKeyType == .custom && customKey.isEmpty) ||
                    newPropertyValue.isEmpty
                )
            }
        }
        .padding(.vertical, 8)
    }
}
