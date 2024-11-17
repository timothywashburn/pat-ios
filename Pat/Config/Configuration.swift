import Foundation

enum PatConfig {
    static let apiURL: String = {
        #if DEBUG
        guard let configURL = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String else {
            fatalError("API_URL not found in Development.xcconfig")
        }
        return "https://" + configURL
        #else
        guard let configURL = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String else {
            fatalError("API_URL not found in Production.xcconfig")
        }
        return "https://" + configURL
        #endif
    }()
}
