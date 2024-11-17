import Foundation

enum PatConfig {
    static let apiURL: String = {
        #if DEBUG
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String else {
            fatalError("API_URL not found in Development.xcconfig")
        }
        return url
        #else
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String else {
            fatalError("API_URL not found in Production.xcconfig")
        }
        return url
        #endif
    }()
}
