//
//  Socket.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import Whisper

class Socket: NSObject, StreamDelegate {
    
    static let shared = Socket()
    
//    let host = "localhost"
    let host = "socket.lazymails.com"
    
    let port = 6969
    
    let endSymbol = "[^END^]"
    
    var inputStream: InputStream!
    
    var outputStream: OutputStream!
    
    let maxReadLength = 65500
    
    var buffer = ""
    
    let data = DataManager.shared
    
    let setting = Setting.shared
    
    var responseCallback: ((_ error: String?, _ message: Dictionary<String, Any>) -> Void)?
    
    var liveCallback: ((_ error: String?, _ message: Dictionary<String, Any>) -> Void)?

    var registerCallback: ((_ error: String?, _ message: Dictionary<String, Any>) -> Void)?
    
    var loginCallback: ((_ error: String?, _ message: Dictionary<String, Any>) -> Void)?
    
    var requestIconCallback: ((_ error: String?, _ message: Dictionary<String, Any>) -> Void)?
    
    var mailCallbacks: [(_ mail: Mail) -> Void] = []
    
    var iconDownloadCallbacks: [() -> Void] = []
    
    var categoryName = ""
    
    var connected = false
    
    /**
     Connect to server
 
     */
    func connect() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host as CFString, UInt32(port), &readStream, &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: .main, forMode: .commonModes)
        outputStream.schedule(in: .main, forMode: .commonModes)
        
        inputStream.open()
        outputStream.open()
        
        if setting.inited {
            Socket.shared.sendConnectMessage(email: setting.email!, password: setting.password!, callback: { (error, message) in
                guard error == nil else {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    let alert = UIAlertController(title: "Login Error", message: "Cannot login to Lazy Mails: \(error!)", preferredStyle: .alert)
                    
                    let actionYes = UIAlertAction(title: "Login", style: .default, handler: { action in
                        let registerViewController = storyboard.instantiateViewController(withIdentifier: "registerViewController")
                        appDelegate.window?.rootViewController?.present(registerViewController, animated: true, completion: nil)
                    })
                    
                    alert.addAction(actionYes)
                    
                    DispatchQueue.main.async {
                        appDelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                    
                    return
                }
            })
        }
    }
    
    /**
     Reconnect to server
     
     */
    func reconnect() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) in
            self.connect()
            
            print("Cannot connect to server, reconnect after 3 seconds")
        })
    }
    
    /**
     Send user register message to server
     - Parameters:
         - email: User email address
         - password: User password
         - mailbox: User mailbox id
         - callback: the callback of receiving register results
     */
    func sendRegisterMessage(email: String, password: String, mailbox: String, callback: @escaping (_ error: String?, _ message: Dictionary<String, Any>) -> Void) {
        let message = ["end": "app", "type": "register", "email": email, "password": password, "mailbox": mailbox]
        
        registerCallback = callback
        
        sendMessage(message: message)
    }
    
    /**
     Send category icon message to server
     - Parameters:
         - category: Category name
         - callback: the callback of receiving category icon results
     */
    func sendCategoryIconMessage(category: String, callback: @escaping (_ error: String?, _ message: Dictionary<String, Any>) -> Void) {
        let message = ["end": "app", "type": "download_category_icon", "category": category]
        
        requestIconCallback = callback
        
        sendMessage(message: message)
    }
    
    /**
     Send login message to server
     - Parameters:
         - email: User email address
         - password: User password
         - callback: the callback of receiving login results
     */
    func sendConnectMessage(email: String, password: String, callback: @escaping (_ error: String?, _ message: Dictionary<String, Any>) -> Void) {
        print("Connecting with email \(email), password \(password)")
        let message = ["end": "app", "type": "connect", "email": email, "password": password]
        
        loginCallback = callback
        
        sendMessage(message: message)
    }
    
    /**
     Update the settings of mailbox to server
     - Parameters:
         - callback: the callback of receiving update mailbox results
     */
    func sendUpdateMailboxMessage(callback: @escaping (_ error: String?, _ message: Dictionary<String, Any>) -> Void) {
        var receivers: [Dictionary<String, String>] = []
        let _receivers = Receiver.fetchAll()
        for _receiver in _receivers {
            receivers.append(["title": _receiver.title, "firstname": _receiver.firstname, "lastname": _receiver.lastname])
        }
        
        let address = ["unit": setting.address?.unit, "number": setting.address?.streetNo, "road": setting.address?.streetName, "roadType": setting.address?.streetType, "suburb": setting.address?.suburb, "state": setting.address?.state, "postalCode": setting.address?.postalCode]
        
        let mailbox: Dictionary<String, Any> = ["names": receivers, "address": address, "settings": ["isEnergySavingOn": setting.isEnergySavingOn]]
        
        let message: Dictionary<String, Any> = ["end": "app", "type": "update_mailbox", "mailbox": mailbox]
        
        responseCallback = callback
        
        sendMessage(message: message)
    }
    
    /**
     Send download category icon message to server
     - Parameters:
         - categoryName: Category name
     */
    func sendDownloadIconMessage(categoryName: String) {
        let message = ["end": "app", "type": "download_category_icon", "category": categoryName]
        
        sendMessage(message: message)
    }
    
    /**
     Send mailbox live message to server
     - Parameters:
         - callback: the callback of receiving mailbox live results
     */
    func sendStartLiveMessage(callback: @escaping (_ error: String?, _ message: Dictionary<String, Any>) -> Void) {
        let message = ["end": "app", "type": "start_live"]
        
        liveCallback = callback
        
        sendMessage(message: message)
    }
    
    /**
     Send heartbeat message to live
     
     */
    func sendLiveHeartbeatMessage() {
        let message = ["end": "app", "type": "live_heartbeat"]
        
        sendMessage(message: message)
    }
    
    /**
     Send stop live message
     
     */
    func sendStopLiveMessage() {
        let message = ["end": "app", "type": "stop_live"]
        
        liveCallback = nil
        
        sendMessage(message: message)
    }
    
    /**
     Send check mails and receive the newest mail when app online
     
     */
    func sendCheckMails() {
        if let newestMail = DataManager.shared.fetchNewestMail() {
            //let after = convertDateToString(date: newestMail.receivedAt)
            let after = newestMail.receivedAt.toStringDate()
            print(after)
        
            print("Checking mails")
            let message = ["end": "app", "type": "check_mails", "after": after]
            
            sendMessage(message: message)
        }
    }
    
    /**
     Send report incorrect category message to server
     - Parameters:
         - id: the id of reported category
         - category: the name of reported category
     */
    func sendReportCategory(id: String, category: String) {
        let message = ["end": "app", "type": "report", "issueType": "category", "reportedCategory": category, "id": id]
        
        sendMessage(message: message)
    }
    
    /**
     Send report incorrect display of category photo message to server
     - Parameters:
         - id: the id of reported category
     */
    func sendReportPhoto(id: String) {
        let message = ["end": "app", "type": "report", "issueType": "photo", "id": id]
        
        sendMessage(message: message)
    }
    
    /**
     Send report incorrect reconition of category message to server
     - Parameters:
         - id: the id of reported category
     */
    func sendReportRecognition(id: String) {
        let message = ["end": "app", "type": "report", "issueType": "recognition", "id": id]
        
        sendMessage(message: message)
    }
    
    /**
     Send message request to server
     - Parameters:
         - message: the messages that wants to send
     */
    func sendMessage(message: Dictionary<String, Any>) {
        // ✴️ Attributes:
        // Websites: Convert Dictionary to JSON in Swift
        //  https://stackoverflow.com/questions/29625133/convert-dictionary-to-json-in-swift
        
        let jsonData = try? JSONSerialization.data(withJSONObject: message, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        
        let data = "\(jsonString)\(endSymbol)".data(using: .ascii)!
        _ = data.withUnsafeBytes {
            outputStream.write($0, maxLength: data.count)
        }
        
        print("sent message \(message["type"] as! String)")
    }
    
    /**
     Send close request to server
     
     */
    func close() {
        connected = false
        inputStream.close()
        outputStream.close()
    }
    
    /**
     Handle stream
     - Parameters:
         - aStream: Stream
         - eventCode: EventCode
     */
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            readBytes(stream: aStream as! InputStream)
            break
        case Stream.Event.endEncountered:
            print("disconnected")
            close()
            reconnect()
            break
        case Stream.Event.errorOccurred:
            print("error")
            close()
            reconnect()
            break
        default:
            print ("Unspecified event occured", eventCode)
            break
        }
    }
    
    /**
     ReadBytes
     - Parameters:
         - stream: Stream
     */
    func readBytes(stream: InputStream) {
        
        // ✴️ Attributes:
        // Websites: SwiftSocket: Can't send more than one TCP message
        //      https://stackoverflow.com/questions/42646159/swiftsocket-cant-send-more-than-one-tcp-message
        
        var buffer = Array<UInt8>(repeating: 0, count: maxReadLength)
        
        while (stream.hasBytesAvailable) {
            let bytesRead = inputStream.read(&buffer, maxLength: maxReadLength)
            
            if (bytesRead < 0) {
                if let _ = inputStream.streamError {
                    break
                }
            }
            
            let string = NSString(bytes: &buffer, length: bytesRead, encoding: String.Encoding.utf8.rawValue)
            if let string = string {
                self.buffer += string as String
            }
            
            if self.buffer.contains(endSymbol) {
                let strings = self.buffer.components(separatedBy: endSymbol)
                self.buffer = strings[strings.count - 1]
                for i in 0..<strings.count - 1 {
                    if let data = strings[i].data(using: .utf8) {
                        do {
                            let message = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary as! Dictionary<String, Any>
                            print("received message", message["type"] as! String)
                            processMessage(message: message)
                        } catch {
                            print("Error occurs when parsing json", error)
                        }
                    }
                }
            }
        }
    }
    
    /**
     Process login result message from server
     - Parameters:
         - message: Login result message
     */
    func processConnectMessage(message: Dictionary<String, Any>) {
        let _receivers = Receiver.fetchAll()
        for _receiver in _receivers {
            data.delete(object: _receiver)
        }
        
        //print(message)
        
        let mailbox = message["mailbox"] as! NSDictionary as! Dictionary<String, Any>
        let receivers = mailbox["names"] as! NSArray as! Array<NSDictionary>
        for receiver in receivers {
            let uuid = UUID().uuidString
            let title = receiver["title"] as! String
            let firstname = receiver["firstname"] as! String
            let lastname = receiver["lastname"] as! String
            
            let _ = Receiver.insertNewObject(id: uuid, title: title, firstname: firstname, lastname: lastname)
        }
        
        do {
            try data.save()
        } catch {
            if (error.localizedDescription.contains("NSConstraintConflict")) {
                fatalError("You already have a receiver with the same name.")
            } else {
                fatalError("Could not save receiver: \(error)")
            }
            return
        }
        
        
        let addressObject = mailbox["address"] as! NSDictionary as! Dictionary<String, Any>
        let addressUnit = addressObject["unit"] is NSNull ? nil : addressObject["unit"] as? String
        let addressStreetNo = addressObject["number"] as! String
        let addressStreetName = addressObject["road"] as! String
        let addressStreetType = addressObject["roadType"] as! String
        let addressSuburb = addressObject["suburb"] as! String
        let addressState = addressObject["state"] as! String
        let addressPostalCode = addressObject["postalCode"] as! String
        
        let address = Address(unit: addressUnit, streetNo: addressStreetNo, streetName: addressStreetName, streetType: addressStreetType, suburb: addressSuburb, state: addressState, postalCode: addressPostalCode)
        
        setting.address = address
        
        
        let settings = mailbox["settings"] as! NSDictionary as! Dictionary<String, Any>
        let isEnergySavingOn = settings["isEnergySavingOn"] as! Bool
        
        setting.isEnergySavingOn = isEnergySavingOn
        
        setting.save()
        
        connected = true
    }
    
    /**
     get error message from server
     - Parameters:
         - message: server error result message
     - Returns: error message
     */
    func getErrorMessage(message: Dictionary<String, Any>) -> String? {
        var errorMessage: String?
        if let error = message["error"] {
            let errorObject = error as! NSDictionary as! Dictionary<String, Any>
            errorMessage = errorObject["message"] as? String
        }
        return errorMessage
    }
    
    /**
     process message result from server
     - Parameters:
         - message: server response message
     */
    func processMessage(message: Dictionary<String, Any>) {
        switch message["type"] as! String {
        // process register result
        case "register":
            if let registerCallback = registerCallback {
                registerCallback(getErrorMessage(message: message), message)
            }
            break
        // process login result
        case "connect":
            let error = getErrorMessage(message: message)
            guard error == nil else {
                if let loginCallback = loginCallback {
                    loginCallback(error, message)
                }
                return
            }
            
            processConnectMessage(message: message)
            if let loginCallback = loginCallback {
                loginCallback(nil, message)
            }
            
            sendCheckMails()
            break
        // process update mailbox result
        case "update_mailbox":
            if let responseCallback = responseCallback {
                responseCallback(getErrorMessage(message: message), message)
            }
            break
        
        case "mailbox_online":
            print("Your mailbox is now online")
            break
        case "mailbox_offline":
            print("Your mailbox goes offline just now")
            break
        //process check mails result
        case "check_mails":
            print("Found unreceived mails")
            let mails = message["mails"] as! NSArray as! Array<NSDictionary>
            print(mails.count)
            break
        // process mail result
        case "mail":
            print("You have received a mail just now")
            let mail = message["mail"] as! NSDictionary as! Dictionary<String, Any>
            //get mail photo data
            let mailContent = mail["content"] as! String
            let mailbox = message["mailbox"] as! NSDictionary as! Dictionary<String, Any>
            //get mailbox photo data
            let mailboxContent = mailbox["content"] as! String
            
            // get information of mail
            let infoDic = message["info"] as! NSDictionary as! Dictionary<String, Any>
            
            // get mail id
            let mailId = infoDic["_id"] as! String
            
            // get title
            var title = ""
            let titleArray = infoDic["titles"] as! NSArray as! Array<NSDictionary>
            if let titleDict = titleArray.first {
                title = titleDict["name"] as! String
            }
            // get receive date
            let receivedAtStr = infoDic["mailboxReceivedAt"] as! String
            print ("receivedAtStr : \(receivedAtStr) " )
            let receivedAt = receivedAtStr.toDate()
            
            //let receivedAt = convertStringToDate(str: receivedAtStr)
            print ("receivedAt :\(receivedAt)")
            
            // get main text
            var wholeText = ""
            var text = ""
            let mainTextArray = infoDic["mainText"] as! NSArray as! Array<NSDictionary>
            if mainTextArray.count != 0 {
                for i in 0...mainTextArray.count - 1 {
                    let eachTextDic = mainTextArray[i] as! Dictionary<String, Any>
                    text = eachTextDic["text"] as! String
                    //print("maintext\(i) : \(text) " )
                    wholeText = wholeText + text
                }
            }
            
            // get from
            let poPox = nullToNil(value: infoDic["poBox"] as AnyObject)
            var from = ""
            if poPox != nil {
                from = poPox as! String
            }
            
            // get to
            let receiver = nullToNil(value: infoDic["receiver"] as AnyObject)
            var to = ""
            if receiver != nil {
                to = receiver as! String
            }
            
            // get mail info
            let mailInfo = infoDic["text"] as! String
            
            // get url
            var urls = infoDic["urls"] as! NSArray as! Array<String>
            var website = ""
            if urls.count > 1 {
                
                for i in 0...urls.count - 1 {
                    let url = urls[i] as String
                    website = website + "\n" + url
                }
                website.remove(at: website.startIndex)
            }else if urls.count == 1 {
                website = urls[0] as String
            }
            else  {
                website = ""
            }
            
            //get category name
            let categoriesDic = infoDic["categories"] as! NSArray as! Array<NSDictionary>
            
            if categoriesDic.count != 0 {
                let category = categoriesDic[0] as! NSDictionary as! Dictionary<String, Any>
                categoryName = category["name"] as! String
            }
            
            // store from, to, wholetext, website to info
            let jsonObj = ["From": from, "To" : to, "Text": wholeText, "Website": website]
            let jsonData = try! JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions())
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            let info = jsonString
            
            // notification
            data.fetchCategories()
            
            Notification.shared.monitorMail(categoryName: categoryName, mailTitle: title)
            
            
            
            
            // insert new Mail
            let newMail = insertNewMail(id: mailId, title: title, mainText: wholeText, info: info, receivedAt: receivedAt, image: mailContent, boxImage: mailboxContent)
            // add new Mail to category
            addMailToCategory(mail: newMail)
            
            if !DataManager.shared.categoryList.contains(newMail.category) {
                DataManager.shared.categoryList.append(newMail.category)
            }
            
            do {
                try DataManager.shared.save()
            } catch {
                let saveError = error as NSError
                print("Can not save data : \(saveError)")
            }

            
            if newMail.category.icon == "" {

                sendDownloadIconMessage(categoryName: categoryName)
            }
            
            for callback in mailCallbacks {
                callback(newMail)
            }
            
            break
        // process live result message
        case "live":
            if let liveCallback = liveCallback {
                liveCallback(getErrorMessage(message: message), message)
            }
            break
        // process download category icon result message
        case "download_category_icon":
            
            if let error = getErrorMessage(message: message) {
                print(error)
                break
            }
            
            // get category name from server
            let categoryName = message["category"] as! String
            let icon = message["content"] as! String
            
            // save icon data into Core Data
            if let category = DataManager.shared.fetchCategoryByName(name: categoryName).first {
                category.icon = icon
                
                do {
                    try DataManager.shared.save()
                } catch {
                    let saveError = error as NSError
                    print("Can not save data : \(saveError)")
                }
            }
            
            for callback in iconDownloadCallbacks {
                callback()
            }
            break
        default:
            break
        }
    }
    
    /**
     Insert new mail into core data
     - Parameters:
         - id: mail id
         - title: mail title
         - mainText: mail main text
         - info: mail detailed information
         - receivedAt: mail receive date
         - image: mail photo
         - boxImage: mailbox photo
     - Returns: Mail
     */
    func insertNewMail(id: String, title: String, mainText: String, info: String, receivedAt: Date, image: String, boxImage: String) -> Mail {
        let mail = Mail.insertNewObject(id: id, title: title, mainText: mainText, info: info, didRead: false, isImportant: false, receivedAt: receivedAt, image: image, boxImage: boxImage, showFullImage: false)
        return mail
    }
    
    /**
     Add mail into category
     - Parameters:
         - mail: Mail
     */
    func addMailToCategory(mail : Mail){
        let uuid = NSUUID().uuidString
        if categoryName != "" {
            let category = DataManager.shared.fetchCategoryByName(name: categoryName)
            
            if category.count == 0 {
                print(uuid)
                let newCategory = Category.insertNewObject(id: uuid, name: categoryName, icon: "")
                newCategory.addToMail(mail)
            }else {
                category[0].addToMail(mail)
            }
        }
    }
    
    /**
     Convert null to nil
     - Parameters:
         - value: AnyObject
     - Returns: value
     */
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return nil
        } else {
            return value
        }
    }
    
    
}
