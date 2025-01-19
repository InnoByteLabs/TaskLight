//
//  ContentView.swift
//  TaskLight
//
//  Created by Blake Lundstrom on 1/18/25.
//

import SwiftUI
import SwiftData
import MessageUI

/*
 TaskLight v1.0
 A task management app with support for sub-tasks and task assignment
 
 Core Features:
 - Main tasks and sub-tasks
 - Task assignment via email
 - Independent task completion
 - Swipe actions for task management
 - Visual hierarchy with indented sub-tasks
 - Data persistence using SwiftData
 
 Created: March 2024
*/

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appTheme") private var appTheme: Theme = .system
    @AppStorage("defaultAssignMessage") private var defaultAssignMessage = "You have been assigned a new task in TaskLight."
    @State private var editMode = EditMode.inactive
    @State private var searchText = ""
    @State private var isShowingSettings = false
    @State private var isEditingDefaultMessage = false
    
    enum Theme: String, CaseIterable {
        case system, light, dark
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    // Separate queries for active and deleted items
    @Query(filter: #Predicate<Item> { item in
        !item.isDeleted && item.parentTask == nil
    }, sort: \Item.timestamp) private var activeItems: [Item]
    
    @Query(filter: #Predicate<Item> { item in
        item.isDeleted
    }, sort: \Item.deletedDate, order: .reverse) private var deletedItems: [Item]
    
    @State private var isAddingTask = false
    @State private var isAddingSubTask = false
    @State private var isAssigningTask = false
    @State private var isShowingNotes = false
    @State private var isShowingDeletedTasks = false
    @State private var newTaskTitle = ""
    @State private var selectedItem: Item?
    @State private var assigneeEmail = ""
    @State private var taskNotes = ""
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return activeItems
        }
        return activeItems.filter { item in
            let titleMatch = item.title.localizedCaseInsensitiveContains(searchText)
            let notesMatch = item.notes?.localizedCaseInsensitiveContains(searchText) ?? false
            let subTaskMatch = item.subTasks.contains { subTask in
                subTask.title.localizedCaseInsensitiveContains(searchText) ||
                (subTask.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            return titleMatch || notesMatch || subTaskMatch
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(filteredItems) { item in
                    Section {
                        // Main task
                        HStack {
                            if editMode.isEditing {
                                TextField("Task name", text: Binding(
                                    get: { item.title },
                                    set: { newValue in
                                        item.title = newValue
                                        try? modelContext.save()
                                    }
                                ))
                            } else {
                                Text(item.title)
                            }
                            
                            if let assignedTo = item.assignedTo {
                                Text("(\(assignedTo))")
                                    .font(.caption)
                            }
                            if item.isPriority {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                            }
                            if item.notes != nil {
                                Image(systemName: "note.text")
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(item.isPriority ? Color.yellow.opacity(0.2) : Color(.systemBackground))
                        .foregroundStyle(item.assignedTo != nil ? .blue : .primary)
                        .strikethrough(item.isCompleted)
                        .swipeActions(edge: .leading) {
                            Button {
                                selectedItem = item
                                isAssigningTask = true
                            } label: {
                                Label("Assign", systemImage: "person.badge.plus")
                            }
                            .tint(.blue)
                            
                            Button {
                                selectedItem = item
                                isAddingSubTask = true
                            } label: {
                                Label("Sub-task", systemImage: "plus.square")
                            }
                            .tint(.orange)
                            
                            Button {
                                item.isPriority.toggle()
                                try? modelContext.save()
                            } label: {
                                Label("Priority", systemImage: "exclamationmark.triangle")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                selectedItem = item
                                isShowingNotes = true
                                taskNotes = item.notes ?? ""
                            } label: {
                                Label("Notes", systemImage: "note.text")
                            }
                            .tint(.gray)
                            
                            Button(role: .destructive) {
                                softDeleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                item.isCompleted.toggle()
                                try? modelContext.save()
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        
                        // Sub-tasks - filter sub-tasks if searching
                        ForEach(searchText.isEmpty ? item.subTasks.filter { !$0.isDeleted } : item.subTasks.filter { subTask in
                            !subTask.isDeleted && (
                                subTask.title.localizedCaseInsensitiveContains(searchText) ||
                                (subTask.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
                            )
                        }) { subTask in
                            HStack {
                                if editMode.isEditing {
                                    TextField("Sub-task name", text: Binding(
                                        get: { subTask.title },
                                        set: { newValue in
                                            subTask.title = newValue
                                            try? modelContext.save()
                                        }
                                    ))
                                } else {
                                    Text(subTask.title)
                                }
                                
                                if let assignedTo = subTask.assignedTo {
                                    Text("(\(assignedTo))")
                                        .font(.caption)
                                }
                                if subTask.isPriority {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                }
                                if subTask.notes != nil {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.leading, 20)
                            .listRowBackground(subTask.isPriority ? Color.yellow.opacity(0.2) : Color(.systemBackground))
                            .foregroundStyle(subTask.assignedTo != nil ? .blue : .primary)
                            .strikethrough(subTask.isCompleted)
                            .swipeActions(edge: .leading) {
                                Button {
                                    selectedItem = subTask
                                    isAssigningTask = true
                                } label: {
                                    Label("Assign", systemImage: "person.badge.plus")
                                }
                                .tint(.blue)
                                
                                Button {
                                    subTask.isPriority.toggle()
                                    try? modelContext.save()
                                } label: {
                                    Label("Priority", systemImage: "exclamationmark.triangle")
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    selectedItem = subTask
                                    isShowingNotes = true
                                    taskNotes = subTask.notes ?? ""
                                } label: {
                                    Label("Notes", systemImage: "note.text")
                                }
                                .tint(.gray)
                                
                                Button(role: .destructive) {
                                    softDeleteItem(subTask)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    subTask.isCompleted.toggle()
                                    try? modelContext.save()
                                } label: {
                                    Label("Complete", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("TaskLight")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        isShowingDeletedTasks.toggle()
                    } label: {
                        Label("Deleted Tasks", systemImage: "trash")
                    }
                }
                ToolbarItem {
                    Button {
                        isAddingTask = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingDeletedTasks) {
                NavigationView {
                    List {
                        ForEach(deletedItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .strikethrough(item.isCompleted)
                                    .foregroundStyle(item.isPriority ? .yellow : .primary)
                                
                                if let deletedDate = item.deletedDate {
                                    Text("Deleted: \(deletedDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                if !item.subTasks.isEmpty {
                                    Text("\(item.subTasks.count) sub-tasks")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                if let notes = item.notes {
                                    Text("Notes: \(notes)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }
                            .swipeActions {
                                Button("Restore") {
                                    restoreItem(item)
                                }
                                .tint(.green)
                                
                                Button("Permanent Delete") {
                                    modelContext.delete(item)
                                    try? modelContext.save()
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .navigationTitle("Deleted Tasks")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isShowingDeletedTasks = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingNotes) {
                NavigationView {
                    Form {
                        TextEditor(text: $taskNotes)
                            .frame(minHeight: 100)
                    }
                    .navigationTitle("Task Notes")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            isShowingNotes = false
                        },
                        trailing: Button("Save") {
                            if let item = selectedItem {
                                item.notes = taskNotes
                                try? modelContext.save()
                            }
                            isShowingNotes = false
                        }
                    )
                }
            }
            .sheet(isPresented: $isAddingTask) {
                NavigationView {
                    Form {
                        TextField("Task name", text: $newTaskTitle)
                    }
                    .navigationTitle("New Task")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            isAddingTask = false
                            newTaskTitle = ""
                        },
                        trailing: Button("Add") {
                            addItem()
                            isAddingTask = false
                        }
                        .disabled(newTaskTitle.isEmpty)
                    )
                }
            }
            .sheet(isPresented: $isAddingSubTask) {
                NavigationView {
                    Form {
                        TextField("Sub-task name", text: $newTaskTitle)
                    }
                    .navigationTitle("New Sub-task")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            isAddingSubTask = false
                            newTaskTitle = ""
                            selectedItem = nil
                        },
                        trailing: Button("Add") {
                            addSubTask()
                            isAddingSubTask = false
                        }
                        .disabled(newTaskTitle.isEmpty)
                    )
                }
            }
            .sheet(isPresented: $isAssigningTask) {
                NavigationView {
                    Form {
                        TextField("Email address", text: $assigneeEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .navigationTitle("Assign Task")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                isAssigningTask = false
                                assigneeEmail = ""
                                selectedItem = nil
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Assign") {
                                if let item = selectedItem {
                                    assignTask(item, to: assigneeEmail)
                                }
                            }
                            .disabled(assigneeEmail.isEmpty || !assigneeEmail.contains("@"))
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationView {
                    List {
                        Section("Appearance") {
                            Picker("Theme", selection: $appTheme) {
                                ForEach(Theme.allCases, id: \.self) { theme in
                                    Text(theme.rawValue.capitalized)
                                        .tag(theme)
                                }
                            }
                            .pickerStyle(.navigationLink)
                        }
                        
                        Section("Task Assignment") {
                            NavigationLink {
                                Form {
                                    TextEditor(text: $defaultAssignMessage)
                                        .frame(minHeight: 100)
                                }
                                .navigationTitle("Default Message")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                LabeledContent("Default Message") {
                                    Text(defaultAssignMessage)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Section("About") {
                            LabeledContent("Version", value: "1.1")
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isShowingSettings = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .preferredColorScheme(appTheme.colorScheme)
            .environment(\.editMode, $editMode)
        } detail: {
            Text("Select a task")
                .foregroundStyle(.secondary)
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(title: newTaskTitle, timestamp: Date())
            modelContext.insert(newItem)
            newTaskTitle = ""
        }
    }
    
    private func addSubTask() {
        if let parentTask = selectedItem {
            withAnimation {
                let subTask = Item(title: newTaskTitle, timestamp: Date())
                subTask.parentTask = parentTask
                parentTask.subTasks.append(subTask)
                modelContext.insert(subTask)
                try? modelContext.save()
                newTaskTitle = ""
                selectedItem = nil
            }
        }
    }
    
    private func assignTask(_ item: Item, to email: String) {
        // Update the item
        item.assignedTo = email
        try? modelContext.save()
        
        // Prepare email content
        let taskTitle = item.title
        let taskNotes = item.notes ?? "No additional notes"
        let isSubTask = item.parentTask != nil
        let taskType = isSubTask ? "sub-task" : "task"
        
        // Create email URL
        let subject = "TaskLight: New \(taskType) assigned"
        let body = """
        \(defaultAssignMessage)
        
        Task: \(taskTitle)
        Type: \(taskType.capitalized)
        \(isSubTask ? "Parent Task: \(item.parentTask?.title ?? "Unknown")\n" : "")
        Notes: \(taskNotes)
        
        Open TaskLight to view and manage this task.
        """
        
        let emailUrl = createEmailUrl(to: email, subject: subject, body: body)
        
        if let url = emailUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        
        // Clean up
        isAssigningTask = false
        assigneeEmail = ""
        selectedItem = nil
    }
    
    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }
    
    private func softDeleteItem(_ item: Item) {
        withAnimation {
            // Mark the item as deleted
            item.isDeleted = true
            item.deletedDate = .now
            
            // If this is a sub-task, we need to remove it from its parent's subTasks array
            if let parentTask = item.parentTask {
                if let index = parentTask.subTasks.firstIndex(where: { $0.id == item.id }) {
                    parentTask.subTasks.remove(at: index)
                }
            }
            
            // If this is a main task, handle all its sub-tasks
            for subTask in item.subTasks {
                subTask.isDeleted = true
                subTask.deletedDate = .now
            }
            
            try? modelContext.save()
        }
    }
    
    private func restoreItem(_ item: Item) {
        withAnimation {
            item.isDeleted = false
            item.deletedDate = nil
            
            // If this is a sub-task, we need to re-add it to its parent's subTasks array
            if let parentTask = item.parentTask {
                if !parentTask.subTasks.contains(where: { $0.id == item.id }) {
                    parentTask.subTasks.append(item)
                }
            }
            
            // If this is a main task, restore all its sub-tasks
            for subTask in item.subTasks {
                subTask.isDeleted = false
                subTask.deletedDate = nil
            }
            
            try? modelContext.save()
        }
    }
}

/*
 Data Model v1.0:
 - Item: Represents both main tasks and sub-tasks
 - Properties:
   - title: String
   - timestamp: Date
   - isCompleted: Bool
   - isShared: Bool
   - assignedTo: String?
   - subTasks: [Item]
   - parentTask: Item?
*/

/*
 Planned for v1.1:
 - [ ] Task due dates
 - [ ] Task priorities
 - [ ] Task categories/tags
 - [ ] Task notes/descriptions
 - [ ] Task sharing improvements
 - [ ] Search functionality
 - [ ] Filter/sort options
*/

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview("App Icon Sizes") {
    Group {
        TaskLightIcon()
            .frame(width: 1024, height: 1024) // App Store
            .previewDisplayName("1024x1024")
        
        TaskLightIcon()
            .frame(width: 180, height: 180) // iPhone 6 Plus
            .previewDisplayName("180x180")
        
        TaskLightIcon()
            .frame(width: 120, height: 120) // iPhone
            .previewDisplayName("120x120")
        
        TaskLightIcon()
            .frame(width: 80, height: 80) // Spotlight
            .previewDisplayName("80x80")
    }
}
