import SwiftUI

struct TaskCategoriesSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var errorMessage: String?
    @State private var newCategory = ""
    
    var body: some View {
        Section("Task Categories") {
            ForEach(settingsManager.categories, id: \.self) { category in
                SettingsItemRow(
                    title: category,
                    onDelete: { deleteCategory(category) }
                )
            }
            
            AddNewItemRow(
                placeholder: "New Category",
                text: $newCategory,
                onAdd: addNewCategory
            )
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
