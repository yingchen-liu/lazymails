//
//  ArrayExtension.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 22/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

//      https://stackoverflow.com/questions/28288148/making-my-function-calculate-average-of-array-swift

extension Array where Element == Double {
    
    var average: Double {
        return isEmpty ? 0 : Double(reduce(0, +)) / Double(count)
    }
}
