import SwiftUI

struct AgendaItemDetail: ViewModifier {
    @Binding var selectedItem: AgendaItem?
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented, let item = selectedItem {
                    AgendaDetailPanel(item: item, isPresented: $isPresented)
                        .transition(.move(edge: .trailing))
                }
            }
    }
}

extension View {
    func agendaItemDetail(selectedItem: Binding<AgendaItem?>, isPresented: Binding<Bool>) -> some View {
        modifier(AgendaItemDetail(selectedItem: selectedItem, isPresented: isPresented))
    }
}
