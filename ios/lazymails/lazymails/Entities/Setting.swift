//
//  Setting.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

//
//  Setting.swift
//  raspberry-and-sensors
//
//  Created by YINGCHEN LIU on 14/9/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit


/**
 Setting, for storing user settings
 */
class Setting: NSObject {
    
    static let shared = Setting()
    
    let keys = (inited: "inited", email: "email", password: "password", mailbox: "mailbox", addressUnit: "addressUnit", addressStreetNo: "addressStreetNo", addressStreetName: "addressStreetName", addressStreetType: "addressStreetType", addressSuburb: "addressSuburb", addressState: "addressState", addressPostalCode: "addressPostalCode", isEnergySavingOn: "isEnergySavingOn")
    
    let preferences = UserDefaults.standard
    
    var inited = false
    
    var address: Address?
    
    var email: String?
    
    var password: String?
    
    var mailbox: String?
    
    var isEnergySavingOn = false
    
    
    override init() {
        super.init()
        
        if preferences.object(forKey: keys.inited) == nil {
            // first time, init default settings
            preferences.set(true, forKey: keys.inited)
            
            inited = false
            address = Address(unit: "11", streetNo: "919", streetName: "Dandenong", streetType: "Road", suburb: "Malvern East", state: "VIC", postalCode: "3145")
            isEnergySavingOn = false
            
            self.save()
        } else {
            // otherwise, retrieve settings
            inited = preferences.bool(forKey: keys.inited)
            
            email = preferences.string(forKey: keys.email)
            mailbox = preferences.string(forKey: keys.mailbox)
            password = preferences.string(forKey: keys.password)
            
            let addressUnit = preferences.string(forKey: keys.addressUnit)
            let addressStreetNo = preferences.string(forKey: keys.addressStreetNo)!
            let addressStreetName = preferences.string(forKey: keys.addressStreetName)!
            let addressStreetType = preferences.string(forKey: keys.addressStreetType)!
            let addressSuburb = preferences.string(forKey: keys.addressSuburb)!
            let addressState = preferences.string(forKey: keys.addressState)!
            let addressPostalCode = preferences.string(forKey: keys.addressPostalCode)!
            address = Address(unit: addressUnit, streetNo: addressStreetNo, streetName: addressStreetName, streetType: addressStreetType, suburb: addressSuburb, state: addressState, postalCode: addressPostalCode)
            
            isEnergySavingOn = preferences.bool(forKey: keys.isEnergySavingOn)
        }
    }
    
    
    /**
     Persistent the settings
     */
    func save() {
        preferences.set(inited, forKey: keys.inited)
        
        preferences.set(email, forKey: keys.email)
        preferences.set(mailbox, forKey: keys.mailbox)
        preferences.set(password, forKey: keys.password)
        
        preferences.set(address?.unit, forKey: keys.addressUnit)
        preferences.set(address?.streetNo, forKey: keys.addressStreetNo)
        preferences.set(address?.streetName, forKey: keys.addressStreetName)
        preferences.set(address?.streetType, forKey: keys.addressStreetType)
        preferences.set(address?.suburb, forKey: keys.addressSuburb)
        preferences.set(address?.state, forKey: keys.addressState)
        preferences.set(address?.postalCode, forKey: keys.addressPostalCode)
        
        preferences.set(isEnergySavingOn, forKey: keys.isEnergySavingOn)
        
        let didSave = preferences.synchronize()
        
        if !didSave {
            fatalError("Could not save the settings")
        }
    }
    
    
    
}

