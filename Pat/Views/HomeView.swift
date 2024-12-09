import SwiftUI

struct HomeView: View {
    @StateObject private var panelController = PanelController()
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showHamburgerMenu = false
    @State private var menuShadowOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
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
            
            ZStack {
                if showHamburgerMenu {
                    Color.black
                        .opacity(menuShadowOpacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showHamburgerMenu = false
                                menuShadowOpacity = 0
                            }
                        }
                        .zIndex(1)
                }
                
                GeometryReader { geometry in
                    HamburgerMenuPanel(
                        panelController: panelController,
                        isPresented: $showHamburgerMenu,
                        selectedPanel: $panelController.selectedPanel
                    )
                    .frame(width: min(300, geometry.size.width * 0.75))
                    .offset(x: showHamburgerMenu ? 0 : -min(300, geometry.size.width * 0.75))
                    .animation(.easeOut(duration: 0.25), value: showHamburgerMenu)
                }
                .zIndex(2)
            }
        }
        .onChange(of: showHamburgerMenu) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.25)) {
                menuShadowOpacity = newValue ? 0.3 : 0
            }
        }
    }
}
