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
                ScrollView {
                    RefreshControl(coordinateSpace: .named("refresh")) {
                        await loadItems()
                    }
                    
                    VStack(spacing: 20) {
                        ForEach(agendaManager.agendaItems) { item in
                            AgendaItemView(item: item)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .coordinateSpace(name: "refresh")
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

struct RefreshControl: View {
    var coordinateSpace: CoordinateSpace
    var onRefresh: () async -> Void
    
    @State private var refreshing = false
    @State private var threshold: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: coordinateSpace).midY > threshold && !refreshing {
                Spacer()
                    .onAppear {
                        refreshing = true
                        Task {
                            await onRefresh()
                            refreshing = false
                        }
                    }
            } else if geometry.frame(in: coordinateSpace).midY <= threshold {
                Spacer()
                    .onAppear {
                        refreshing = false
                    }
            }
            
            HStack {
                Spacer()
                if refreshing {
                    ProgressView()
                }
                Spacer()
            }
            .offset(y: min(geometry.frame(in: coordinateSpace).midY - threshold, 0))
        }
        .padding(.top, -threshold)
    }
}
