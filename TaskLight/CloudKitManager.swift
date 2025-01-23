import CloudKit
import Foundation

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.innobyte.tasklight")
        database = container.privateCloudDatabase
    }
    
    func checkCloudKitAvailability() async throws {
        let status = try await container.accountStatus()
        print("CloudKit Status: \(status.rawValue)")
        
        switch status {
        case .available:
            print("CloudKit is available")
        case .noAccount:
            throw CloudKitError.iCloudAccountNotFound
        case .restricted:
            throw CloudKitError.iCloudAccountRestricted
        case .couldNotDetermine:
            throw CloudKitError.iCloudAccountUnknown
        @unknown default:
            throw CloudKitError.iCloudAccountUnknown
        }
    }
    
    // MARK: - CRUD Operations
    
    func save(_ record: CKRecord) async throws {
        try await database.save(record)
    }
    
    func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        try await database.record(for: recordID)
    }
    
    func delete(recordID: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: recordID)
    }
    
    func modify(_ record: CKRecord) async throws {
        try await database.modifyRecords(saving: [record], deleting: [])
    }
    
    // MARK: - Query Operations
    
    func query(recordType: String, predicate: NSPredicate = NSPredicate(value: true)) async throws -> [CKRecord] {
        // Create a compound query using indexed fields
        let titlePredicate = NSPredicate(format: "%K != %@", RecordKey.title, "")
        let query = CKQuery(recordType: recordType, predicate: titlePredicate)
        
        // Sort by indexed fields only
        query.sortDescriptors = [
            NSSortDescriptor(key: RecordKey.createdAt, ascending: false)
        ]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            let records = matchResults.compactMap { try? $0.1.get() }
            print("Found \(records.count) records")
            return records
        } catch {
            print("Query error: \(error)")
            throw error
        }
    }
    
    // MARK: - Record Types
    enum RecordType {
        static let task = "Task"
    }
    
    // MARK: - Record Keys
    enum RecordKey {
        static let title = "title"
        static let isCompleted = "isCompleted"
        static let notes = "notes"
        static let priority = "priority"
        static let dueDate = "dueDate"
        static let createdAt = "createdAt"
        static let modifiedAt = "modifiedAt"
        static let groupID = "groupID"
        static let parentTaskID = "parentTaskID"
        static let timestamp = "timestamp"
        static let isDeleted = "isDeleted"
        static let deletedDate = "deletedDate"
    }
    
    // Error handling
    enum CloudKitError: LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountRestricted
        case iCloudAccountUnknown
        
        var errorDescription: String? {
            switch self {
            case .iCloudAccountNotFound:
                return "iCloud account not found. Please sign in to your iCloud account."
            case .iCloudAccountRestricted:
                return "iCloud account is restricted."
            case .iCloudAccountUnknown:
                return "Unknown iCloud account status."
            }
        }
    }
    
    // MARK: - Task Operations
    func fetchTasks() async throws -> [TaskItem] {
        print("Fetching tasks...")
        
        // Use a simple predicate that only checks title exists
        let titlePredicate = NSPredicate(format: "%K != %@", RecordKey.title, "")
        let query = CKQuery(recordType: "Task", predicate: titlePredicate)
        
        // Use only indexed fields for sorting
        query.sortDescriptors = [
            NSSortDescriptor(key: RecordKey.priority, ascending: false),
            NSSortDescriptor(key: RecordKey.createdAt, ascending: false)
        ]
        
        do {
            let result = try await database.records(matching: query)
            let tasks = result.matchResults.compactMap { try? TaskItem(from: $0.1.get()) }
            print("Fetched \(tasks.count) total tasks")
            return tasks
        } catch {
            print("Error fetching tasks: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Add a new function specifically for fetching deleted tasks
    func fetchDeletedTasks() async throws -> [TaskItem] {
        print("Fetching deleted tasks...")
        
        let predicate = NSPredicate(format: "%K != %@ AND %K == %d",
            RecordKey.title, "",
            RecordKey.isDeleted, 1  // Only fetch deleted tasks
        )
        
        let query = CKQuery(recordType: "Task", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.deletedDate, ascending: false)]
        
        do {
            let result = try await database.records(matching: query)
            let tasks = result.matchResults.compactMap { try? TaskItem(from: $0.1.get()) }
            print("Fetched \(tasks.count) deleted tasks")
            return tasks
        } catch {
            print("Error fetching deleted tasks: \(error.localizedDescription)")
            throw error
        }
    }
    
    func saveTask(_ task: TaskItem) async throws {
        print("Saving task: \(task.title)")
        print("isDeleted: \(task.isDeleted)")  // Debug log
        
        do {
            // Try to fetch existing record first
            if let recordID = task.recordID {
                do {
                    let existingRecord = try await database.record(for: recordID)
                    print("Found existing record")
                    
                    // Update existing record
                    existingRecord[RecordKey.title] = task.title
                    existingRecord[RecordKey.isCompleted] = task.isCompleted ? 1 : 0
                    existingRecord[RecordKey.notes] = task.notes
                    existingRecord[RecordKey.priority] = Int64(task.priority.rawValue)
                    existingRecord[RecordKey.dueDate] = task.dueDate
                    existingRecord[RecordKey.modifiedAt] = Date()
                    existingRecord[RecordKey.isDeleted] = task.isDeleted ? 1 : 0  // Make sure we set isDeleted
                    existingRecord[RecordKey.deletedDate] = task.deletedDate      // And deletedDate
                    
                    // Save modifications
                    try await database.modifyRecords(saving: [existingRecord], deleting: [])
                    print("Successfully modified existing task")
                    print("isDeleted status: \(existingRecord[RecordKey.isDeleted] ?? "nil")")
                    return
                } catch {
                    print("Record not found or error: \(error.localizedDescription)")
                }
            }
            
            // Create new record
            let record = task.toCKRecord()
            record[RecordKey.timestamp] = Date().timeIntervalSince1970
            record[RecordKey.isDeleted] = task.isDeleted ? 1 : 0  // Make sure we set isDeleted for new records
            record[RecordKey.deletedDate] = task.deletedDate      // And deletedDate for new records
            
            let savedRecord = try await database.save(record)
            print("Successfully saved new task with ID: \(savedRecord.recordID.recordName)")
            print("isDeleted status: \(savedRecord[RecordKey.isDeleted] ?? "nil")")
        } catch {
            print("Error saving task: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteTask(_ task: TaskItem) async throws {
        guard let recordID = task.recordID else {
            print("No recordID found for task: \(task.title)")
            return
        }
        
        do {
            try await database.deleteRecord(withID: recordID)
            print("Successfully deleted task: \(task.title)")
        } catch {
            print("Error deleting task: \(error.localizedDescription)")
            throw error
        }
    }
} 