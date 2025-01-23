import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingAddTask = false
    @State private var searchText = ""
    @State private var showCompletedTasks = true
    @State private var sortOption: SortOption = .priority
    @State private var isExpanded = true
    
    enum SortOption: String, CaseIterable {
        case priority = "Priority"
        case dueDate = "Due Date"
        case createdAt = "Created"
        
        var systemImage: String {
            switch self {
            case .priority: return "exclamationmark.circle"
            case .dueDate: return "calendar"
            case .createdAt: return "clock"
            }
        }
    }
    
    // Simplified filtering and sorting
    var filteredTasks: [TaskItem] {
        let deletedFiltered = filterDeleted(viewModel.tasks)
        let searchFiltered = filterBySearch(deletedFiltered)
        let completionFiltered = filterByCompletion(searchFiltered)
        return sortTasks(completionFiltered)
    }
    
    // Root tasks only
    var rootTasks: [TaskItem] {
        filteredTasks.filter { $0.parentTaskID == nil }
    }
    
    var body: some View {
        List {
            ForEach(rootTasks) { parentTask in
                // Parent task
                TaskRowView(task: parentTask, viewModel: viewModel, isExpanded: $isExpanded)
                    .swipeActions(edge: .leading) {
                        Button {
                            Task {
                                await viewModel.toggleTaskCompletion(parentTask)
                            }
                        } label: {
                            Label(parentTask.isCompleted ? "Mark Incomplete" : "Complete", 
                                  systemImage: parentTask.isCompleted ? "xmark.circle" : "checkmark.circle")
                        }
                        .tint(parentTask.isCompleted ? .gray : .green)
                        
                        Button {
                            viewModel.showingAddSubtask = true
                            viewModel.selectedParentTask = parentTask
                        } label: {
                            Label("Add Subtask", systemImage: "plus.circle")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.softDeleteTask(parentTask)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                
                // Subtasks
                if parentTask.hasSubtasks {
                    ForEach(viewModel.subtasksFor(parentTask)) { subtask in
                        TaskRowView(task: subtask, viewModel: viewModel, isExpanded: .constant(false))
                            .padding(.leading, 20)  // Back to original padding
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task {
                                        await viewModel.toggleTaskCompletion(subtask)
                                    }
                                } label: {
                                    Label(subtask.isCompleted ? "Mark Incomplete" : "Complete", 
                                          systemImage: subtask.isCompleted ? "xmark.circle" : "checkmark.circle")
                                }
                                .tint(subtask.isCompleted ? .gray : .green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.softDeleteTask(subtask)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search tasks")
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                        }
                    }
                    
                    Toggle("Show Completed", isOn: $showCompletedTasks)
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: TrashView(viewModel: viewModel)) {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddSubtask) {
            if let parentTask = viewModel.selectedParentTask {
                AddSubtaskView(viewModel: viewModel, parentTask: parentTask)
            }
        }
    }
    
    // Helper functions
    private func filterDeleted(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter { !$0.isDeleted }
    }
    
    private func filterBySearch(_ tasks: [TaskItem]) -> [TaskItem] {
        if searchText.isEmpty { return tasks }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func filterByCompletion(_ tasks: [TaskItem]) -> [TaskItem] {
        if showCompletedTasks { return tasks }
        return tasks.filter { !$0.isCompleted }
    }
    
    private func sortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        var sortedTasks = tasks
        switch sortOption {
        case .priority:
            sortedTasks.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .dueDate:
            sortedTasks.sort { 
                guard let date1 = $0.dueDate, let date2 = $1.dueDate else {
                    return $0.dueDate != nil
                }
                return date1 < date2
            }
        case .createdAt:
            break // Already sorted by CloudKit
        }
        return sortedTasks
    }
}

struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskViewModel
    @Binding var isExpanded: Bool
    
    var body: some View {
        NavigationLink(destination: TaskDetailView(task: task, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if task.hasSubtasks {
                        Button {
                            isExpanded.toggle()
                        } label: {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(task.title)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                        .foregroundColor(.primary)  // Ensure text is visible in navigation link
                    
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
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                
                if let dueDate = task.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(dueDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(isDueDateOverdue(dueDate) ? .red : .secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .listRowInsets(EdgeInsets())
        .listRowBackground(priorityColor.opacity(0.2))
    }
    
    private var priorityColor: Color {
        if task.isCompleted {
            return .gray
        }
        switch task.priority {
        case .high:
            return .red
        case .medium:
            return Color(red: 1.0, green: 0.8, blue: 0.0)  // A more vibrant yellow
        case .low:
            return .clear
        }
    }
    
    private func isDueDateOverdue(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDate = calendar.startOfDay(for: date)
        return dueDate < today
    }
}