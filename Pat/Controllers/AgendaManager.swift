import Foundation
import SwiftUI

struct AgendaItem: Identifiable, Codable {
    let id: String
    let name: String
    let date: Date?
    let notes: String?
    let completed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes, completed
        case date = "dueDate"
    }
}

class AgendaManager: ObservableObject {
    private static var instance: AgendaManager?
    @Published var agendaItems: [AgendaItem] = []
    
    static func getInstance() -> AgendaManager {
        if instance == nil {
            instance = AgendaManager()
        }
        return instance!
    }
    
    func loadAgendaItems() async throws {
        guard let token = AuthState.shared.authToken else {
            return
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              let responseData = json["data"] as? [String: Any],
              let taskData = responseData["tasks"] as? [[String: Any]] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        let items = taskData.compactMap { task -> AgendaItem? in
            guard let id = task["_id"] as? String,
                  let name = task["name"] as? String else {
                return nil
            }
            
            let date = task["dueDate"].flatMap { dateString in
                dateString as? String
            }.flatMap { dateString in
                dateFormatter.date(from: dateString)
            }
            
            return AgendaItem(
                id: id,
                name: name,
                date: date,
                notes: task["notes"] as? String,
                completed: task["completed"] as? Bool ?? false
            )
        }
        
        await MainActor.run {
            self.agendaItems = items
        }
    }
    
    func createAgendaItem(name: String, date: Date, notes: String? = nil) async throws -> AgendaItem {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "name": name,
            "dueDate": ISO8601DateFormatter().string(from: date),
            "notes": notes ?? "",
            "userId": AuthState.shared.userId ?? ""
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              let responseData = json["data"] as? [String: Any],
              let taskData = responseData["task"] as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard success else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: json["error"] as? String ?? "Unknown error"])
        }
        
        let agendaItem = AgendaItem(
            id: taskData["id"] as? String ?? "",
            name: taskData["name"] as? String ?? "",
            date: ISO8601DateFormatter().date(from: taskData["dueDate"] as? String ?? "") ?? Date(),
            notes: taskData["notes"] as? String,
            completed: taskData["completed"] as? Bool ?? false
        )
        
        try await loadAgendaItems()
        
        return agendaItem
    }
}
