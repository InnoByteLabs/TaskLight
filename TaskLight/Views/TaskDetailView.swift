import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var task: TaskItem
    
    // State for editing
    @State private var title: String
    @State private var notes: String
    @State private var priority: TaskItem.Priority
    @State private var dueDate: Date?
    @State private var showingDueDatePicker = false
    
    init(task: TaskItem, viewModel: TaskViewModel) {
        self.viewModel = viewModel
        _task = State(initialValue: task)
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes ?? "")
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                TextField("Notes", text: $notes)
            }
            
            Section {
                Picker("Priority", selection: $priority) {
                    ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
            }
            
            Section {
                Toggle("Set Due Date", isOn: .init(
                    get: { dueDate != nil },
                    set: { if !$0 { dueDate = nil } }
                ))
                
                if dueDate != nil || showingDueDatePicker {
                    DatePicker("Due Date",
                              selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                              ),
                              displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
        }
        .navigationTitle("Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(title.isEmpty)
            }
        }
    }
    
    private func save() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.notes = notes.isEmpty ? nil : notes
        updatedTask.priority = priority
        updatedTask.dueDate = dueDate
        updatedTask.modifiedAt = Date()
        
        Task {
            await viewModel.updateTask(updatedTask)
            dismiss()
        }
    }
} 