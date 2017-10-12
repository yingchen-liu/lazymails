//
//  UITextFieldExtension.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

extension UITextField {
    
    /**
     Show error for the text field
     */
    func showError() {
        
        // ✴️ Attributes:
        // StackOverflow: ios - How set swift 3 UITextField border color ? - Stack Overflow
        //      https://stackoverflow.com/questions/38460327/how-set-swift-3-uitextfield-border-color
        
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.cornerRadius = 3.0
        self.layer.borderWidth = 1.0
    }
    
    /**
     Hide error for the text field
     */
    func hideError() {
        self.layer.borderWidth = 0.0
    }
    
}

