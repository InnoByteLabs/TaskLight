import SwiftUI

struct AddSubtaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    let parentTask: TaskItem
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskItem.Priority = .low
    @State private var dueDate = Date().addingTimeInterval(24 * 60 * 60)
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                }
                
                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let subtask = TaskItem(
                            title: title,
                            notes: notes.isEmpty ? nil : notes,
                            priority: priority,
                            dueDate: hasDueDate ? dueDate : nil,
                            parentTaskID: parentTask.id
                        )
                        
                        dismiss()
                        
                        Task {
                            await viewModel.addSubtask(subtask, to: parentTask)
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddSubtaskView(viewModel: TaskViewModel(), parentTask: TaskItem(title: "Test Parent"))
} 