import SwiftUI

struct PropertyKeyField: View {
    @Binding var text: String
    let placeholder: String
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingSuggestions = false
    @FocusState private var isFocused: Bool
    
    private var filteredSuggestions: [String] {
        guard !text.isEmpty else { return [] }
        return settingsManager.propertyKeys.filter { $0.lowercased().contains(text.lowercased()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .onChange(of: text) { _, _ in
                    showingSuggestions = !text.isEmpty && isFocused
                }
                .onChange(of: isFocused) { _, newValue in
                    showingSuggestions = newValue && !text.isEmpty
                }
            
            if showingSuggestions && !filteredSuggestions.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredSuggestions, id: \.self) { suggestion in
                            Text(suggestion)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    text = suggestion
                                    showingSuggestions = false
                                    isFocused = false
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
    }
}
