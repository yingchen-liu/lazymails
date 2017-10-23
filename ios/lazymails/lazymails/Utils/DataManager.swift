//
//  Data.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit
import CoreData

/**
 Help easy access to CoreData managed object context
 */
class DataManager: NSObject {
    
    static let shared = DataManager()
    var categoryList : [Category] = []
    var mailList : [Mail] = []
    let managedObjectContext: NSManagedObjectContext
    
    override init() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
    }
    
    func delete(object: NSManagedObject) {
        managedObjectContext.delete(object)
    }
    
    func save() throws {
        do {
            try managedObjectContext.save()
        } catch {
            throw error
        }
    }
    func fetchCategories() {
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        do {
            categoryList = try self.managedObjectContext.fetch(fetchRequest)
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    func fetchMails() {
        let fetchRequest = NSFetchRequest<Mail>(entityName: "Mail")
        do {
            mailList = try self.managedObjectContext.fetch(fetchRequest)
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
}

