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

    static func insertNewObject(id: String, title: String, firstname: String, lastname: String) -> Receiver {
        let receiver = NSEntityDescription.insertNewObject(forEntityName: "Receiver", into: Data.shared.managedObjectContext) as! Receiver
        receiver.id = id
        receiver.title = title
        receiver.firstname = firstname
        receiver.lastname = lastname
        
        return receiver
    }
    
    static func fetchAll() -> [Receiver] {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Receiver")
        
        do {
            return try Data.shared.managedObjectContext.fetch(fetch) as NSArray as! [Receiver]
        } catch {
            fatalError("Failed to fetch receivers: \(error)")
        }
    }
    
}
