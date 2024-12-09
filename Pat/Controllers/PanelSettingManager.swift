import SwiftUI

class PanelSettingsManager: ObservableObject {
    static let shared = PanelSettingsManager()
    @Published var panels: [PanelSetting] = []
    @Published var isLoaded = false
    
    struct PanelSetting: Identifiable, Equatable {
        let id = UUID()
        var panel: Panel
        var visible: Bool
        
        static func == (lhs: PanelSetting, rhs: PanelSetting) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    init() {
        NSLog("[panel-settings] initializing manager")
    }
    
    func loadPanelSettings() async throws {
        NSLog("[panel-settings] starting to load panel settings")
        guard let token = AuthState.shared.authToken else {
            NSLog("[panel-settings] no auth token available")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No auth token"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/account/config")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        NSLog("[panel-settings] fetching config from server")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            NSLog("[panel-settings] invalid response type")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        NSLog("[panel-settings] received response with status: \(httpResponse.statusCode)")
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              let responseData = json["data"] as? [String: Any],
              let userData = responseData["user"] as? [String: Any],
              let iosApp = userData["iosApp"] as? [String: Any],
              let panelSettings = iosApp["panels"] as? [[String: Any]],
              success else {
            NSLog("[panel-settings] failed to parse response data")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])
        }
        
        NSLog("[panel-settings] processing panel settings")
        await MainActor.run {
            let panelMap = Dictionary(uniqueKeysWithValues: Panel.allCases.map { ($0.title.lowercased(), $0) })
            
            var newPanels: [PanelSetting] = []
            for setting in panelSettings {
                if let panelName = setting["panel"] as? String,
                   let visible = setting["visible"] as? Bool,
                   let panel = panelMap[panelName] {
                    newPanels.append(PanelSetting(panel: panel, visible: visible))
                }
            }
            
            let configuredPanelNames = Set(newPanels.map { $0.panel.title.lowercased() })
            for panel in Panel.allCases {
                let panelName = panel.title.lowercased()
                if !configuredPanelNames.contains(panelName) {
                    newPanels.append(PanelSetting(panel: panel, visible: true))
                }
            }
            
            self.panels = newPanels
            self.isLoaded = true
            NSLog("[panel-settings] finished loading settings with \(newPanels.count) panels")
            NotificationCenter.default.post(name: NSNotification.Name("PanelSettingsChanged"), object: nil)
        }
    }
    
    func updatePanelSettings() async throws {
        NSLog("[panel-settings] starting panel settings update")
        guard let token = AuthState.shared.authToken else {
            NSLog("[panel-settings] no auth token available for update")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No auth token"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/account/config")!
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
        
        NSLog("[panel-settings] sending update to server")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            NSLog("[panel-settings] server returned error status: \(httpResponse.statusCode)")
            throw NSError(domain: "", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              success else {
            NSLog("[panel-settings] failed to parse update response")
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to update panel settings"])
        }
        
        NSLog("[panel-settings] successfully updated panel settings")
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("PanelSettingsChanged"), object: nil)
        }
    }
}
