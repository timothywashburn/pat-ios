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
    
    init() {
        Task {
            await loadPanelSettings()
        }
    }
    
    func loadPanelSettings() async {
        guard let token = AuthState.shared.authToken else { return }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/user/config")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool,
                  let responseData = json["data"] as? [String: Any],
                  let userData = responseData["user"] as? [String: Any],
                  let iosApp = userData["iosApp"] as? [String: Any],
                  let panelSettings = iosApp["panels"] as? [[String: Any]],
                  success else {
                return
            }
            
            await MainActor.run {
                var panelVisibility: [String: Bool] = [:]
                for setting in panelSettings {
                    if let panelName = setting["panel"] as? String,
                       let visible = setting["visible"] as? Bool {
                        panelVisibility[panelName] = visible
                    }
                }
                
                self.panels = self.panels.map { setting in
                    let panelName = setting.panel.title.lowercased()
                    if let visible = panelVisibility[panelName] {
                        return PanelSetting(panel: setting.panel, visible: visible)
                    }
                    return setting
                }
                
                NotificationCenter.default.post(name: NSNotification.Name("PanelSettingsChanged"), object: nil)
            }
        } catch {
            print("Error loading panel settings: \(error)")
        }
    }
    
    func updatePanelSettings() async throws {
        guard let token = AuthState.shared.authToken else { return }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/user/config")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let panelConfig = panels.map { setting -> [String: Any] in
            return [
                "panel": setting.panel.title.lowercased(),
                "visible": setting.visible
            ]
        }
        
        let body: [String: Any] = [
            "iosApp": [
                "panels": panelConfig
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw NSError(domain: "", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              success else {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to update panel settings"])
        }
        
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("PanelSettingsChanged"), object: nil)
        }
    }
}
