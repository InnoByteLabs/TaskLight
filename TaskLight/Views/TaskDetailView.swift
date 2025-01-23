import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var task: TaskItem
    @State private var showingDeleteConfirmation = false
    @State private var selectedGroupID: String?
    
    init(task: TaskItem, viewModel: TaskViewModel) {
        self.viewModel = viewModel
        _task = State(initialValue: task)
        _selectedGroupID = State(initialValue: task.groupID)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $task.title)
                TextField("Notes", text: Binding(
                    get: { task.notes ?? "" },
                    set: { task.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(4, reservesSpace: true)
            }
            
            Section {
                Picker("Priority", selection: $task.priority) {
                    ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
            }
            
            Section {
                DatePicker("Due Date",
                          selection: Binding(
                            get: { task.dueDate ?? Date() },
                            set: { task.dueDate = $0 }
                          ),
                          displayedComponents: [.date])
                Toggle("Has Due Date", isOn: Binding(
                    get: { task.dueDate != nil },
                    set: { if !$0 { task.dueDate = nil } else if task.dueDate == nil { task.dueDate = Date() } }
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
            
            if !task.isDeleted {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        var updatedTask = task
                        updatedTask.groupID = selectedGroupID
                        await viewModel.updateTask(updatedTask)
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this task?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.softDeleteTask(task)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
} 