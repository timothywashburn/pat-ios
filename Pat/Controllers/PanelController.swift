import SwiftUI

class PanelController: ObservableObject {
    static let shared = PanelController()
    
    @Published var selectedPanel: Panel = .agenda
    @Published private(set) var currentPanels: [Panel] = []
    private var panelSettings: [Panel: Bool] = [:]
    private var panelOrder: [Panel] = []
    
    private init() {
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
        print("updating from settings with initialLoad \(isInitialLoad)")
        print("selecting \(selectedPanel)")
        
        let oldSettingsVisible = panelSettings[.settings] == true
        
        let settings = SettingsManager.shared.panels
        panelSettings = Dictionary(uniqueKeysWithValues: settings.map { ($0.panel, $0.visible) })
        panelOrder = settings.map(\.panel)
        
        let newSettingsVisible = panelSettings[.settings] == true
        
        if isInitialLoad {
            print("visible panels: \(visiblePanels)")
            print("panelOrder: \(panelOrder)")
            currentPanels = visiblePanels
            if let firstVisible = visiblePanels.first {
                selectedPanel = firstVisible
            }
        } else if selectedPanel == .settings {
            if oldSettingsVisible && !newSettingsVisible {
                // Case: visible -> hidden
                // Act like hamburger menu selection of a hidden panel
                currentPanels = [.settings]
            } else if !oldSettingsVisible && newSettingsVisible {
                // Case: hidden -> visible
                // Update to show with other visible panels
                currentPanels = visiblePanels
            } else if oldSettingsVisible && newSettingsVisible {
                // Case: visible -> visible
                // Update current panels normally
                currentPanels = visiblePanels
            }
            // Case: hidden -> hidden is handled by doing nothing
        } else {
            currentPanels = visiblePanels
        }
    }
    
    var visiblePanels: [Panel] {
        panelOrder.filter { panelSettings[$0] == true }
    }
}
