import SwiftUI

struct AgendaItemView: View {
    let item: AgendaItem
    @StateObject private var agendaManager = AgendaManager.getInstance()
    @State private var isLoading = false
    
    private var formattedDate: String {
        guard let date = item.date else { return "" }
        
        let dateFormatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            dateFormatter.dateFormat = "'Today at' h:mm a"
        }
        else if Calendar.current.isDateInTomorrow(date) {
            dateFormatter.dateFormat = "'Tomorrow at' h:mm a"
        }
        else if let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day,
                daysUntil < 7 && daysUntil >= 0 {
            dateFormatter.dateFormat = "EEEE 'at' h:mm a"
        }
        else {
            dateFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        }
        
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    isLoading = true
                    do {
                        try await agendaManager.setCompleted(item.id, completed: !item.completed)
                    } catch {
                        print("failed to update completion status: \(error.localizedDescription)")
                    }
                    isLoading = false
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(item.completed ? .green : .gray)
                }
            }
            .disabled(isLoading)
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.headline)
                
                if !formattedDate.isEmpty {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
