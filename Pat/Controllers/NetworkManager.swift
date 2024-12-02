import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct NetworkRequest {
    let endpoint: String
    let method: HTTPMethod
    let body: [String: Any]?
    let token: String?
    
    init(endpoint: String, method: HTTPMethod, body: [String: Any]? = nil, token: String? = nil) {
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.token = token
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = PatConfig.apiURL
    
    private init() {}
    
    func perform(_ request: NetworkRequest) async throws -> [String: Any] {
        var urlRequest = URLRequest(url: URL(string: baseURL + request.endpoint)!)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = request.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = request.body {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              let responseData = json["data"] as? [String: Any] else {
            throw AuthError.invalidResponse
        }
        
        if !success {
            let errorMessage = (json["error"] as? String) ?? "Unknown error occurred"
            throw AuthError.serverError(errorMessage)
        }
        
        return responseData
    }
}
