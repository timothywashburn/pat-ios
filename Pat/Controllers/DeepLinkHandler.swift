import SwiftUI

enum DeepLinkHandler {
    static func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("[deeplink] invalid url components")
            return
        }
        
        print("[deeplink] handling url: \(url)")
        
//        switch components.path {
//        case "/redirect":
//            print("[deeplink] handling redirect")
//            
//        default:
//            print("[deeplink] unhandled path: \(components.path)")
//        }
    }
}
