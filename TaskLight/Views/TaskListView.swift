import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingAddTask = false
    @State private var searchText = ""
    @State private var showCompletedTasks = true
    @State private var sortOption: SortOption = .priority
    
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
    
    var filteredTasks: [TaskItem] {
        var tasks = viewModel.tasks
        
        // Ensure we're only working with non-deleted tasks
        tasks = tasks.filter { !$0.isDeleted }
        
        // Filter by search text
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by completion status
        if !showCompletedTasks {
            tasks = tasks.filter { !$0.isCompleted }
        }
        
        // Sort tasks
        switch sortOption {
        case .priority:
            tasks.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .dueDate:
            tasks.sort { 
                guard let date1 = $0.dueDate, let date2 = $1.dueDate else {
                    return $0.dueDate != nil
                }
                return date1 < date2
            }
        case .createdAt:
            // Assuming tasks are already sorted by createdAt from CloudKit
            break
        }
        
        return tasks
    }
    
    var body: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskRowView(task: task, viewModel: viewModel)
                    .swipeActions(edge: .leading) {
                        Button {
                            var updatedTask = task
                            updatedTask.isCompleted.toggle()
                            Task {
                                await viewModel.updateTask(updatedTask)
                            }
                        } label: {
                            Label(task.isCompleted ? "Mark Incomplete" : "Complete", 
                                  systemImage: task.isCompleted ? "xmark.circle" : "checkmark.circle")
                        }
                        .tint(task.isCompleted ? .gray : .green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.softDeleteTask(task)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
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
            
            ToolbarItem(placement: .navigationBarTrailing) {
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
    }
}

struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        NavigationLink(destination: TaskDetailView(task: task, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    
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
    
    private func isDueDateOverdue(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDate = calendar.startOfDay(for: date)
        return dueDate < today
    }
} 