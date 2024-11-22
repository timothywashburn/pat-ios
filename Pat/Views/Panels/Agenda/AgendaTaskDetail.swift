import SwiftUI

struct AgendaTaskDetail: ViewModifier {
    @Binding var selectedTask: AgendaItem?
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented, let task = selectedTask {
                    AgendaDetailPanel(item: task, isPresented: $isPresented)
                        .transition(.move(edge: .trailing))
                }
            }
    }
}

extension View {
    func agendaTaskDetail(selectedTask: Binding<AgendaItem?>, isPresented: Binding<Bool>) -> some View {
        modifier(AgendaTaskDetail(selectedTask: selectedTask, isPresented: isPresented))
    }
}
