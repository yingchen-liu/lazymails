//
//  StringExtension.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 4/11/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

extension String{
    /**
     Convert string to date
     - Returns: date
     */
    func toDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from:self)
        return date!
    }
}
