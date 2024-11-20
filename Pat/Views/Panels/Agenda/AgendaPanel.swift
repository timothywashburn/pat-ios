import SwiftUI

struct AgendaPanel: View {
    @StateObject private var agendaManager = AgendaManager.getInstance()
    @State private var showingCreateSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(title: "Agenda", showAddButton: true) {
                showingCreateSheet = true
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if isLoading && agendaManager.agendaItems.isEmpty {
                ProgressView()
                    .padding()
            } else {
                List {
                    ForEach(agendaManager.agendaItems) { item in
                        AgendaItemView(item: item)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    await loadItems()
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateAgendaItemView()
        }
        .task {
            await loadItems()
        }
    }
    
    private func loadItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await agendaManager.loadAgendaItems()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
