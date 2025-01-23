import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskItem.Priority = .medium
    @State private var dueDate: Date?
    @State private var selectedGroupID: String?
    
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
                
                Section {
                    Picker("Group", selection: $selectedGroupID) {
                        Text("None").tag(String?.none)
                        ForEach(viewModel.groups) { group in
                            Text(group.title).tag(Optional(group.id))
                        }
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
                        Task {
                            let task = TaskItem(
                                title: title,
                                notes: notes.isEmpty ? nil : notes,
                                priority: priority,
                                dueDate: dueDate,
                                groupID: selectedGroupID
                            )
                            await viewModel.addTask(task)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .task {
            // Fetch groups when view appears
            await viewModel.fetchGroups()
        }
    }
}

#Preview {
    AddTaskView(viewModel: TaskViewModel())
} 