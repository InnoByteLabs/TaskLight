import Foundation
import SwiftUI

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var deletedTasks: [TaskItem] = []
    @Published var showingAddSubtask = false
    @Published var selectedParentTask: TaskItem?
    @Published var errorMessage: String?
    @Published var isShowingError = false
    @Published var groups: [TaskGroup] = []
    @Published var showingAddGroup = false
    
    private let cloudKitManager = CloudKitManager.shared
    
    // MARK: - Task Operations
    func addTask(_ task: TaskItem) async {
        do {
            // Add to local array immediately for UI update
            var newTask = task
            try await cloudKitManager.saveTask(task)
            
            // Update the task with the saved record ID
            if let lastSavedTask = tasks.first(where: { $0.id == task.id }) {
                newTask = lastSavedTask
            }
            
            // Only add to tasks array if it's not part of a group
            if task.groupID == nil {
                tasks.removeAll(where: { $0.id == task.id })
                tasks.insert(newTask, at: 0)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func fetchTasks() async {
        do {
            let allTasks = try await cloudKitManager.fetchTasks()
            tasks = allTasks // Store all tasks, including grouped ones
            deletedTasks = allTasks.filter { $0.isDeleted }
            await fetchGroups() // Also fetch groups when fetching tasks
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func updateTask(_ task: TaskItem) async {
        do {
            // Update local array immediately
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            } else if task.groupID != nil {
                // If it's a new grouped task, add it to tasks array
                tasks.append(task)
            }
            
            // Save to CloudKit
            try await cloudKitManager.saveTask(task)
            
            // Only handle parent-child relationships for ungrouped tasks
            if task.groupID == nil {
                // Update parent task if this is a subtask
                if let parentID = task.parentTaskID,
                   let parentTask = tasks.first(where: { $0.id == parentID }) {
                    let siblings = subtasksFor(parentTask)
                    let allCompleted = siblings.allSatisfy { $0.isCompleted }
                    if parentTask.isCompleted != allCompleted {
                        var updatedParent = parentTask
                        updatedParent.isCompleted = allCompleted
                        try await cloudKitManager.saveTask(updatedParent)
                        if let index = tasks.firstIndex(where: { $0.id == parentID }) {
                            tasks[index] = updatedParent
                        }
                    }
                }
            }
        } catch {
            await fetchTasks()
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func deleteTask(_ task: TaskItem) async {
        do {
            // Remove from local array immediately
            tasks.removeAll { $0.id == task.id }
            
            // Delete from CloudKit
            try await cloudKitManager.deleteTask(task)
        } catch {
            // Refresh from server if delete failed
            await fetchTasks()
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func softDeleteTask(_ task: TaskItem) async {
        var updatedTask = task
        updatedTask.isDeleted = true
        updatedTask.deletedDate = Date()
        
        do {
            // Delete the task
            try await cloudKitManager.saveTask(updatedTask)
            
            // Remove from tasks array and add to deletedTasks
            tasks.removeAll { $0.id == task.id }
            deletedTasks.append(updatedTask)
            
            // If this is a subtask, update the parent's hasSubtasks property
            if let parentID = task.parentTaskID,
               let parentTask = tasks.first(where: { $0.id == parentID }) {
                let remainingSubtasks = tasks.filter { 
                    $0.parentTaskID == parentID && !$0.isDeleted 
                }
                
                if remainingSubtasks.isEmpty {
                    var updatedParent = parentTask
                    updatedParent.hasSubtasks = false
                    try await cloudKitManager.saveTask(updatedParent)
                    if let index = tasks.firstIndex(where: { $0.id == parentID }) {
                        tasks[index] = updatedParent
                    }
                }
            }
            
            // If this is a parent task, delete all its subtasks
            if task.hasSubtasks {
                let subtasks = self.subtasksFor(task)
                for var subtask in subtasks {
                    subtask.isDeleted = true
                    subtask.deletedDate = Date()
                    try await cloudKitManager.saveTask(subtask)
                    tasks.removeAll { $0.id == subtask.id }
                    deletedTasks.append(subtask)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func restoreTask(_ task: TaskItem) async {
        var updatedTask = task
        updatedTask.isDeleted = false
        updatedTask.deletedDate = nil
        
        do {
            try await cloudKitManager.saveTask(updatedTask)
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func permanentlyDeleteTask(_ task: TaskItem) async {
        do {
            try await cloudKitManager.deleteTask(task)
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    // MARK: - CloudKit Status
    func checkCloudKitAvailability() async {
        do {
            try await cloudKitManager.checkCloudKitAvailability()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    // Get subtasks for a specific task
    func subtasksFor(_ task: TaskItem) -> [TaskItem] {
        tasks.filter { $0.parentTaskID == task.id }
    }
    
    // Add a subtask to a parent task
    func addSubtask(_ subtask: TaskItem, to parentTask: TaskItem) async {
        do {
            // Update parent task to indicate it has subtasks
            var updatedParent = parentTask
            updatedParent.hasSubtasks = true
            
            // Save both the subtask and updated parent
            try await cloudKitManager.saveTask(subtask)
            try await cloudKitManager.saveTask(updatedParent)
            
            // Update local arrays
            if let index = tasks.firstIndex(where: { $0.id == parentTask.id }) {
                tasks[index] = updatedParent
            }
            tasks.append(subtask)
            
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    // Toggle task completion (also handles subtasks)
    func toggleTaskCompletion(_ task: TaskItem) async {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        
        do {
            // Just update the single task
            try await cloudKitManager.saveTask(updatedTask)
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
            
            // Only handle parent-child relationships for ungrouped tasks
            if task.groupID == nil {
                // If this is a parent task, update all its subtasks
                if task.hasSubtasks {
                    let subtasks = self.subtasksFor(task)
                    for var subtask in subtasks {
                        subtask.isCompleted = updatedTask.isCompleted
                        try await cloudKitManager.saveTask(subtask)
                        if let index = tasks.firstIndex(where: { $0.id == subtask.id }) {
                            tasks[index] = subtask
                        }
                    }
                }
                
                // Update parent if this is a subtask
                if let parentID = task.parentTaskID,
                   let parentTask = tasks.first(where: { $0.id == parentID }) {
                    let siblings = subtasksFor(parentTask)
                    let allCompleted = siblings.allSatisfy { $0.isCompleted }
                    if parentTask.isCompleted != allCompleted {
                        var updatedParent = parentTask
                        updatedParent.isCompleted = allCompleted
                        try await cloudKitManager.saveTask(updatedParent)
                        if let index = tasks.firstIndex(where: { $0.id == parentID }) {
                            tasks[index] = updatedParent
                        }
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    // Update filtered tasks to handle parent-child relationships
    var filteredRootTasks: [TaskItem] {
        tasks.filter { $0.parentTaskID == nil }  // Only return top-level tasks
    }
    
    // MARK: - Group Operations
    
    func fetchGroups() async {
        do {
            let allGroups = try await cloudKitManager.fetchGroups()
            groups = allGroups.filter { !$0.isDeleted }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func addGroup(_ group: TaskGroup) async {
        do {
            // Save to CloudKit
            try await cloudKitManager.saveGroup(group)
            
            // Add to local array immediately
            groups.append(group)
            
            // Optional: Sort groups if needed
            groups.sort { $0.createdAt > $1.createdAt }
            
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func toggleGroupCompletion(_ group: TaskGroup) async {
        var updatedGroup = group
        updatedGroup.isCompleted.toggle()
        
        do {
            // Update group
            try await cloudKitManager.saveGroup(updatedGroup)
            if let index = groups.firstIndex(where: { $0.id == group.id }) {
                groups[index] = updatedGroup
            }
            
            // Update all tasks in the group
            let groupTasks = tasksForGroup(group)
            for var task in groupTasks {
                task.isCompleted = updatedGroup.isCompleted
                try await cloudKitManager.saveTask(task)
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index] = task
                }
                
                // Update subtasks if any
                if task.hasSubtasks {
                    let subtasks = self.subtasksFor(task)
                    for var subtask in subtasks {
                        subtask.isCompleted = updatedGroup.isCompleted
                        try await cloudKitManager.saveTask(subtask)
                        if let index = tasks.firstIndex(where: { $0.id == subtask.id }) {
                            tasks[index] = subtask
                        }
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func softDeleteGroup(_ group: TaskGroup) async {
        var updatedGroup = group
        updatedGroup.isDeleted = true
        updatedGroup.deletedDate = Date()
        
        do {
            // Delete group
            try await cloudKitManager.saveGroup(updatedGroup)
            groups.removeAll { $0.id == group.id }
            
            // Delete all tasks in the group
            let groupTasks = tasksForGroup(group)
            for var task in groupTasks {
                task.isDeleted = true
                task.deletedDate = Date()
                try await cloudKitManager.saveTask(task)
                tasks.removeAll { $0.id == task.id }
                deletedTasks.append(task)
                
                // Delete subtasks if any
                if task.hasSubtasks {
                    let subtasks = self.subtasksFor(task)
                    for var subtask in subtasks {
                        subtask.isDeleted = true
                        subtask.deletedDate = Date()
                        try await cloudKitManager.saveTask(subtask)
                        tasks.removeAll { $0.id == subtask.id }
                        deletedTasks.append(subtask)
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    // Helper function to get tasks for a specific group
    func tasksForGroup(_ group: TaskGroup) -> [TaskItem] {
        tasks.filter { task in
            !task.isDeleted && task.groupID == group.id
        }
    }
}