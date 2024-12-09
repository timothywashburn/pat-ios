import SwiftUI

class PanelController: ObservableObject {
    @Published var selectedPanel: Panel = .agenda
    @Published var panelSettings: [Panel: Bool] = [:]
    @Published var panelOrder: [Panel] = []
    
    func setSelectedPanel(_ panel: Panel) {
        selectedPanel = panel
    }
    
    init() {
        updateFromSettings()
        
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(settingsChanged),
                                            name: NSNotification.Name("PanelSettingsChanged"),
                                            object: nil)
    }
    
    @objc private func settingsChanged() {
        updateFromSettings()
    }
    
    private func updateFromSettings() {
        let settings = PanelSettingsManager.shared.panels
        panelSettings = Dictionary(uniqueKeysWithValues: settings.map { ($0.panel, $0.visible) })
        panelOrder = settings.map(\.panel)
        
        // Update selected panel only if not already set to a visible panel
        if !panelSettings[selectedPanel, default: false] {
            if let firstVisible = panelOrder.first(where: { panelSettings[$0] == true }) {
                selectedPanel = firstVisible
            }
        }
    }
    
    var visiblePanels: [Panel] {
        panelOrder.filter { panelSettings[$0] == true }
    }
    
    func handlePanelSwipe(_ value: DragGesture.Value) {
        let threshold: CGFloat = 50
        let dragDistance = value.translation.width
        let dragVelocity = value.predictedEndLocation.x - value.location.x
        
        if abs(dragDistance) > threshold || abs(dragVelocity) > threshold {
            guard let currentIndex = visiblePanels.firstIndex(of: selectedPanel) else { return }
            
            if dragDistance > 0 && currentIndex > 0 {
                withAnimation {
                    selectedPanel = visiblePanels[currentIndex - 1]
                }
            } else if dragDistance < 0 && currentIndex < visiblePanels.count - 1 {
                withAnimation {
                    selectedPanel = visiblePanels[currentIndex + 1]
                }
            }
        }
    }
}
