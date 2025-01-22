import SwiftUI

struct TaskRow: View {
    let item: Item
    @Binding var isEditing: Bool
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if isEditing {
                    TextField("Task", text: Binding(
                        get: { item.title },
                        set: { item.title = $0 }
                    ))
                } else {
                    Text(item.title)
                }
                
                Spacer()
                
                if item.isPriority {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            if !item.subTasks.isEmpty {
                ForEach(item.subTasks) { subTask in
                    TaskRow(item: subTask, isEditing: $isEditing)
                        .padding(.leading)
                }
            }
            
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
} 