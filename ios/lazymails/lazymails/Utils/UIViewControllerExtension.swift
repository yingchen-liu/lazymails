//
//  UIViewControllerExtension.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /**
     Disable the back button
     */
    func disableRightButton() {
        
        // ✴️ Attributes:
        // StackOverflow: ios - How to disable back button in navigation bar - Stack Overflow
        //      https://stackoverflow.com/questions/32010429/how-to-disable-back-button-in-navigation-bar
        
        //      https://stackoverflow.com/questions/25362050/how-to-disable-a-navigation-bar-button-item-in-ios
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.tintColor = .lightGray
    }
    
    /**
     Enable the back button
     */
    func enableRightButton() {
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.tintColor = .blue
    }
    
    
    func showError(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            alertController.dismiss(animated: true, completion: nil)
        })
        
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}
