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
    /**
     Insert new mail to core data
     - Parameters:
         - id: mail id
         - title: mail title
         - mainText: mail mainText
         - info: mail info
         - didRead: mail read or not
         - important: mail important or important
         - receiveAt: mail receive date
         - image: mail image
         - image: mailbox image
         - showFullImage: mail show full image or not
     - Returns: Mail
     */
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
