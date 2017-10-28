//
//  Category+CoreDataClass.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 17/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject {
    
    static func insertNewObject(id: String, name: String, icon: String) -> Category {
        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: DataManager.shared.managedObjectContext) as! Category
        category.id = id
        category.name = name
        category.icon = icon
        category.notified = true
        return category
    }
    
}
