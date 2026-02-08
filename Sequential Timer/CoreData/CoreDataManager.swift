import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}

    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    // MARK: - Routine CRUD

    func createRoutine(name: String) -> Routine {
        let routine = Routine(context: context)
        routine.routineId = UUID()
        routine.name = name
        routine.createdAt = Date()
        routine.updatedAt = Date()
        routine.isArchived = false
        routine.keepScreenOn = UserDefaults.standard.bool(forKey: "keepScreenOn")
        
        saveContext()
        return routine
    }

    func fetchRoutines(includeArchived: Bool = false) -> [Routine] {
        let request: NSFetchRequest<Routine> = Routine.fetchRequest()
        
        if !includeArchived {
            request.predicate = NSPredicate(format: "isArchived == false")
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            var needsSave = false
            results.forEach { routine in
                if routine.routineId == nil {
                    routine.routineId = UUID()
                    needsSave = true
                }
            }
            if needsSave { saveContext() }
            return results
        } catch {
            print("Error fetching routines: \(error.localizedDescription)")
            return []
        }
    }

    func fetchRoutine(by id: UUID) -> Routine? {
        let request: NSFetchRequest<Routine> = Routine.fetchRequest()
        request.predicate = NSPredicate(format: "routineId == %@", id as CVarArg)
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching routine: \(error.localizedDescription)")
            return nil
        }
    }

    func updateRoutine(_ routine: Routine, name: String? = nil, isArchived: Bool? = nil, isTemplate: Bool? = nil) {
        if let name = name { routine.name = name }
        if let isArchived = isArchived { routine.isArchived = isArchived }
        if let isTemplate = isTemplate { routine.isTemplate = isTemplate }
        routine.updatedAt = Date()
        
        saveContext()
    }

    func fetchTemplateRoutines() -> [Routine] {
        let request: NSFetchRequest<Routine> = Routine.fetchRequest()
        request.predicate = NSPredicate(format: "isTemplate == true AND isArchived == false")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Routine.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching template routines: \(error.localizedDescription)")
            return []
        }
    }

    func deleteRoutine(_ routine: Routine) {
        context.delete(routine)
        saveContext()
    }

    // MARK: - RoutineStep CRUD

    @discardableResult
    func createRoutineStep(routine: Routine, order: Int16, title: String, durationSeconds: Int64) -> RoutineStep {
        let step = RoutineStep(context: context)
        step.stepId = UUID()
        step.routineId = routine.routineId
        step.order = order
        step.title = title
        step.durationSeconds = durationSeconds
        step.routine = routine
        routine.addToSteps(step)
        
        saveContext()
        return step
    }

    func fetchRoutineSteps(for routine: Routine) -> [RoutineStep] {
        let request: NSFetchRequest<RoutineStep> = RoutineStep.fetchRequest()
        request.predicate = NSPredicate(format: "routine == %@", routine)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching routine steps: \(error.localizedDescription)")
            return []
        }
    }

    func updateRoutineStep(_ step: RoutineStep, order: Int16? = nil, title: String? = nil, durationSeconds: Int64? = nil) {
        if let order = order { step.order = order }
        if let title = title { step.title = title }
        if let durationSeconds = durationSeconds { step.durationSeconds = durationSeconds }
        
        saveContext()
    }

    func deleteRoutineStep(_ step: RoutineStep) {
        context.delete(step)
        saveContext()
    }

    // MARK: - Session CRUD

    @discardableResult
    func createSession(for routine: Routine, startedAt: Date = Date()) -> Session {
        let session = Session(context: context)
        session.sessionId = UUID()
        session.routineId = routine.routineId
        session.startedAt = startedAt
        session.status = "RUNNING"
        session.pauseCount = 0
        session.createdAt = Date()
        session.updatedAt = Date()
        session.routine = routine
        routine.addToSessions(session)
        
        saveContext()
        return session
    }

    func fetchSessions(for routine: Routine) -> [Session] {
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "routine == %@", routine)
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching sessions: \(error.localizedDescription)")
            return []
        }
    }

    func fetchSession(by id: UUID) -> Session? {
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "sessionId == %@", id as CVarArg)
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching session: \(error.localizedDescription)")
            return nil
        }
    }

    func updateSession(_ session: Session, 
                      endedAt: Date? = nil, 
                      status: String? = nil,
                      pauseCount: Int16? = nil) {
        if let endedAt = endedAt { session.endedAt = endedAt }
        if let status = status { session.status = status }
        if let pauseCount = pauseCount { session.pauseCount = pauseCount }
        session.updatedAt = Date()
        
        saveContext()
    }

    func deleteSession(_ session: Session) {
        context.delete(session)
        saveContext()
    }

    // MARK: - SessionStep CRUD

    @discardableResult
    func createSessionStep(for session: Session, 
                          stepOrder: Int16, 
                          plannedMinutes: Int16) -> SessionStep {
        let step = SessionStep(context: context)
        step.sessionStepId = UUID()
        step.sessionId = session.sessionId
        step.stepOrder = stepOrder
        step.plannedMinutes = plannedMinutes
        step.actualSeconds = 0
        step.isCompleted = false
        step.createdAt = Date()
        step.updatedAt = Date()
        step.session = session
        session.addToSteps(step)
        
        saveContext()
        return step
    }

    func fetchSessionSteps(for session: Session) -> [SessionStep] {
        let request: NSFetchRequest<SessionStep> = SessionStep.fetchRequest()
        request.predicate = NSPredicate(format: "session == %@", session)
        request.sortDescriptors = [NSSortDescriptor(key: "stepOrder", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching session steps: \(error.localizedDescription)")
            return []
        }
    }

    func updateSessionStep(_ step: SessionStep,
                          actualSeconds: Int64? = nil,
                          isCompleted: Bool? = nil) {
        if let actualSeconds = actualSeconds { step.actualSeconds = actualSeconds }
        if let isCompleted = isCompleted { step.isCompleted = isCompleted }
        step.updatedAt = Date()
        
        saveContext()
    }

    func deleteSessionStep(_ step: SessionStep) {
        context.delete(step)
        saveContext()
    }

    // MARK: - Persistence Info

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
}
