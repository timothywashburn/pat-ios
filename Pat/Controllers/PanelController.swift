import SwiftUI

class PanelController: ObservableObject {
    @Published var selectedPanel: Panel = .agenda
    @Published var panelSettings: [Panel: Bool] = [:]
    @Published var panelOrder: [Panel] = []
    
    init() {
        updateFromSettings(isInitialLoad: true)
        
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(settingsChanged),
                                            name: NSNotification.Name("PanelSettingsChanged"),
                                            object: nil)
    }
    
    func setSelectedPanel(_ panel: Panel) {
        selectedPanel = panel
    }
    
    @objc private func settingsChanged() {
        updateFromSettings(isInitialLoad: false)
    }
    
    private func updateFromSettings(isInitialLoad: Bool) {
        let settings = SettingsManager.shared.panels
        panelSettings = Dictionary(uniqueKeysWithValues: settings.map { ($0.panel, $0.visible) })
        panelOrder = settings.map(\.panel)
        
        if isInitialLoad {
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
