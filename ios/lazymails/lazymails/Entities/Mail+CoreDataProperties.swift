//
//  Mail+CoreDataProperties.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 17/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//
//

import Foundation
import CoreData


extension Mail {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Mail> {
        return NSFetchRequest<Mail>(entityName: "Mail")
    }

    @NSManaged public var boxImage: String?
    @NSManaged public var didRead: Bool
    @NSManaged public var id: String?
    @NSManaged public var image: String?
    @NSManaged public var info: String?
    @NSManaged public var isImportant: Bool
    @NSManaged public var mainText: String?
    @NSManaged public var receivedAt: Date?
    @NSManaged public var showFullImage: Bool
    @NSManaged public var title: String?
    @NSManaged public var category: Category

}
