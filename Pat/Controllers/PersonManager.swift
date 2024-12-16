import Foundation

struct PersonProperty: Identifiable, Codable {
    let id: String
    let key: String
    let value: String
    
    init(id: String = UUID().uuidString, key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

struct PersonNote: Identifiable, Codable {
    let id: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String = UUID().uuidString, content: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Person: Identifiable, Codable {
    let id: String
    let name: String
    let properties: [PersonProperty]
    let notes: [PersonNote]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, properties, notes
    }
}

class PersonManager: ObservableObject {
    private static var instance: PersonManager?
    @Published var people: [Person] = []
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static func getInstance() -> PersonManager {
        if instance == nil {
            instance = PersonManager()
        }
        return instance!
    }
    
    func loadPeople() async throws {
        guard let token = AuthState.shared.authToken else {
            return
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/people")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let peopleData = responseData["people"] as? [[String: Any]] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        let people = peopleData.compactMap { person -> Person? in
            guard let id = person["id"] as? String,
                  let name = person["name"] as? String,
                  let properties = person["properties"] as? [[String: Any]],
                  let notes = person["notes"] as? [[String: Any]] else {
                return nil
            }
            
            let mappedProperties = properties.compactMap { property -> PersonProperty? in
                guard let key = property["key"] as? String,
                      let value = property["value"] as? String else {
                    return nil
                }
                return PersonProperty(key: key, value: value)
            }
            
            let mappedNotes = notes.compactMap { note -> PersonNote? in
                guard let content = note["content"] as? String,
                      let createdAtString = note["createdAt"] as? String,
                      let updatedAtString = note["updatedAt"] as? String,
                      let createdAt = dateFormatter.date(from: createdAtString),
                      let updatedAt = dateFormatter.date(from: updatedAtString) else {
                    return nil
                }
                return PersonNote(content: content, createdAt: createdAt, updatedAt: updatedAt)
            }
            
            return Person(id: id, name: name, properties: mappedProperties, notes: mappedNotes)
        }
        
        await MainActor.run {
            self.people = people
        }
    }
    
    func createPerson(name: String, properties: [PersonProperty] = [], notes: [PersonNote] = []) async throws -> Person {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/people")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "name": name,
            "properties": properties.map { [
                "key": $0.key,
                "value": $0.value
            ] },
            "notes": notes.map { [
                "content": $0.content
            ] }
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let personData = responseData["person"] as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        try await loadPeople()
        
        let person = people.first { $0.id == personData["id"] as? String }
        guard let person = person else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create person"])
        }
        
        return person
    }
    
    func updatePerson(_ id: String, name: String?, properties: [PersonProperty]?, notes: [PersonNote]?) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/people/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let properties = properties {
            body["properties"] = properties.map { [
                "key": $0.key,
                "value": $0.value
            ] }
        }
        if let notes = notes {
            body["notes"] = notes.map { [
                "content": $0.content
            ] }
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard success else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: json["error"] as? String ?? "Unknown error"])
        }
        
        try await loadPeople()
    }
    
    func deletePerson(_ id: String) async throws {
        guard let token = AuthState.shared.authToken else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(PatConfig.apiURL)/api/people/\(id)")!
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
        
        try await loadPeople()
    }
}
