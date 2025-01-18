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
    @Query(sort: \Item.timestamp) private var items: [Item]
    @State private var isAddingTask = false
    @State private var isAddingSubTask = false
    @State private var isAssigningTask = false
    @State private var newTaskTitle = ""
    @State private var selectedItem: Item?
    @State private var assigneeEmail = ""
    
    var rootItems: [Item] {
        items.filter { $0.parentTask == nil }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(rootItems) { item in
                    Section {
                        // Main task
                        HStack {
                            TextField("Task name", text: Binding(
                                get: { item.title },
                                set: { newValue in
                                    item.title = newValue
                                    try? modelContext.save()
                                }
                            ))
                            if let assignedTo = item.assignedTo {
                                Text("(\(assignedTo))")
                                    .font(.caption)
                            }
                        }
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
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                                try? modelContext.save()
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
                        
                        // Sub-tasks
                        ForEach(item.subTasks) { subTask in
                            HStack {
                                TextField("Sub-task name", text: Binding(
                                    get: { subTask.title },
                                    set: { newValue in
                                        subTask.title = newValue
                                        try? modelContext.save()
                                    }
                                ))
                                if let assignedTo = subTask.assignedTo {
                                    Text("(\(assignedTo))")
                                        .font(.caption)
                                }
                            }
                            .padding(.leading, 20)
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
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(subTask)
                                    try? modelContext.save()
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        isAddingTask = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
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
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            isAssigningTask = false
                            assigneeEmail = ""
                            selectedItem = nil
                        },
                        trailing: Button("Assign") {
                            if let item = selectedItem {
                                assignTask(item, to: assigneeEmail)
                            }
                            isAssigningTask = false
                            assigneeEmail = ""
                            selectedItem = nil
                        }
                        .disabled(assigneeEmail.isEmpty || !assigneeEmail.contains("@"))
                    )
                }
            }
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
        item.assignedTo = email
        try? modelContext.save()
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
