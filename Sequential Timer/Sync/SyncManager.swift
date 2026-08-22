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
        guard isNetworkReachable else { return }
        guard !isSyncing else { return }
        isSyncing = true
        backend.ensureAuth { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                // 도달성과 인증이 실제로 확인된 뒤에 기록한다. 이 호출이 앞에 있으면
                // 활성화 시점에 오프라인이거나 인증이 실패했을 때 그날치 시도가 소진돼,
                // 이후 온라인이 돼도 다음 KST 날짜가 될 때까지 재시도하지 않는다.
                self.recordSyncAttempt(now: now)
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
