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
    
    func convertDateToString() -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        //print ("dateeeeeeeee is \(date)")
        let str = formatter.string(from: self)
        //        print ("\(str)")
        return str
    }
    
    func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyy-MM-dd"
        //print ("dateeeeeeeee is \(date)")
        let str = formatter.string(from: self)
        //        print ("\(str)")
        return str
    }
    
    func formatDateAndTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "HH:mm"
        //print ("dateeeeeeeee is \(date)")
        let str = formatter.string(from: self)
        //        print ("\(str)")
        return str
    }
    
}
