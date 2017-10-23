//
//  Category+CoreDataProperties.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 17/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//
//

import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var icon: String?
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var mail: NSSet?

}

// MARK: Generated accessors for mail
extension Category {

    @objc(addMailObject:)
    @NSManaged public func addToMail(_ value: Mail)

    @objc(removeMailObject:)
    @NSManaged public func removeFromMail(_ value: Mail)

    @objc(addMail:)
    @NSManaged public func addToMail(_ values: NSSet)

    @objc(removeMail:)
    @NSManaged public func removeFromMail(_ values: NSSet)

}
