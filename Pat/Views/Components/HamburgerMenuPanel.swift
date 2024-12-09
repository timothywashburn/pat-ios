import SwiftUI

struct HamburgerMenuPanel: View {
    @StateObject private var settingsManager = PanelSettingsManager.shared
    @ObservedObject var panelController: PanelController
    @Binding var isPresented: Bool
    @Binding var selectedPanel: Panel
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Panels")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    Section(header: Text("Visible Panels")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(nil)) {
                        ForEach(settingsManager.panels.filter { $0.visible }, id: \.id) { panelSetting in
                            Button(action: {
                                panelController.setSelectedPanel(panelSetting.panel)
                                withAnimation(.easeOut(duration: 0.25)) {
                                    isPresented = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: panelSetting.panel.icon)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    Text(panelSetting.panel.title)
                                    Spacer()
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    
                    Section(header: Text("Hidden Panels")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(nil)) {
                        ForEach(settingsManager.panels.filter { !$0.visible }, id: \.id) { panelSetting in
                            Button(action: {
                                panelController.setSelectedPanel(panelSetting.panel)
                                withAnimation(.easeOut(duration: 0.25)) {
                                    isPresented = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: panelSetting.panel.icon)
                                        .foregroundColor(.gray)
                                        .frame(width: 30)
                                    Text(panelSetting.panel.title)
                                    Spacer()
                                }
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding(.top)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemBackground))
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    dragOffset = min(0, gesture.translation.width)
                }
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = 0
                            isPresented = false
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}
