import SwiftUI

struct HomeView: View {
    @StateObject private var panelController = PanelController()
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView(selection: $panelController.selectedPanel) {
                    ForEach(panelController.visiblePanels, id: \.self) { panel in
                        Group {
                            switch panel {
                            case .agenda:
                                AgendaPanel()
                            case .tasks:
                                TasksPanel()
                            case .inbox:
                                InboxPanel()
                            case .settings:
                                SettingsPanel()
                            }
                        }
                        .tag(panel)
                    }
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
                
                PanelNavigationBar(
                    selectedPanel: $panelController.selectedPanel,
                    visiblePanels: panelController.visiblePanels
                )
            }
        }
    }
}
