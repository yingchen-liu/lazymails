//
//  Address.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class Address: NSObject {

    var unit: String?
    
    var streetNo: String
    
    var streetName: String
    
    var streetType: String
    
    var suburb: String
    
    var state: String
    
    var postalCode: String
    
    init(unit: String?, streetNo: String, streetName: String, streetType: String, suburb: String, state: String, postalCode: String) {
        self.unit = unit
        self.streetNo = streetNo
        self.streetName = streetName
        self.streetType = streetType
        self.suburb = suburb
        self.state = state
        self.postalCode = postalCode
    }
    
}
