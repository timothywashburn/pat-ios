import SwiftUI

enum Panel: Int, CaseIterable {
    case agenda, tasks, inbox, people, settings
    
    var title: String {
        switch self {
        case .agenda: return "Agenda"
        case .tasks: return "Tasks"
        case .inbox: return "Inbox"
        case .people: return "People"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .agenda: return "calendar"
        case .tasks: return "checklist"
        case .inbox: return "tray"
        case .people: return "person"
        case .settings: return "gear"
        }
    }
}
