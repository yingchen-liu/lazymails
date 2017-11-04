//
//  DateExtension.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 4/11/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

extension Date{
    /**
     Convert date to string date
     - Returns: String date
     */
    func toStringDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from:self)
    }
}
