import SwiftUI

struct PanelRow: View {
    let panelSetting: SettingsManager.PanelSetting
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: panelSetting.panel.icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(panelSetting.panel.title)
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: panelSetting.visible ? "eye" : "eye.slash")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}

struct SettingsItemRow: View {
    let title: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

struct AddNewItemRow: View {
    let placeholder: String
    @Binding var text: String
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}
