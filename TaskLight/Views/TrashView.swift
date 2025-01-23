import SwiftUI

struct TrashView: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.deletedTasks) { task in
                TaskRowView(task: task, viewModel: viewModel)
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