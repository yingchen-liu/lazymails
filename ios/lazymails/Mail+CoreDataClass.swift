//
//  Mail+CoreDataClass.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 17/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Mail)
public class Mail: NSManagedObject {
    static func insertNewObject(id: String, title: String, mainText: String, info: String, didRead: Bool, isImportant: Bool,receivedAt: Date,image: String, boxImage: String, showFullImage : Bool) -> Mail {
        let mail = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: DataManager.shared.managedObjectContext) as! Mail
        mail.id = id
        mail.title = title
        mail.mainText = mainText
        mail.info = info
        mail.receivedAt = receivedAt
        mail.image = image
        mail.boxImage = boxImage
        return mail
    }
}
