import SwiftUI

struct TaskCategoriesSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var errorMessage: String?
    @State private var newCategory = ""
    @State private var categoryToDelete: String? = nil
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        Section(header: Text("Task Categories")
            .textCase(.none)
            .font(.system(size: 16))) {
            ForEach(settingsManager.categories, id: \.self) { category in
                HStack {
                    Text(category)
                    Spacer()
                    if editMode?.wrappedValue.isEditing == true {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if editMode?.wrappedValue.isEditing == true {
                        categoryToDelete = category
                    }
                }
            }
            .onMove { source, destination in
                var updatedCategories = settingsManager.categories
                updatedCategories.move(fromOffsets: source, toOffset: destination)
                
                Task {
                    do {
                        try await settingsManager.updateTaskCategories(updatedCategories)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            
            if editMode?.wrappedValue.isEditing == true {
                AddNewItemRow(
                    placeholder: "New Category",
                    text: $newCategory,
                    onAdd: addNewCategory
                )
            }
        }
        .alert("Delete Category", isPresented: .init(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
            .textCase(nil)
            
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
                categoryToDelete = nil
            }
            .textCase(nil)
        } message: {
            if let category = categoryToDelete {
                Text("Are you sure you want to delete '\(category)'? This will remove the category from all tasks that use it.")
            }
        }
    }
    
    private func deleteCategory(_ category: String) {
        var updatedCategories = settingsManager.categories
        updatedCategories.removeAll { $0 == category }
        
        Task {
            do {
                try await settingsManager.updateTaskCategories(updatedCategories)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func addNewCategory() {
        guard !newCategory.isEmpty else { return }
        var updatedCategories = settingsManager.categories
        updatedCategories.append(newCategory)
        
        Task {
            do {
                try await settingsManager.updateTaskCategories(updatedCategories)
                newCategory = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
