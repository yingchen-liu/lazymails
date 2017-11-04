//
//  Notification.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 29/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit
import UserNotifications
import Whisper

class Notification: NSObject {
    static let shared = Notification()
    
    override init() {
        super.init()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (granted, error) in
            guard granted else {
                return
            }
            
        })
        
    }
    
    func monitorMail(id: String, categoryName: String) {
        let identifier = id
        let title = "You got a new Mail in Category \(categoryName)"
        let message = ""
     
        notify(title: title, message: message, identifier: identifier)
    }
    
    func monitorNewCategoryMail(id: String, categoryName: String) {
        let identifier = id
        let title = "LazyMail has a new Category \(categoryName)"
        let message = ""
        
        notify(title: title, message: message, identifier: identifier)
    }
    
    func notify(title: String, message: String, identifier: String) {
        // ✴️ Attributes:
        
        // Website: How to Make Local Notifications in iOS 10
        //      https://makeapppie.com/2016/08/08/how-to-make-local-notifications-in-ios-10/
        
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.sound = UNNotificationSound.default()
        content.body = message
        content.categoryIdentifier = identifier
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        // In-app notification
        // ✴️ Attribute:
        // GitHub: hyperoslo/Whisper
        //      https://github.com/hyperoslo/Whisper
        
        let murmur = Murmur(title: title)
        Whisper.show(whistle: murmur, action: .show(5))
    }
    
    
    
    
}
