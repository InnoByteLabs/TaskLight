import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @Binding var isEditing: Bool
    @Binding var showDeleted: Bool
    
    var body: some View {
        List {
            Section("Tasks") {
                ForEach(items.filter { !$0.isDeleted && $0.parentTask == nil }) { item in
                    TaskRow(item: item, isEditing: $isEditing)
                        .swipeActions {
                            Button(role: .destructive) {
                                softDeleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            
            if showDeleted {
                Section("Deleted") {
                    ForEach(items.filter { $0.isDeleted }) { item in
                        TaskRow(item: item, isEditing: $isEditing)
                            .swipeActions {
                                Button {
                                    restoreItem(item)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.left")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
    }
    
    private func softDeleteItem(_ item: Item) {
        withAnimation {
            item.isDeleted = true
            item.deletedDate = .now
            try? modelContext.save()
        }
    }
    
    private func restoreItem(_ item: Item) {
        withAnimation {
            item.isDeleted = false
            item.deletedDate = nil
            try? modelContext.save()
        }
    }
} 