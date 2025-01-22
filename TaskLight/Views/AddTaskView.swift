import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    
    @State private var title = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                TextField("Notes", text: $notes)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newTask = TaskItem(
                            title: title,
                            notes: notes.isEmpty ? nil : notes
                        )
                        Task {
                            await viewModel.addTask(newTask)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            })
        }
    }
} 