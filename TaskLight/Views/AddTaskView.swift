import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskItem.Priority = .low
    @State private var dueDate: Date = Date().addingTimeInterval(24 * 60 * 60) // Tomorrow
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Notes", text: $notes)
                
                Picker("Priority", selection: $priority) {
                    ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let task = TaskItem(
                            title: title,
                            notes: notes.isEmpty ? nil : notes,
                            priority: priority,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        
                        // Dismiss immediately for better UX
                        dismiss()
                        
                        // Then save the task
                        Task {
                            await viewModel.addTask(task)
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddTaskView(viewModel: TaskViewModel())
} 