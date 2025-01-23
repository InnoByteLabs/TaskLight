import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var task: TaskItem
    @State private var editedTitle: String
    @State private var editedNotes: String
    @State private var editedPriority: TaskItem.Priority
    @State private var editedDueDate: Date
    @State private var hasDueDate: Bool
    
    init(task: TaskItem, viewModel: TaskViewModel) {
        self.viewModel = viewModel
        _task = State(initialValue: task)
        _editedTitle = State(initialValue: task.title)
        _editedNotes = State(initialValue: task.notes ?? "")
        _editedPriority = State(initialValue: task.priority)
        _editedDueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: $editedTitle)
                    .font(.headline)
            }
            
            Section("Priority") {
                Picker("Priority", selection: $editedPriority) {
                    ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                        Label(priority.title, systemImage: priorityIcon(for: priority))
                            .foregroundColor(priorityColor(for: priority))
                            .tag(priority)
                    }
                }
            }
            
            Section("Due Date") {
                Toggle("Has Due Date", isOn: $hasDueDate)
                
                if hasDueDate {
                    DatePicker("Due Date", selection: $editedDueDate, displayedComponents: [.date])
                }
            }
            
            Section("Notes") {
                TextEditor(text: $editedNotes)
                    .frame(minHeight: 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                    dismiss()
                }
            }
        }
        .onChange(of: editedTitle) { _ in saveChanges() }
        .onChange(of: editedPriority) { _ in saveChanges() }
        .onChange(of: hasDueDate) { _ in saveChanges() }
        .onChange(of: editedDueDate) { _ in 
            if hasDueDate {
                saveChanges()
            }
        }
    }
    
    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        updatedTask.priority = editedPriority
        updatedTask.dueDate = hasDueDate ? editedDueDate : nil
        
        Task {
            print("Saving task with notes: \(updatedTask.notes ?? "nil")")
            await viewModel.updateTask(updatedTask)
            task = updatedTask
        }
    }
    
    private func priorityIcon(for priority: TaskItem.Priority) -> String {
        switch priority {
        case .high: return "exclamationmark.2"
        case .medium: return "exclamationmark"
        case .low: return "minus"
        }
    }
    
    private func priorityColor(for priority: TaskItem.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
    
    private func isDueDateOverdue(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDate = calendar.startOfDay(for: date)
        return dueDate < today
    }
} 