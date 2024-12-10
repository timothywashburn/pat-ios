import SwiftUI

struct PanelManagementSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var errorMessage: String?
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        Section(header: Text("Panel Arrangement")
                .textCase(.none)
                .font(.system(size: 16))) {
            Text("Visible Panels")
                .foregroundColor(.secondary)
            ForEach(settingsManager.panels.filter { $0.visible }, id: \.id) { panelSetting in
                HStack {
                    Image(systemName: panelSetting.panel.icon)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text(panelSetting.panel.title)
                    
                    Spacer()
                    
                    if editMode?.wrappedValue.isEditing == true {
                        Button(action: {
                            togglePanel(panelSetting, visible: false)
                        }) {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onMove { source, destination in
                movePanels(source: source, destination: destination, visible: true)
            }
        }
        
        Section {
            Text("Hidden Panels")
                .foregroundColor(.secondary)
            ForEach(settingsManager.panels.filter { !$0.visible }, id: \.id) { panelSetting in
                HStack {
                    Image(systemName: panelSetting.panel.icon)
                        .foregroundColor(.gray)
                        .frame(width: 30)
                    
                    Text(panelSetting.panel.title)
                    
                    Spacer()
                    
                    if editMode?.wrappedValue.isEditing == true {
                        Button(action: {
                            togglePanel(panelSetting, visible: true)
                        }) {
                            Image(systemName: "eye")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
