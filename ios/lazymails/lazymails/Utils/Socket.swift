//
//  Socket.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class Socket: NSObject, StreamDelegate {
    
    static let shared = Socket()
    
    let host = "localhost"
    
    let port = 6969
    
    let endSymbol = "[^END^]"
    
    var inputStream: InputStream!
    
    var outputStream: OutputStream!
    
    let maxReadLength = 1024
    
    var buffer = ""
    
    let data = Data.shared
    
    let setting = Setting.shared
    
    var responseCallback: ((_ error: String?, _ message: Dictionary<String, Any>) -> Void)?

    
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
        
        sendConnectMessage()
    }
    
    func reconnect() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) in
            self.connect()
            
            print("Cannot connect to server, reconnect after 3 seconds")
        })
    }
    
    func sendConnectMessage() {
        let message = ["end": "app", "type": "connect", "email": "ytxiuxiu@gmail.com", "password": "123456"]
        sendMessage(message: message)
    }
    
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
    
    func sendStartLiveMessage() {
        let message = ["end": "app", "type": "start_live"]
        sendMessage(message: message)
    }
    
    func sendMessage(message: Dictionary<String, Any>) {
        
        //  https://stackoverflow.com/questions/29625133/convert-dictionary-to-json-in-swift
        
        let jsonData = try? JSONSerialization.data(withJSONObject: message, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        
        let data = "\(jsonString)\(endSymbol)".data(using: .ascii)!
        _ = data.withUnsafeBytes {
            outputStream.write($0, maxLength: data.count)
        }
    }
    
    func close() {
        inputStream.close()
        outputStream.close()
    }
    
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
    
    func readBytes(stream: InputStream) {
        
        //  In order to receive long messages,
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
    
    func processConnectMessage(message: Dictionary<String, Any>) {
        let _receivers = Receiver.fetchAll()
        for _receiver in _receivers {
            data.delete(object: _receiver)
        }
        
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
    }
    
    func processMessage(message: Dictionary<String, Any>) {
        switch message["type"] as! String {
        case "connect":
            processConnectMessage(message: message)
            break
        case "update_mailbox":
            if let responseCallback = responseCallback {
                var errorMessage: String?
                if let error = message["error"] {
                    let errorObject = error as! NSDictionary as! Dictionary<String, Any>
                    errorMessage = errorObject["message"] as? String
                }
                responseCallback(errorMessage, message)
            }
            break
        case "mailbox_online":
            print("Your mailbox is now online")
            break
        case "mailbox_offline":
            print("Your mailbox goes offline just now")
            break
        case "mail":
            print("You have received a mail just now")
            break
        default:
            print("Unknown message type")
        }
    }

}
