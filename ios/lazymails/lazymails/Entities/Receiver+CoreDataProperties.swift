//
//  Receivers+CoreDataProperties.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//
//

import Foundation
import CoreData


extension Receiver {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Receiver> {
        return NSFetchRequest<Receiver>(entityName: "Receiver")
    }

    @NSManaged public var firstname: String?
    @NSManaged public var id: String?
    @NSManaged public var lastname: String?
    @NSManaged public var title: String?

}
