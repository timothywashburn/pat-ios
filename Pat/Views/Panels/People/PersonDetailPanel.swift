import SwiftUI

struct PersonDetailPanel: View {
    let person: Person
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = 0
    @StateObject private var personManager = PersonManager.getInstance()
    @StateObject private var settingsManager = SettingsManager.shared
    
    @State private var isEditing = false
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        nameSection
                        
                        if !properties.isEmpty || isEditing {
                            PersonDetailProperties(
                                isEditing: isEditing,
                                properties: $properties,
                                newPropertyKey: $newPropertyKey,
                                newPropertyValue: $newPropertyValue,
                                addProperty: addProperty
                            )
                        }
                        
                        if !notes.isEmpty || isEditing {
                            PersonDetailNotes(
                                isEditing: isEditing,
                                notes: $notes,
                                newNote: $newNote,
                                addNote: addNote
                            )
                        }
                        
                        if isEditing {
                            deleteButton
                        }
                    }
                    .padding(.vertical)
                }
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
                    isEditing = false
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
        .padding(.horizontal)
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
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
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
