import Foundation

class ThoughtManager: ObservableObject {
    private static var instance: ThoughtManager?
    @Published var thoughts: [Thought] = []
    
    static func getInstance() -> ThoughtManager {
        if instance == nil {
            instance = ThoughtManager()
        }
        return instance!
    }
    
    func loadThoughts() async throws {
        guard let token = AuthState.shared.authToken else {
            return
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/thoughts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let thoughtsData = responseData["thoughts"] as? [[String: Any]] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        let thoughts = thoughtsData.compactMap { thought -> Thought? in
            guard let id = thought["id"] as? String,
                  let content = thought["content"] as? String else {
                return nil
            }
            
            return Thought(id: id, content: content)
        }
        
        await MainActor.run {
            self.thoughts = thoughts
        }
    }
    
    func createThought(_ content: String) async throws -> Thought {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/thoughts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let thoughtData = responseData["thought"] as? [String: Any],
              let id = thoughtData["id"] as? String,
              let content = thoughtData["content"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        let thought = Thought(id: id, content: content)
        try await loadThoughts()
        return thought
    }
    
    func updateThought(_ id: String, content: String) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/thoughts/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        try await loadThoughts()
    }
    
    func deleteThought(_ id: String) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/thoughts/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        try await loadThoughts()
    }
}
