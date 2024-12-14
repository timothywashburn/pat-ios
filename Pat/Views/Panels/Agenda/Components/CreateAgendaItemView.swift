import SwiftUI

struct CreateAgendaItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var agendaManager = AgendaManager.getInstance()
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var name: String
    @State private var date = Date()
    @State private var notes = ""
    @State private var urgent = false
    @State private var category: String?
    @State private var type: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didCreate = false
    
    init(initialName: String = "") {
        _name = State(initialValue: initialName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Toggle(isOn: $urgent) {
                        Text("Urgent")
                            .foregroundColor(.red)
                    }
                    
                    Picker("Category", selection: $category) {
                        Text("None")
                            .tag(Optional<String>.none)
                        ForEach(settingsManager.categories, id: \.self) { category in
                            Text(category)
                                .tag(Optional(category))
                        }
                    }
                    
                    Picker("Type", selection: $type) {
                        Text("None")
                            .tag(Optional<String>.none)
                        ForEach(settingsManager.types, id: \.self) { type in
                            Text(type)
                                .tag(Optional(type))
                        }
                    }
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
                    notes: notes.isEmpty ? nil : notes,
                    urgent: urgent,
                    category: category,
                    type: type
                )
                await MainActor.run {
                    didCreate = true
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
