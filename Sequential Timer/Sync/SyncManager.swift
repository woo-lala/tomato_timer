import Foundation
import Network

final class SyncManager {
    static let shared = SyncManager()

    private let queueStore: UploadQueueStore
    private let backend: RemoteBackend
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "sync.network.monitor")

    private let lastSyncAttemptKey = "seqtimer.sync.lastSyncAttemptDate"
    private let calendar = Calendar(identifier: .gregorian)
    private var isSyncing = false
    private var isNetworkReachable = true

    init(queueStore: UploadQueueStore = .shared, backend: RemoteBackend = FirebaseBackend.shared) {
        self.queueStore = queueStore
        self.backend = backend
        self.monitor = NWPathMonitor()
        startNetworkMonitor()
    }

    func handleAppBecameActive(now: Date = Date()) {
        guard shouldAttemptSync(now: now) else { return }
        recordSyncAttempt(now: now)
        guard isNetworkReachable else { return }
        guard !isSyncing else { return }
        isSyncing = true
        backend.ensureAuth { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.flushQueue { [weak self] in
                    self?.isSyncing = false
                }
            case .failure:
                self.isSyncing = false
            }
        }
    }

    func enqueueRoutine(routineId: UUID, payloadHash: String?) {
        queueStore.enqueueRoutine(routineId: routineId, payloadHash: payloadHash)
    }

    func enqueueSession(sessionId: UUID) {
        queueStore.enqueueSession(sessionId: sessionId)
    }

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkReachable = path.status == .satisfied
        }
        monitor.start(queue: monitorQueue)
    }

    private func shouldAttemptSync(now: Date) -> Bool {
        let today = SyncDateUtils.todayKSTString(now: now)
        let last = UserDefaults.standard.string(forKey: lastSyncAttemptKey)
        return last != today
    }

    private func recordSyncAttempt(now: Date) {
        let today = SyncDateUtils.todayKSTString(now: now)
        UserDefaults.standard.set(today, forKey: lastSyncAttemptKey)
    }

    private func flushQueue(completion: @escaping () -> Void) {
        let items = queueStore.fetchItemsToUpload()
        if items.isEmpty {
            completion()
            return
        }

        let group = DispatchGroup()

        for item in items {
            guard let typeRaw = item.type, let type = UploadQueueItemType(rawValue: typeRaw) else {
                queueStore.remove(item)
                continue
            }
            switch type {
            case .routine:
                group.enter()
                uploadRoutine(item) {
                    group.leave()
                }
            case .session:
                group.enter()
                uploadSession(item) {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    private func uploadRoutine(_ item: UploadQueueItem, completion: @escaping () -> Void) {
        guard let entityId = item.entityId else {
            queueStore.remove(item)
            completion()
            return
        }
        guard let routine = CoreDataManager.shared.fetchRoutine(by: entityId) else {
            queueStore.remove(item)
            completion()
            return
        }
        guard let dto = RoutineDTOBuilder.build(from: routine) else {
            queueStore.remove(item)
            completion()
            return
        }

        backend.uploadRoutine(dto) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.queueStore.remove(item)
            case .failure:
                self.queueStore.markFailed(item)
            }
            completion()
        }
    }

    private func uploadSession(_ item: UploadQueueItem, completion: @escaping () -> Void) {
        guard let entityId = item.entityId else {
            queueStore.remove(item)
            completion()
            return
        }
        guard let session = CoreDataManager.shared.fetchSession(by: entityId) else {
            queueStore.remove(item)
            completion()
            return
        }
        guard let dto = SessionSummaryBuilder.build(from: session) else {
            queueStore.remove(item)
            completion()
            return
        }

        backend.uploadSession(dto) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.queueStore.remove(item)
            case .failure:
                self.queueStore.markFailed(item)
            }
            completion()
        }
    }
}
