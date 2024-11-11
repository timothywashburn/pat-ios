// Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var panelController = PanelController()
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView(selection: $panelController.selectedPanel) {
                    AgendaPanel()
                        .tag(Panel.agenda)
                    
                    TasksPanel()
                        .tag(Panel.tasks)
                    
                    InboxPanel()
                        .tag(Panel.inbox)
                    
                    SettingsPanel()
                        .tag(Panel.settings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            panelController.handlePanelSwipe(value)
                        }
                )
                
                PanelNavigationBar(selectedPanel: $panelController.selectedPanel)
            }
        }
    }
}
