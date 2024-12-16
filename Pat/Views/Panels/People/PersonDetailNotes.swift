import SwiftUI

struct PersonDetailNotes: View {
    let isEditing: Bool
    @Binding var notes: [PersonNote]
    @Binding var newNote: String
    let addNote: () -> Void
    @Environment(\.editMode) private var editMode
    @State private var editingNote: PersonNote?
    @State private var editedContent: String = ""
    
    var body: some View {
        Section {
            ForEach(notes) { note in
                HStack {
                    if editingNote?.id == note.id {
                        TextField("Note", text: $editedContent, onCommit: {
                            saveNoteEdit(note: note)
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(note.content)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                if editMode?.wrappedValue == .active {
                                    editingNote = note
                                    editedContent = note.content
                                }
                            }
                    }
                    
                    if editMode?.wrappedValue == .active {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .onTapGesture {
                                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                                    notes.remove(at: index)
                                }
                            }
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onMove { source, destination in
                if editMode?.wrappedValue == .active {
                    notes.move(fromOffsets: source, toOffset: destination)
                }
            }
            
            if editMode?.wrappedValue == .active {
                NewNoteInput(
                    newNote: $newNote,
                    onAdd: addNote
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .editingDidEnd)) { _ in
            editingNote = nil
        }
    }
    
    private func saveNoteEdit(note: PersonNote) {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                let updatedNote = PersonNote(
                    id: note.id,
                    content: editedContent,
                    createdAt: note.createdAt,
                    updatedAt: Date()
                )
                notes[index] = updatedNote
            }
            editingNote = nil
        }
}

struct NewNoteInput: View {
    @Binding var newNote: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Note", text: $newNote)
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newNote.isEmpty)
            }
        }
        .padding(.vertical, 8)
    }
}
