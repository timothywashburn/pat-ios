import SwiftUI

struct PersonDetailNotes: View {
    let isEditing: Bool
    @Binding var notes: [PersonNote]
    @Binding var newNote: String
    let addNote: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(isEditing ? .headline : .headline.weight(.medium))
                .foregroundColor(isEditing ? .primary : .secondary)
                .padding(.horizontal)
            
            if isEditing {
                ForEach(notes.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray)
                        Text(notes[index].content)
                        Spacer()
                        Button {
                            notes.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .onMove { from, to in
                    notes.move(fromOffsets: from, toOffset: to)
                }
                
                HStack {
                    TextField("Add note", text: $newNote)
                    Button(action: addNote) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(newNote.isEmpty)
                }
            } else {
                ForEach(notes, id: \.content) { note in
                    Text(note.content)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
}
