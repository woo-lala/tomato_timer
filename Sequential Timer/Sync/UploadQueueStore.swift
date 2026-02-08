import Foundation
import CoreData

final class UploadQueueStore {
    static let shared = UploadQueueStore()

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func enqueueRoutine(routineId: UUID, payloadHash: String?) {
        context.performAndWait {
            let request: NSFetchRequest<UploadQueueItem> = UploadQueueItem.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@ AND entityId == %@", UploadQueueItemType.routine.rawValue, routineId as CVarArg)
            request.fetchLimit = 1
            let existing = try? context.fetch(request).first

            if let existing {
                if let payloadHash, existing.payloadHash == payloadHash {
                    return
                }
                existing.payloadHash = payloadHash
                existing.status = UploadQueueItemStatus.pending.rawValue
                existing.lastAttemptAt = nil
                existing.attemptCount = 0
                saveContext()
                return
            }

            let item = UploadQueueItem(context: context)
            item.itemId = UUID()
            item.type = UploadQueueItemType.routine.rawValue
            item.entityId = routineId
            item.status = UploadQueueItemStatus.pending.rawValue
            item.createdAt = Date()
            item.lastAttemptAt = nil
            item.attemptCount = 0
            item.payloadHash = payloadHash
            saveContext()
        }
    }

    func enqueueSession(sessionId: UUID) {
        context.performAndWait {
            let request: NSFetchRequest<UploadQueueItem> = UploadQueueItem.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@ AND entityId == %@", UploadQueueItemType.session.rawValue, sessionId as CVarArg)
            request.fetchLimit = 1
            let existing = try? context.fetch(request).first
            if existing != nil {
                return
            }

            let item = UploadQueueItem(context: context)
            item.itemId = UUID()
            item.type = UploadQueueItemType.session.rawValue
            item.entityId = sessionId
            item.status = UploadQueueItemStatus.pending.rawValue
            item.createdAt = Date()
            item.lastAttemptAt = nil
            item.attemptCount = 0
            item.payloadHash = nil
            saveContext()
        }
    }

    func fetchItemsToUpload() -> [UploadQueueItem] {
        let request: NSFetchRequest<UploadQueueItem> = UploadQueueItem.fetchRequest()
        request.predicate = NSPredicate(format: "status IN %@", [UploadQueueItemStatus.pending.rawValue, UploadQueueItemStatus.failed.rawValue])
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func markFailed(_ item: UploadQueueItem) {
        context.performAndWait {
            item.status = UploadQueueItemStatus.failed.rawValue
            item.attemptCount += 1
            item.lastAttemptAt = Date()
            saveContext()
        }
    }

    func remove(_ item: UploadQueueItem) {
        context.performAndWait {
            context.delete(item)
            saveContext()
        }
    }

    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
