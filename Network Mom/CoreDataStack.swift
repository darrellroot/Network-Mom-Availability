//
//  CoreDataStack.swift
//  Network Mom
//
//  Created by Darrell Root on 1/8/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Foundation
import CoreData
import DLog

class CoreDataStack {
    private let modelName: String
    
    init(modelName: String) {
        self.modelName = modelName
    }
    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()
    private lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                DLog.log(.dataIntegrity,"Unresolved core data error \(error), \(error.userInfo)")
            }
        }
        DLog.log(.dataIntegrity,"Core Data default directory \(NSPersistentContainer.defaultDirectoryURL())")
        return container
    }()
    func saveContext() -> Bool {
/*        guard managedContext.hasChanges else {
            DLog.log(.dataIntegrity,"No core data changes")
            return
        }*/
        do {
            try managedContext.save()
        } catch let error as NSError {
            DLog.log(.dataIntegrity,"Unresolved Core Data Error \(error), \(error.userInfo)")
            return false
        }
        return true
    }
}
