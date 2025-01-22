import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task, viewModel: viewModel)
                    } label: {
                        TaskRowView(task: task, viewModel: viewModel)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteTask(task)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .task {
                await viewModel.checkCloudKitAvailability()
                await viewModel.fetchTasks()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button {
                    var updatedTask = task
                    updatedTask.isCompleted.toggle()
                    Task {
                        await viewModel.updateTask(updatedTask)
                    }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                }
                
                Text(task.title)
                    .strikethrough(task.isCompleted)
                
                Spacer()
                
                if task.priority != .medium {
                    Image(systemName: task.priority == .high ? "exclamationmark.2" : "minus")
                        .foregroundColor(task.priority == .high ? .red : .gray)
                }
            }
            
            if let notes = task.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let dueDate = task.dueDate {
                Text(dueDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    private var backgroundColor: Color {
        switch task.priority {
        case .high:
            return Color.red.opacity(0.15)
        case .medium:
            return Color.yellow.opacity(0.15)
        case .low:
            return Color.clear
        }
    }
} 