import CloudKit
import Foundation

class CloudKitManager {
    static let shared = CloudKitManager()
    
    let container: CKContainer
    let privateDatabase: CKDatabase
    let sharedDatabase: CKDatabase
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.innobyte.tasklight")
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
    }
    
    func checkCloudKitAvailability() async throws {
        try await container.accountStatus()
    }
    
    // MARK: - CRUD Operations
    
    func save(_ record: CKRecord) async throws {
        try await privateDatabase.save(record)
    }
    
    func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        try await privateDatabase.record(for: recordID)
    }
    
    func delete(recordID: CKRecord.ID) async throws {
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    func modify(_ record: CKRecord) async throws {
        try await privateDatabase.modifyRecords(saving: [record], deleting: [])
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
            let (matchResults, _) = try await privateDatabase.records(matching: query)
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
        static let dueDate = "dueDate"
        static let priority = "priority"
        static let notes = "notes"
        static let createdAt = "createdAt"
        static let modifiedAt = "modifiedAt"
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
        do {
            let records = try await query(recordType: RecordType.task)
            let tasks = records.compactMap { TaskItem(from: $0) }
            print("Converted \(tasks.count) tasks")  // Debug print
            return tasks
        } catch {
            print("Fetch tasks error: \(error)")  // Full error
            throw error
        }
    }
    
    func saveTasks(_ tasks: [TaskItem]) async throws {
        do {
            let records = tasks.map { $0.toCKRecord() }
            print("Saving \(records.count) records")
            
            // Use modify instead of save for better update handling
            let (savedResults, _) = try await privateDatabase.modifyRecords(
                saving: records,
                deleting: [],
                savePolicy: .changedKeys // Only update changed fields
            )
            
            for result in savedResults {
                if case .failure(let error) = result.1 {
                    print("Save error for record: \(error)")
                    throw error
                }
            }
            print("Successfully saved records")
        } catch {
            print("Save tasks error: \(error)")
            throw error
        }
    }
    
    func deleteTask(_ task: TaskItem) async throws {
        guard let recordID = task.recordID else { return }
        _ = try await privateDatabase.deleteRecord(withID: recordID)
    }
} 