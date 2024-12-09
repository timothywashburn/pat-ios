import SwiftUI

class PanelController: ObservableObject {
    @Published var selectedPanel: Panel = .agenda
    @Published var panelSettings: [Panel: Bool] = [:]
    @Published var panelOrder: [Panel] = []
    @Published var isLoading = true
    
    func setSelectedPanel(_ panel: Panel) {
        selectedPanel = panel
    }
    
    init() {
        NSLog("[panel-controller] initializing")
        Task {
            await loadInitialSettings()
        }
        
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(settingsChanged),
                                            name: NSNotification.Name("PanelSettingsChanged"),
                                            object: nil)
    }
    
    private func loadInitialSettings() async {
        NSLog("[panel-controller] starting initial settings load")
        let settingsManager = PanelSettingsManager.shared
        
        do {
            try await settingsManager.loadPanelSettings()
            await MainActor.run {
                updateFromSettings()
                isLoading = false
                NSLog("[panel-controller] finished initial load")
            }
        } catch {
            NSLog("[panel-controller] failed to load initial settings: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    @objc private func settingsChanged() {
        NSLog("[panel-controller] received settings changed notification")
        updateFromSettings()
    }
    
    private func updateFromSettings() {
        let settings = PanelSettingsManager.shared.panels
        panelSettings = Dictionary(uniqueKeysWithValues: settings.map { ($0.panel, $0.visible) })
        panelOrder = settings.map(\.panel)
        
        if !panelSettings[selectedPanel, default: false] {
            if let firstVisible = panelOrder.first(where: { panelSettings[$0] == true }) {
                selectedPanel = firstVisible
                NSLog("[panel-controller] updated selected panel to: \(firstVisible)")
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
                    NSLog("[panel-controller] swiped to previous panel: \(visiblePanels[currentIndex - 1])")
                }
            } else if dragDistance < 0 && currentIndex < visiblePanels.count - 1 {
                withAnimation {
                    selectedPanel = visiblePanels[currentIndex + 1]
                    NSLog("[panel-controller] swiped to next panel: \(visiblePanels[currentIndex + 1])")
                }
            }
        }
    }
}
