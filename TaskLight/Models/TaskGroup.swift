import CloudKit
import Foundation

struct TaskGroup: Identifiable {
    let id: String
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var modifiedAt: Date
    var isDeleted: Bool
    var deletedDate: Date?
    var recordID: CKRecord.ID?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isDeleted: Bool = false,
        deletedDate: Date? = nil,
        recordID: CKRecord.ID? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isDeleted = isDeleted
        self.deletedDate = deletedDate
        self.recordID = recordID
    }
    
    // Initialize from CloudKit record
    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.title = record[CloudKitManager.RecordKey.groupTitle] as? String ?? ""
        self.isCompleted = (record[CloudKitManager.RecordKey.groupIsCompleted] as? Int64 ?? 0) == 1
        self.createdAt = record[CloudKitManager.RecordKey.groupCreatedAt] as? Date ?? Date()
        self.modifiedAt = record[CloudKitManager.RecordKey.groupModifiedAt] as? Date ?? Date()
        self.isDeleted = (record[CloudKitManager.RecordKey.groupIsDeleted] as? Int64 ?? 0) == 1
        self.deletedDate = record[CloudKitManager.RecordKey.groupDeletedDate] as? Date
        self.recordID = record.recordID
    }
    
    // Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Group", recordID: recordID ?? CKRecord.ID(recordName: id))
        record[CloudKitManager.RecordKey.groupTitle] = title
        record[CloudKitManager.RecordKey.groupIsCompleted] = isCompleted ? 1 : 0
        record[CloudKitManager.RecordKey.groupCreatedAt] = createdAt
        record[CloudKitManager.RecordKey.groupModifiedAt] = modifiedAt
        record[CloudKitManager.RecordKey.groupIsDeleted] = isDeleted ? 1 : 0
        record[CloudKitManager.RecordKey.groupDeletedDate] = deletedDate
        return record
    }
} 