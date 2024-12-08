import Foundation
import SwiftUI

struct AgendaItem: Identifiable, Codable {
    let id: String
    let name: String
    let date: Date?
    let notes: String?
    let completed: Bool
    let urgent: Bool
    let category: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes, completed, urgent, category, type
        case date = "dueDate"
    }
}

class AgendaManager: ObservableObject {
    private static var instance: AgendaManager?
    @Published var agendaItems: [AgendaItem] = []
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
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
                completed: task["completed"] as? Bool ?? false,
                urgent: task["urgent"] as? Bool ?? false,
                category: task["category"] as? String,
                type: task["type"] as? String
            )
        }
        
        await MainActor.run {
            self.agendaItems = items
        }
    }
    
    func createAgendaItem(name: String, date: Date, notes: String? = nil, urgent: Bool = false, category: String? = nil, type: String? = nil) async throws -> AgendaItem {
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
            "dueDate": dateFormatter.string(from: date),
            "notes": notes ?? "",
            "urgent": urgent,
            "category": category as Any,
            "type": type as Any
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
            date: (taskData["dueDate"] as? String).flatMap { dateFormatter.date(from: $0) },
            notes: taskData["notes"] as? String,
            completed: taskData["completed"] as? Bool ?? false,
            urgent: taskData["urgent"] as? Bool ?? false,
            category: taskData["category"] as? String,
            type: taskData["type"] as? String
        )
        
        try await loadAgendaItems()
        
        return agendaItem
    }
    
    func setCompleted(_ id: String, completed: Bool) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/tasks/\(id)/complete")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["completed": completed]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard success else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: json["error"] as? String ?? "Unknown error"])
        }
        
        try await loadAgendaItems()
    }
    
    func updateAgendaItem(_ id: String, name: String?, date: Date?, notes: String?, urgent: Bool?, category: String?, type: String?) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/tasks/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        body["dueDate"] = date.map { dateFormatter.string(from: $0) }
        if let notes = notes { body["notes"] = notes }
        if let urgent = urgent { body["urgent"] = urgent }
        body["category"] = category
        body["type"] = type
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard success else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: json["error"] as? String ?? "Unknown error"])
        }
        
        try await loadAgendaItems()
    }
    
    func deleteAgendaItem(_ id: String) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/tasks/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard success else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: json["error"] as? String ?? "Unknown error"])
        }
        
        try await loadAgendaItems()
    }
}
