import SwiftUI

struct AgendaDetailPanel: View {
    let item: AgendaItem
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = 0
    @StateObject private var agendaManager = AgendaManager.getInstance()
    @StateObject private var settingsManager = SettingsManager.shared
    
    @State private var name: String
    @State private var date: Date?
    @State private var notes: String
    @State private var urgent: Bool
    @State private var category: String?
    @State private var type: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false
    
    init(item: AgendaItem, isPresented: Binding<Bool>) {
        self.item = item
        self._isPresented = isPresented
        self._name = State(initialValue: item.name)
        self._date = State(initialValue: item.date)
        self._notes = State(initialValue: item.notes ?? "")
        self._urgent = State(initialValue: item.urgent)
        self._category = State(initialValue: item.category)
        self._type = State(initialValue: item.type)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
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
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Event Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Due Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if let date = date {
                                    DatePicker("", selection: .init(
                                        get: { date },
                                        set: { self.date = $0 }
                                    ), displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    
                                    Button {
                                        self.date = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Button {
                                        self.date = Date()
                                    } label: {
                                        Text("Add date")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        
                        Toggle(isOn: $urgent) {
                            Text("Urgent")
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Category")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Category", selection: $category) {
                                Text("None")
                                    .tag(Optional<String>.none)
                                ForEach(settingsManager.categories, id: \.self) { category in
                                    Text(category)
                                        .tag(Optional(category))
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Type", selection: $type) {
                                Text("None")
                                    .tag(Optional<String>.none)
                                ForEach(settingsManager.types, id: \.self) { type in
                                    Text(type)
                                        .tag(Optional(type))
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Task")
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .offset(x: offset)
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteTask()
                }
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private func saveChanges() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await agendaManager.updateAgendaItem(
                item.id,
                name: name,
                date: date,
                notes: notes,
                urgent: urgent,
                category: category,
                type: type
            )
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
    
    private func deleteTask() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await agendaManager.deleteAgendaItem(item.id)
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
