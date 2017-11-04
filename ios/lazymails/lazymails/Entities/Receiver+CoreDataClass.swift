//
//  Receivers+CoreDataClass.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Receiver)
public class Receiver: NSManagedObject {
    /**
     Insert new receiver to core data
     - Parameters:
         - id: receiver id
         - title: receiver title
         - firstname: receiver firstname
         - lastname: receiver lastname
     - Returns: Receiver
     */
    static func insertNewObject(id: String, title: String, firstname: String, lastname: String) -> Receiver {
        let receiver = NSEntityDescription.insertNewObject(forEntityName: "Receiver", into: DataManager.shared.managedObjectContext) as! Receiver
        receiver.id = id
        receiver.title = title
        receiver.firstname = firstname
        receiver.lastname = lastname
        
        return receiver
    }
    /**
     Fetch all receivers from core data
     
     - Returns: a list of Receivers
     */
    static func fetchAll() -> [Receiver] {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Receiver")
        
        do {
            return try DataManager.shared.managedObjectContext.fetch(fetch) as NSArray as! [Receiver]
        } catch {
            fatalError("Failed to fetch receivers: \(error)")
        }
    }
    
}
