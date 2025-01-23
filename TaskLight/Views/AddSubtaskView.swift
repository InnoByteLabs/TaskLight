import SwiftUI

struct AddSubtaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    let parentTask: TaskItem
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskItem.Priority = .medium
    @State private var dueDate: Date?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                }
                
                Section {
                    DatePicker("Due Date",
                              selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                              ),
                              displayedComponents: [.date])
                    Toggle("Has Due Date", isOn: Binding(
                        get: { dueDate != nil },
                        set: { if !$0 { dueDate = nil } else if dueDate == nil { dueDate = Date() } }
                    ))
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
                        Task {
                            let subtask = TaskItem(
                                title: title,
                                notes: notes.isEmpty ? nil : notes,
                                priority: priority,
                                dueDate: dueDate,
                                parentTaskID: parentTask.id,
                                groupID: parentTask.groupID  // Inherit parent's group
                            )
                            await viewModel.addSubtask(subtask, to: parentTask)
                            dismiss()
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