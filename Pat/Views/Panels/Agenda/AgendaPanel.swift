import SwiftUI

struct AgendaPanel: View {
    @StateObject private var agendaManager = AgendaManager.getInstance()
    @State private var showingCreateSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedItem: AgendaItem?
    @State private var showingDetail = false
    @Binding var showHamburgerMenu: Bool
    @State private var showCompleted = false
    
    private var filteredItems: [AgendaItem] {
        agendaManager.agendaItems
            .filter { showCompleted == $0.completed }
            .sorted { (item1, item2) in
                if item1.urgent != item2.urgent {
                    return item1.urgent
                }
                
                guard let date1 = item1.date, let date2 = item2.date else {
                    if item1.date == nil { return false }
                    if item2.date == nil { return true }
                    return false
                }
                return date1 < date2
            }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(
                title: "Agenda",
                showAddButton: true,
                onAddTapped: { showingCreateSheet = true },
                showFilterButton: true,
                isFilterActive: showCompleted,
                onFilterTapped: { withAnimation { showCompleted.toggle() } },
                showHamburgerMenu: $showHamburgerMenu
            )
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if isLoading && agendaManager.agendaItems.isEmpty {
                ProgressView()
                    .padding()
            } else if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(showCompleted ? "No completed items" : "No pending items")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredItems) { item in
                        AgendaItemView(item: item)
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
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
                    await loadItems()
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateAgendaItemView()
        }
        .overlay {
            if showingDetail, let item = selectedItem {
                AgendaDetailPanel(item: item, isPresented: $showingDetail)
                    .transition(.move(edge: .trailing))
            }
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
