import SwiftUI

struct CreatePersonView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var personManager = PersonManager.getInstance()
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var name = ""
    @State private var properties: [PersonProperty] = []
    @State private var notes: [PersonNote] = []
    @State private var newPropertyKey = ""
    @State private var newPropertyValue = ""
    @State private var newNote = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Properties")) {
                    ForEach(properties.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(properties[index].key)
                                    .font(.caption)
                                Text(properties[index].value)
                            }
                            Spacer()
                            Button(action: {
                                properties.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onMove { from, to in
                        properties.move(fromOffsets: from, toOffset: to)
                        updatePropertyOrders()
                    }
                    
                    PropertyInputSection(
                        newPropertyKey: $newPropertyKey,
                        newPropertyValue: $newPropertyValue,
                        onAdd: addProperty
                    )
                }
                
                Section(header: Text("Notes")) {
                    ForEach(notes.indices, id: \.self) { index in
                        HStack {
                            Text(notes[index].content)
                            Spacer()
                            Button(action: {
                                notes.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onMove { from, to in
                        notes.move(fromOffsets: from, toOffset: to)
                        updateNoteOrders()
                    }
                    
                    HStack {
                        TextField("Add note", text: $newNote)
                        Button(action: addNote) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newNote.isEmpty)
                    }
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Person")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(action: createPerson) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Add")
                    }
                }
                .disabled(name.isEmpty || isLoading)
            )
        }
    }
    
    private func updatePropertyOrders() {
        for (index, _) in properties.enumerated() {
            properties[index] = PersonProperty(
                key: properties[index].key,
                value: properties[index].value
            )
        }
    }
    
    private func updateNoteOrders() {
        for (index, _) in notes.enumerated() {
            notes[index] = PersonNote(
                content: notes[index].content,
                createdAt: notes[index].createdAt,
                updatedAt: notes[index].updatedAt
            )
        }
    }
    
    private func addProperty() {
        guard !newPropertyKey.isEmpty && !newPropertyValue.isEmpty else { return }
        properties.append(PersonProperty(
            key: newPropertyKey,
            value: newPropertyValue
        ))
        newPropertyKey = ""
        newPropertyValue = ""
    }
    
    private func addNote() {
        guard !newNote.isEmpty else { return }
        let now = Date()
        notes.append(PersonNote(
            content: newNote,
            createdAt: now,
            updatedAt: now
        ))
        newNote = ""
    }
    
    private func createPerson() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await personManager.createPerson(
                    name: name,
                    properties: properties,
                    notes: notes
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
