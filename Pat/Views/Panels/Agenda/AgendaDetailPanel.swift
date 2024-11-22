import SwiftUI

struct AgendaDetailPanel: View {
    let item: AgendaItem
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Text(item.name)
                        .font(.title)
                        .bold()
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .offset(x: offset)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture()
                .onChanged { gesture in
                    offset = max(0, gesture.translation.width)
                }
                .onEnded { gesture in
                    if gesture.translation.width > 100 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = 0
                        }
                    }
                }
        )
        .ignoresSafeArea()
    }
}
