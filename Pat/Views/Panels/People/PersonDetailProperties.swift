import SwiftUI

struct PersonDetailProperties: View {
    let isEditing: Bool
    @Binding var properties: [PersonProperty]
    @Binding var newPropertyKey: String
    @Binding var newPropertyValue: String
    let addProperty: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Properties")
                .font(isEditing ? .headline : .headline.weight(.medium))
                .foregroundColor(isEditing ? .primary : .secondary)
                .padding(.horizontal)
            
            if isEditing {
                ForEach(properties.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text(properties[index].key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(properties[index].value)
                        }
                        Spacer()
                        Button {
                            properties.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .onMove { from, to in
                    properties.move(fromOffsets: from, toOffset: to)
                }
                
                PropertyInputSection(
                    newPropertyKey: $newPropertyKey,
                    newPropertyValue: $newPropertyValue,
                    onAdd: addProperty
                )
            } else {
                ForEach(properties, id: \.key) { property in
                    VStack(alignment: .leading) {
                        Text(property.key)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(property.value)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
}
