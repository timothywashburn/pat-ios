import SwiftUI

struct CreateAgendaItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var agendaManager = AgendaManager.getInstance()
    @State private var name = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Agenda Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(action: createItem) {
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
    
    private func createItem() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await agendaManager.createAgendaItem(
                    name: name,
                    date: date,
                    notes: notes.isEmpty ? nil : notes
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
