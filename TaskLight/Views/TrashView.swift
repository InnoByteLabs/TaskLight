import SwiftUI

struct TrashView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var expandedTasks: Set<String> = []  // Track expanded state by task ID
    
    var body: some View {
        List {
            ForEach(viewModel.deletedTasks) { task in
                TaskRowView(
                    task: task,
                    viewModel: viewModel,
                    isExpanded: .constant(false)  // Deleted tasks don't need expansion
                )
                .swipeActions(edge: .leading) {
                    Button {
                        Task {
                            await viewModel.restoreTask(task)
                        }
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.left")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.permanentlyDeleteTask(task)
                        }
                    } label: {
                        Label("Delete Forever", systemImage: "trash.fill")
                    }
                }
            }
        }
        .navigationTitle("Trash")
        .overlay {
            if viewModel.deletedTasks.isEmpty {
                ContentUnavailableView("Trash is Empty", 
                    systemImage: "trash",
                    description: Text("Items you delete will appear here for 30 days")
                )
            }
        }
    }
} 