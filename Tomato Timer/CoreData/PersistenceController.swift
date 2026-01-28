import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "TomatoTimer")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // If lightweight migration fails, reset the store to avoid a broken app state.
                if let storeURL = storeDescription.url {
                    do {
                        try container.persistentStoreCoordinator.destroyPersistentStore(
                            at: storeURL,
                            ofType: storeDescription.type,
                            options: storeDescription.options
                        )
                        try container.persistentStoreCoordinator.addPersistentStore(
                            ofType: storeDescription.type,
                            configurationName: storeDescription.configuration,
                            at: storeURL,
                            options: storeDescription.options
                        )
                    } catch {
                        fatalError("Unresolved error \(error), \(error)")
                    }
                } else {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        self.container = container
    }
}
