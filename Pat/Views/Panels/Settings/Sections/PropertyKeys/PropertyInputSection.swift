import SwiftUI

struct PropertyInputSection: View {
    @Binding var newPropertyKey: String
    @Binding var newPropertyValue: String
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            PropertyKeyField(text: $newPropertyKey, placeholder: "Key")
            TextField("Value", text: $newPropertyValue)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
            .disabled(newPropertyKey.isEmpty || newPropertyValue.isEmpty)
        }
    }
}
