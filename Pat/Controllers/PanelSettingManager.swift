import SwiftUI

class PanelSettingsManager: ObservableObject {
    static let shared = PanelSettingsManager()
    @Published var panels: [PanelSetting] = Panel.allCases.map { panel in
        PanelSetting(panel: panel, visible: true)
    }
    
    struct PanelSetting: Identifiable, Equatable {
        let id = UUID()
        var panel: Panel
        var visible: Bool
        
        static func == (lhs: PanelSetting, rhs: PanelSetting) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    func updatePanelSettings() async throws {
        guard let token = AuthState.shared.authToken else { return }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/user/config")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Convert panels to the format expected by the API
        let panelConfig = panels.map { setting -> [String: Any] in
            return [
                "panel": setting.panel.title.lowercased(),
                "visible": setting.visible
            ]
        }
        
        // Send the config in the format expected by the schema
        let body: [String: Any] = [
            "iosApp": [
                "panels": panelConfig
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              success else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = json["error"] as? String {
                throw NSError(domain: "", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to update panel settings"])
        }
    }
}
