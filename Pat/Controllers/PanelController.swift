import SwiftUI

class PanelController: ObservableObject {
    @Published var selectedPanel: Panel = .agenda
    
    func handlePanelSwipe(_ value: DragGesture.Value) {
        let threshold: CGFloat = 50
        let dragDistance = value.translation.width
        let dragVelocity = value.predictedEndLocation.x - value.location.x
        
        if abs(dragDistance) > threshold || abs(dragVelocity) > threshold {
            if dragDistance > 0 && selectedPanel != .agenda {
                withAnimation {
                    selectedPanel = Panel(rawValue: selectedPanel.rawValue - 1) ?? .agenda
                }
            } else if dragDistance < 0 && selectedPanel != .settings {
                withAnimation {
                    selectedPanel = Panel(rawValue: selectedPanel.rawValue + 1) ?? .settings
                }
            }
        }
    }
}
