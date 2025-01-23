import SwiftUI

struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Group Name", text: $title)
                }
            }
            .navigationTitle("New Group")
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
                            let group = TaskGroup(
                                title: title
                            )
                            await viewModel.addGroup(group)
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
    AddGroupView(viewModel: TaskViewModel())
} 