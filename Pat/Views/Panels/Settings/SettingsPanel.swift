import SwiftUI

struct SettingsPanel: View {
    @StateObject private var settingsManager = PanelSettingsManager.shared
    @State private var errorMessage: String?
    @Binding var showHamburgerMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeader(
                title: "Settings",
                showAddButton: false,
                onAddTapped: { },
                showHamburgerMenu: $showHamburgerMenu
            )
            
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
                    Section(header: Text("Visible Panels")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(nil)) {
                        ForEach(settingsManager.panels.filter { $0.visible }) { panelSetting in
                            PanelRow(
                                panelSetting: panelSetting,
                                onToggle: {
                                    if let index = settingsManager.panels.firstIndex(where: { $0.id == panelSetting.id }) {
                                        // First, mark as invisible
                                        settingsManager.panels[index].visible = false
                                        
                                        // Then reorganize the entire array
                                        let visiblePanels = settingsManager.panels.filter { $0.visible }
                                        let hiddenPanels = settingsManager.panels.filter { !$0.visible }
                                        settingsManager.panels = visiblePanels + hiddenPanels
                                        
                                        Task {
                                            do {
                                                try await settingsManager.updatePanelSettings()
                                            } catch {
                                                errorMessage = error.localizedDescription
                                            }
                                        }
                                    }
                                }
                            )
                        }
                        .onMove { source, destination in
                            var visiblePanels = settingsManager.panels.filter { $0.visible }
                            visiblePanels.move(fromOffsets: source, toOffset: destination)
                            
                            let hiddenPanels = settingsManager.panels.filter { !$0.visible }
                            settingsManager.panels = visiblePanels + hiddenPanels
                            
                            Task {
                                do {
                                    try await settingsManager.updatePanelSettings()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Hidden Panels")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(nil)) {
                        ForEach(settingsManager.panels.filter { !$0.visible }) { panelSetting in
                            PanelRow(
                                panelSetting: panelSetting,
                                onToggle: {
                                    if let index = settingsManager.panels.firstIndex(where: { $0.id == panelSetting.id }) {
                                        settingsManager.panels[index].visible = true
                                        
                                        let visiblePanels = settingsManager.panels.filter { $0.visible }
                                        let hiddenPanels = settingsManager.panels.filter { !$0.visible }
                                        settingsManager.panels = visiblePanels + hiddenPanels
                                        
                                        Task {
                                            do {
                                                try await settingsManager.updatePanelSettings()
                                            } catch {
                                                errorMessage = error.localizedDescription
                                            }
                                        }
                                    }
                                }
                            )
                        }
                        .onMove { source, destination in
                            var hiddenPanels = settingsManager.panels.filter { !$0.visible }
                            hiddenPanels.move(fromOffsets: source, toOffset: destination)
                            
                            let visiblePanels = settingsManager.panels.filter { $0.visible }
                            settingsManager.panels = visiblePanels + hiddenPanels
                            
                            Task {
                                do {
                                    try await settingsManager.updatePanelSettings()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, .constant(.active))
                .frame(minHeight: 300)
            }
            .padding(.top)
            
            Spacer()
        }
    }
}

struct PanelRow: View {
    let panelSetting: PanelSettingsManager.PanelSetting
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: panelSetting.panel.icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(panelSetting.panel.title)
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: panelSetting.visible ? "eye" : "eye.slash")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
