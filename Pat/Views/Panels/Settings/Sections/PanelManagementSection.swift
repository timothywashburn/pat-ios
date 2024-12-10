import SwiftUI

struct PanelManagementSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var errorMessage: String?
    
    var body: some View {
        Section {
            Text("Panel Management")
                .font(.headline)
                .foregroundColor(.primary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .textCase(nil)
        }
        
        Section(header:
            Text("Visible Panels")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(nil)
        ) {
            ForEach(settingsManager.panels.filter { $0.visible }, id: \.id) { panelSetting in
                PanelRow(
                    panelSetting: panelSetting,
                    onToggle: {
                        togglePanel(panelSetting, visible: false)
                    }
                )
            }
            .onMove { source, destination in
                movePanels(source: source, destination: destination, visible: true)
            }
        }
        
        Section(header:
            Text("Hidden Panels")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(nil)
        ) {
            ForEach(settingsManager.panels.filter { !$0.visible }, id: \.id) { panelSetting in
                PanelRow(
                    panelSetting: panelSetting,
                    onToggle: {
                        togglePanel(panelSetting, visible: true)
                    }
                )
            }
            .onMove { source, destination in
                movePanels(source: source, destination: destination, visible: false)
            }
        }
    }
    
    private func togglePanel(_ panelSetting: SettingsManager.PanelSetting, visible: Bool) {
        if let index = settingsManager.panels.firstIndex(where: { $0.id == panelSetting.id }) {
            settingsManager.panels[index].visible = visible
            reorderPanels()
            
            Task {
                do {
                    try await settingsManager.updatePanelSettings()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func movePanels(source: IndexSet, destination: Int, visible: Bool) {
        var filteredPanels = settingsManager.panels.filter { $0.visible == visible }
        filteredPanels.move(fromOffsets: source, toOffset: destination)
        reorderPanels(visiblePanels: visible ? filteredPanels : nil,
                      hiddenPanels: !visible ? filteredPanels : nil)
        
        Task {
            do {
                try await settingsManager.updatePanelSettings()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func reorderPanels(visiblePanels: [SettingsManager.PanelSetting]? = nil,
                             hiddenPanels: [SettingsManager.PanelSetting]? = nil) {
        let visible = visiblePanels ?? settingsManager.panels.filter { $0.visible }
        let hidden = hiddenPanels ?? settingsManager.panels.filter { !$0.visible }
        settingsManager.panels = visible + hidden
    }
}
