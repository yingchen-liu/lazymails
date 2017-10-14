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
class Data: NSObject {
    
    static let shared = Data()
    
    let managedObjectContext: NSManagedObjectContext
    
    override init() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
    }
    
}

