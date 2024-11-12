import SwiftUI
import UIKit

class KeyboardPreloader {
    static let shared = KeyboardPreloader()
    private var hasPreloaded = false
    
    private init() {}
    
    func preloadKeyboard() {
        guard !hasPreloaded else { return }
        
        DispatchQueue.main.async {
            self.withoutAutolayoutLogs {
                let lagFreeField = UITextField()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.addSubview(lagFreeField)
                    lagFreeField.becomeFirstResponder()
                    lagFreeField.resignFirstResponder()
                    lagFreeField.removeFromSuperview()
                }
                self.hasPreloaded = true
            }
        }
    }
    
    func withoutAutolayoutLogs(_ closure: () -> Void) {
        let wasEnabled = UserDefaults.standard.bool(forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        closure()
        UserDefaults.standard.set(wasEnabled, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
}

struct KeyboardPreloadModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onAppear {
            KeyboardPreloader.shared.preloadKeyboard()
        }
    }
}

extension View {
    func preloadKeyboard() -> some View {
        modifier(KeyboardPreloadModifier())
    }
}
