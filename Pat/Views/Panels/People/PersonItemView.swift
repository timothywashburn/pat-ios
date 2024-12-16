import SwiftUI

struct PersonItemView: View {
    let person: Person
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(person.name)
                .font(.headline)
            
            if !person.properties.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(person.properties, id: \.key) { property in
                            VStack(alignment: .leading) {
                                Text(property.key)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(property.value)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
