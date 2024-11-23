import SwiftUI

struct SettingsPanel: View {
    @StateObject private var settingsManager = PanelSettingsManager.shared
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(title: "Settings", showAddButton: false) {
                // No add action needed
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Panel Management")
                    .font(.headline)
                    .padding(.horizontal)
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                List {
                    ForEach(settingsManager.panels) { panelSetting in
                        HStack {
                            Image(systemName: panelSetting.panel.icon)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            Text(panelSetting.panel.title)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { panelSetting.visible },
                                set: { newValue in
                                    if let index = settingsManager.panels.firstIndex(where: { $0.id == panelSetting.id }) {
                                        settingsManager.panels[index].visible = newValue
                                        Task {
                                            do {
                                                try await settingsManager.updatePanelSettings()
                                            } catch {
                                                errorMessage = error.localizedDescription
                                            }
                                        }
                                    }
                                }
                            ))
                        }
                        .padding(.vertical, 8)
                    }
                    .onMove { from, to in
                        settingsManager.panels.move(fromOffsets: from, toOffset: to)
                        Task {
                            do {
                                try await settingsManager.updatePanelSettings()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
                .frame(minHeight: 300)
            }
            .padding(.top)
            
            Spacer()
        }
    }
}
