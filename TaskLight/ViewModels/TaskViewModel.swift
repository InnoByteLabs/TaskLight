import Foundation
import CloudKit

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var errorMessage: String?
    
    private let cloudKitManager = CloudKitManager.shared
    
    // MARK: - Task Operations
    func addTask(_ task: TaskItem) async {
        do {
            try await cloudKitManager.saveTasks([task])
            tasks.append(task)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchTasks() async {
        do {
            tasks = try await cloudKitManager.fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateTask(_ task: TaskItem) async {
        do {
            try await cloudKitManager.saveTasks([task])
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteTask(_ task: TaskItem) async {
        do {
            try await cloudKitManager.deleteTask(task)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - CloudKit Status
    func checkCloudKitAvailability() async {
        do {
            try await cloudKitManager.checkCloudKitAvailability()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
} 