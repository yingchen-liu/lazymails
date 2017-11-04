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
import AudioToolbox

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
    
    /**
     Notify a mail arrived
     - Parameters:
         - categoryName: category name
         - mailTitle: mail title
     */
    func notifyMail(categoryName: String, mailTitle: String) {
        let title = "New Mail: \(mailTitle) (\(categoryName))"
        notify(title: title, message: "")
    }
    
    /**
     Notify mailbox online
     */
    func notifyMailboxOnline() {
        notify(title: "Your mailbox is now online", message: "")
    }
    
    /**
     Notify mailbox offline
     */
    func notifyMailboxOffline() {
        notify(title: "Your mailbox is now offline", message: "")
    }
 
    /**
      Mail notification
     - Parameters:
         - title: title shows in notification
         - message: message shows in notification
     */
    func notify(title: String, message: String) {
        
        // In-app notification
        // ✴️ Attribute:
        // GitHub: hyperoslo/Whisper
        //      https://github.com/hyperoslo/Whisper
        // Website: mrGott - Play System Sound Notification with AudtioToolbox in Swift 4
        //      http://mrgott.com/swift-programing/38-play-system-sound-notification-in-swift-4-using-audtiotoolbox
        
        let murmur = Murmur(title: title)
        Whisper.show(whistle: murmur, action: .show(5))
        
        let systemSoundId: SystemSoundID = 1016
        AudioServicesPlaySystemSound(systemSoundId)
    }
}
