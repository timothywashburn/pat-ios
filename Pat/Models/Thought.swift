import Foundation

struct Thought: Identifiable, Codable {
    let id: String
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content
    }
}
