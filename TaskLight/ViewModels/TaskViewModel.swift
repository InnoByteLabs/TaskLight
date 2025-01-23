import Foundation
import SwiftUI

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var deletedTasks: [TaskItem] = []
    @Published var errorMessage: String?
    @Published var isShowingError = false
    
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
            
            // Insert at the beginning of the array
            tasks.removeAll(where: { $0.id == task.id })
            tasks.insert(newTask, at: 0)
            
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
    
    func fetchTasks() async {
        do {
            let allTasks = try await cloudKitManager.fetchTasks()
            tasks = allTasks.filter { !$0.isDeleted }
            deletedTasks = allTasks.filter { $0.isDeleted }
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
            }
            
            // Save to CloudKit
            try await cloudKitManager.saveTask(task)
        } catch {
            // Refresh from server if update failed
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
            // Remove from active tasks immediately
            tasks.removeAll { $0.id == task.id }
            // Add to deleted tasks immediately
            deletedTasks.append(updatedTask)
            
            // Save to CloudKit
            try await cloudKitManager.saveTask(updatedTask)
            
            // Refresh to ensure consistency
            await fetchTasks()
        } catch {
            // Revert local changes if save fails
            await fetchTasks()
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
}