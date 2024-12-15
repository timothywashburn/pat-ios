import SwiftUI

struct PeoplePanel: View {
    @StateObject private var personManager = PersonManager.getInstance()
    @State private var showingCreateSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPerson: Person?
    @State private var showingDetail = false
    @Binding var showHamburgerMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(
                title: "People",
                showAddButton: true,
                onAddTapped: { showingCreateSheet = true },
                showHamburgerMenu: $showHamburgerMenu
            )
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if isLoading && personManager.people.isEmpty {
                ProgressView()
                    .padding()
            } else if personManager.people.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No people added yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(personManager.people) { person in
                        PersonItemView(person: person)
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPerson = person
                                withAnimation(.spring()) {
                                    showingDetail = true
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    await loadPeople()
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreatePersonView()
        }
        .overlay {
            if showingDetail, let person = selectedPerson {
                PersonDetailPanel(person: person, isPresented: $showingDetail)
                    .transition(.move(edge: .trailing))
            }
        }
        .task {
            await loadPeople()
        }
    }
    
    private func loadPeople() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await personManager.loadPeople()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
