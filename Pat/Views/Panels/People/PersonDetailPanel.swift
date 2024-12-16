import SwiftUI

struct PersonDetailPanel: View {
    let person: Person
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = 0
    @StateObject private var personManager = PersonManager.getInstance()
    @StateObject private var settingsManager = SettingsManager.shared
    
    @State private var isEditing = false
    @State private var editMode: EditMode = .inactive
    @State private var name: String
    @State private var properties: [PersonProperty]
    @State private var notes: [PersonNote]
    @State private var newPropertyKey = ""
    @State private var newPropertyValue = ""
    @State private var newNote = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false
    
    init(person: Person, isPresented: Binding<Bool>) {
        self.person = person
        self._isPresented = isPresented
        self._name = State(initialValue: person.name)
        self._properties = State(initialValue: person.properties)
        self._notes = State(initialValue: person.notes)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                navigationBar
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                List {
                    nameSection
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    
                    if !properties.isEmpty || isEditing {
                        Section {
                            PersonDetailProperties(
                                properties: $properties,
                                newPropertyKey: $newPropertyKey,
                                newPropertyValue: $newPropertyValue,
                                addProperty: addProperty
                            )
                            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                        }
                    }
                    
                    if !notes.isEmpty || isEditing {
                        Section {
                            PersonDetailNotes(
                                isEditing: isEditing,
                                notes: $notes,
                                newNote: $newNote,
                                addNote: addNote
                            )
                            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                        }
                    }
                    
                    if isEditing {
                        Section {
                            deleteButton
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .disabled(!isEditing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .offset(x: offset)
        }
        .alert("Delete Person", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePerson()
                }
            }
        } message: {
            Text("Are you sure you want to delete this person? This action cannot be undone.")
        }
    }
    
    private var navigationBar: some View {
        HStack(spacing: 16) {
            Button {
                if isEditing {
                    name = person.name
                    properties = person.properties
                    notes = person.notes
                    newPropertyKey = ""
                    newPropertyValue = ""
                    newNote = ""
                    isEditing = false
                    errorMessage = nil
                    NotificationCenter.default.post(name: .editingDidEnd, object: nil)
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            } label: {
                Image(systemName: isEditing ? "xmark" : "chevron.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            if isEditing {
                if isLoading {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task {
                            await saveChanges()
                            // Notify child views that editing has ended
                            NotificationCenter.default.post(name: .editingDidEnd, object: nil)
                        }
                    }
                    .disabled(name.isEmpty)
                }
            } else {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .padding()
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading) {
            if isEditing {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Person Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(name)
                    .font(.title)
            }
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Person")
            }
            .foregroundColor(.red)
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
    
    private func saveChanges() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await personManager.updatePerson(
                person.id,
                name: name,
                properties: properties,
                notes: notes
            )
            await MainActor.run {
                isEditing = false
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func deletePerson() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await personManager.deletePerson(person.id)
            await MainActor.run {
                isPresented = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

extension Notification.Name {
    static let editingDidEnd = Notification.Name("editingDidEnd")
}

#Preview {
    PersonDetailPanel(
        person: Person(
            id: "123",
            name: "Test Person",
            properties: [
                PersonProperty(id: "1", key: "email", value: "test@example.com"),
                PersonProperty(id: "2", key: "phone", value: "123-456-7890"),
                PersonProperty(id: "3", key: "address", value: "123 Test St")
            ],
            notes: [
                PersonNote(content: "Test note", createdAt: Date(), updatedAt: Date())
            ]
        ),
        isPresented: .constant(true)
    )
}
