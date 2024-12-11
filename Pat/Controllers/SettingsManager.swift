import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    @Published var panels: [PanelSetting] = []
    @Published var isLoaded = false
    @Published var categories: [String] = ["School", "Work", "Personal"]
    @Published var types: [String] = ["Assignment", "Project"]
    @Published private(set) var config: [String: Any] = [:]
    
    struct PanelSetting: Identifiable, Equatable {
        let id = UUID()
        var panel: Panel
        var visible: Bool
        
        static func == (lhs: PanelSetting, rhs: PanelSetting) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    private init() {}
    
    func loadConfig() async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No auth token"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/account/config")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              let responseData = json["data"] as? [String: Any],
              let userData = responseData["user"] as? [String: Any],
              success else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])
        }
        
        await MainActor.run {
            self.config = userData
            updateFromConfig()
            self.isLoaded = true
        }
    }
    
    func updateConfig(_ newConfig: [String: Any]) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No auth token"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/account/config")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: newConfig)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw NSError(domain: "", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              let responseData = json["data"] as? [String: Any],
              let userData = responseData["user"] as? [String: Any],
              success else {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to update configuration"])
        }
        
        await MainActor.run {
            if var existingIosApp = self.config["iosApp"] as? [String: Any],
               let newIosApp = newConfig["iosApp"] as? [String: Any] {
                for (key, value) in newIosApp {
                    existingIosApp[key] = value
                }
                var updatedConfig = self.config
                updatedConfig["iosApp"] = existingIosApp
                self.config = updatedConfig
            } else {
                self.config = userData
            }
            
            updateFromConfig()
            NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        }
    }
    
    private func updateFromConfig() {
        if let iosApp = config["iosApp"] as? [String: Any] {
            if let itemCategories = iosApp["itemCategories"] as? [String] {
                self.categories = itemCategories
            }
            if let itemTypes = iosApp["itemTypes"] as? [String] {
                self.types = itemTypes
            }
            if let panelSettings = iosApp["panels"] as? [[String: Any]] {
                updatePanelsFromSettings(panelSettings)
            }
        }
    }
    
    private func updatePanelsFromSettings(_ panelSettings: [[String: Any]]) {
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
        NotificationCenter.default.post(name: NSNotification.Name("PanelSettingsChanged"), object: nil)
    }
    
    func updatePanelSettings() async throws {
        let newConfig: [String: Any] = [
            "iosApp": [
                "panels": panels.map { setting -> [String: Any] in
                    return [
                        "panel": setting.panel.title.lowercased(),
                        "visible": setting.visible
                    ]
                }
            ]
        ]
        
        try await updateConfig(newConfig)
    }

    func updateItemCategories(_ categories: [String]) async throws {
        let newConfig: [String: Any] = [
            "iosApp": [
                "itemCategories": categories
            ]
        ]
        
        try await updateConfig(newConfig)
    }

    func updateItemTypes(_ types: [String]) async throws {
        let newConfig: [String: Any] = [
            "iosApp": [
                "itemTypes": types
            ]
        ]
        
        try await updateConfig(newConfig)
    }
}
