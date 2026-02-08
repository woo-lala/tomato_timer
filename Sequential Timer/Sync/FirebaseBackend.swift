import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

protocol RemoteBackend {
    func ensureAuth(completion: @escaping (Result<String, Error>) -> Void)
    func uploadRoutine(_ routine: RoutineDTO, completion: @escaping (Result<Void, Error>) -> Void)
    func uploadSession(_ session: SessionSummaryDTO, completion: @escaping (Result<Void, Error>) -> Void)
}

enum BackendError: Error {
    case authUnavailable
    case firestoreUnavailable
    case missingUser
}

final class FirebaseBackend: RemoteBackend {
    static let shared = FirebaseBackend()

    private init() {}

    func ensureAuth(completion: @escaping (Result<String, Error>) -> Void) {
        #if canImport(FirebaseAuth)
        if let user = Auth.auth().currentUser {
            completion(.success(user.uid))
            return
        }
        Auth.auth().signInAnonymously { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                completion(.failure(BackendError.missingUser))
                return
            }
            completion(.success(user.uid))
        }
        #else
        completion(.failure(BackendError.authUnavailable))
        #endif
    }

    func uploadRoutine(_ routine: RoutineDTO, completion: @escaping (Result<Void, Error>) -> Void) {
        #if canImport(FirebaseFirestore)
        guard let uid = currentUid() else {
            completion(.failure(BackendError.missingUser))
            return
        }
        let db = Firestore.firestore()
        let doc = db.collection("users").document(uid).collection("routines").document(routine.routineId)
        let data = serializeRoutine(routine)
        doc.setData(data, merge: true) { error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
        #else
        completion(.failure(BackendError.firestoreUnavailable))
        #endif
    }

    func uploadSession(_ session: SessionSummaryDTO, completion: @escaping (Result<Void, Error>) -> Void) {
        #if canImport(FirebaseFirestore)
        guard let uid = currentUid() else {
            completion(.failure(BackendError.missingUser))
            return
        }
        let db = Firestore.firestore()
        let doc = db.collection("users").document(uid).collection("sessions").document(session.sessionId)
        let data = serializeSession(session)
        doc.setData(data, merge: true) { error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
        #else
        completion(.failure(BackendError.firestoreUnavailable))
        #endif
    }

    private func currentUid() -> String? {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser?.uid
        #else
        return nil
        #endif
    }

    private func serializeRoutine(_ routine: RoutineDTO) -> [String: Any] {
        let steps = routine.steps.map { step in
            return [
                "stepId": step.stepId,
                "order": step.order,
                "title": step.title,
                "durationSeconds": step.durationSeconds
            ]
        }
        return [
            "routineId": routine.routineId,
            "name": routine.name,
            "createdAt": routine.createdAt,
            "updatedAt": routine.updatedAt,
            "isArchived": routine.isArchived,
            "isTemplate": routine.isTemplate,
            "keepScreenOn": routine.keepScreenOn,
            "steps": steps,
            "schemaVersion": routine.schemaVersion
        ]
    }

    private func serializeSession(_ session: SessionSummaryDTO) -> [String: Any] {
        return [
            "sessionId": session.sessionId,
            "routineId": session.routineId,
            "startedAt": session.startedAt,
            "endedAt": session.endedAt,
            "status": session.status,
            "pauseCount": session.pauseCount,
            "plannedStepCount": session.plannedStepCount,
            "completedStepCount": session.completedStepCount,
            "actualDurationSeconds": session.actualDurationSeconds,
            "date": session.date,
            "patternKey": session.patternKey,
            "createdAt": session.createdAt,
            "schemaVersion": session.schemaVersion
        ]
    }
}
