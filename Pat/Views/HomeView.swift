import SwiftUI

struct HomeView: View {
    @StateObject private var panelController = PanelController()
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showHamburgerMenu = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    TabView(selection: $panelController.selectedPanel) {
                        ForEach(panelController.panelOrder, id: \.self) { panel in
                            Group {
                                switch panel {
                                case .agenda:
                                    AgendaPanel(showHamburgerMenu: $showHamburgerMenu)
                                case .tasks:
                                    TasksPanel(showHamburgerMenu: $showHamburgerMenu)
                                case .inbox:
                                    InboxPanel(showHamburgerMenu: $showHamburgerMenu)
                                case .settings:
                                    SettingsPanel(showHamburgerMenu: $showHamburgerMenu)
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
                
                if showHamburgerMenu {
                    HamburgerMenuPanel(
                        panelController: panelController,
                        isPresented: $showHamburgerMenu,
                        selectedPanel: $panelController.selectedPanel
                    )
                    .transition(.move(edge: .leading))
                }
            }
        }
    }
}
