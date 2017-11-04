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
    
    func monitorMail(categoryName: String, mailTitle: String) {
        let title = "New Mail: \(mailTitle) (\(categoryName))"
        let message = ""
        notify(title: title, message: message)
    }
    
    func notify(title: String, message: String) {
        
        // In-app notification
        // ✴️ Attribute:
        // GitHub: hyperoslo/Whisper
        //      https://github.com/hyperoslo/Whisper
        
        let murmur = Murmur(title: title)
        Whisper.show(whistle: murmur, action: .show(5))
    }
}
