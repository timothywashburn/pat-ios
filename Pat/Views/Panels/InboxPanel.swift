import SwiftUI

struct InboxPanel: View {
    @Binding var showHamburgerMenu: Bool
    @StateObject private var thoughtManager = ThoughtManager.getInstance()
    @State private var newThought = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedThought: Thought?
    @State private var showingActionSheet = false
    @State private var showingCreateAgendaSheet = false
    @State private var editingThought: Thought?
    @State private var editedContent = ""
    @State private var showingWIPAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(
                title: "Inbox",
                showAddButton: true,
                onAddTapped: {
                    showingCreateAgendaSheet = true
                },
                showHamburgerMenu: $showHamburgerMenu
            )
            
            VStack(spacing: 16) {
                HStack {
                    TextField("Add a thought...", text: $newThought)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button {
                        Task {
                            guard !newThought.isEmpty else { return }
                            isLoading = true
                            do {
                                try await thoughtManager.createThought(newThought)
                                newThought = ""
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(newThought.isEmpty || isLoading)
                }
                .padding(.horizontal)
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(thoughtManager.thoughts) { thought in
                            ThoughtView(
                                thought: thought,
                                isEditing: editingThought?.id == thought.id,
                                editedContent: $editedContent,
                                onCommitEdit: {
                                    Task {
                                        do {
                                            try await thoughtManager.updateThought(thought.id, content: editedContent)
                                            editingThought = nil
                                        } catch {
                                            errorMessage = error.localizedDescription
                                        }
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if editingThought?.id == thought.id {
                                    Task {
                                        do {
                                            try await thoughtManager.updateThought(thought.id, content: editedContent)
                                            editingThought = nil
                                        } catch {
                                            errorMessage = error.localizedDescription
                                        }
                                    }
                                } else if editingThought == nil {
                                    selectedThought = thought
                                    showingActionSheet = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    try? await thoughtManager.loadThoughts()
                }
            }
            .padding(.top)
        }
        .confirmationDialog("Choose Action", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Move to Agenda") {
                showingCreateAgendaSheet = true
            }
            
            Button("Move to Tasks (WIP)") {
                showingWIPAlert = true
            }
            
            Button("Edit") {
                if let thought = selectedThought {
                    editingThought = thought
                    editedContent = thought.content
                }
            }
            
            Button("Delete", role: .destructive) {
                if let thought = selectedThought {
                    Task {
                        do {
                            try await thoughtManager.deleteThought(thought.id)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingCreateAgendaSheet) {
            if let thought = selectedThought {
                CreateAgendaItemView(initialName: thought.content) { didCreate in
                    if didCreate {
                        Task {
                            do {
                                try await thoughtManager.deleteThought(thought.id)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            } else {
                CreateAgendaItemView()
            }
        }
        .alert("In Development", isPresented: $showingWIPAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This feature has not been implemented yet.")
        }
        .task {
            do {
                try await thoughtManager.loadThoughts()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct ThoughtView: View {
    let thought: Thought
    let isEditing: Bool
    @Binding var editedContent: String
    let onCommitEdit: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        if isEditing {
            TextField("", text: $editedContent)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
                .focused($isFocused)
                .onAppear {
                    editedContent = thought.content
                    isFocused = true
                }
                .onChange(of: isFocused) { newValue in
                    if !newValue {
                        onCommitEdit()
                    }
                }
                .onSubmit {
                    isFocused = false
                }
        } else {
            Text(thought.content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}
