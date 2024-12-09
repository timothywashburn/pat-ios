import SwiftUI

class PanelController: ObservableObject {
    @Published var selectedPanel: Panel = .agenda
    @Published private(set) var currentPanels: [Panel] = []
    private var panelSettings: [Panel: Bool] = [:]
    private var panelOrder: [Panel] = []
    
    init() {
        updateFromSettings(isInitialLoad: true)
        
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(settingsChanged),
                                            name: NSNotification.Name("PanelSettingsChanged"),
                                            object: nil)
    }
    
    func setSelectedPanel(_ panel: Panel) {
        if panelSettings[panel] == true {
            currentPanels = visiblePanels
            withAnimation {
                selectedPanel = panel
            }
        } else {
            currentPanels = [panel]
            DispatchQueue.main.async {
                withAnimation {
                    self.selectedPanel = panel
                }
            }
        }
    }
    
    @objc private func settingsChanged() {
        updateFromSettings(isInitialLoad: false)
    }
    
    private func updateFromSettings(isInitialLoad: Bool) {
        let settings = SettingsManager.shared.panels
        panelSettings = Dictionary(uniqueKeysWithValues: settings.map { ($0.panel, $0.visible) })
        panelOrder = settings.map(\.panel)
        currentPanels = visiblePanels
        
        if isInitialLoad {
            if let firstVisible = visiblePanels.first {
                selectedPanel = firstVisible
            }
        }
    }
    
    var visiblePanels: [Panel] {
        panelOrder.filter { panelSettings[$0] == true }
    }
}
