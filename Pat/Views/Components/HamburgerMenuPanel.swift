import SwiftUI

struct HamburgerMenuPanel: View {
    @StateObject private var settingsManager = PanelSettingsManager.shared
    @ObservedObject var panelController: PanelController
    @Binding var isPresented: Bool
    @Binding var selectedPanel: Panel
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    NSLog("[menu] background tapped")
                    withAnimation {
                        isPresented = false
                    }
                }
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
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
                                            NSLog("[menu] visible panel selected: \(panelSetting.panel.title)")
                                            panelController.setSelectedPanel(panelSetting.panel)
                                            withAnimation {
                                                NSLog("[menu] closing menu after visible panel selection")
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
                                            NSLog("[menu] hidden panel selected: \(panelSetting.panel.title)")
                                            panelController.setSelectedPanel(panelSetting.panel)
                                            withAnimation {
                                                NSLog("[menu] closing menu after hidden panel selection")
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
                    .frame(width: min(300, geometry.size.width * 0.75))
                    .background(Color(.systemBackground))
                    .offset(x: offset)
                    
                    Spacer()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        NSLog("[menu] drag changed: \(gesture.translation)")
                        offset = min(0, gesture.translation.width)
                    }
                    .onEnded { gesture in
                        NSLog("[menu] drag ended: \(gesture.translation)")
                        if gesture.translation.width < -50 {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.2)) {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}
