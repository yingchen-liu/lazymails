//
//  RegisterViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 22/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

//  https://github.com/yannickl/QRCodeReader.swift

import UIKit
import AVFoundation
import QRCodeReader

class RegisterViewController: UIViewController, QRCodeReaderViewControllerDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var mailboxIdField: UITextField!
    
    
    let socket = Socket.shared
    
    let setting = Setting.shared
    
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func scanButtonTapped(_ sender: Any) {
        readerVC.delegate = self
        
        // Or by using the closure pattern
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            self.mailboxIdField.text = result?.value
        }
        
        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    // MARK: - QRCodeReaderViewController Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let email = emailField.text
        let password = passwordField.text
        let mailboxId = mailboxIdField.text
        
        if mailboxId == "" {
            // Login
            
            socket.sendConnectMessage(email: email!, password: password!, callback: { (error, message) in
                guard error == nil else {
                    print(error!)
                    return
                }
            
                self.setting.inited = true
                self.setting.email = email
                self.setting.password = password
                self.setting.save()
                
                let mainBarViewController = storyboard.instantiateViewController(withIdentifier: "mainTabBarController")
                self.present(mainBarViewController, animated: true, completion: nil)
            })
        } else {
            // Register
            
            socket.sendRegisterMessage(email: email!, password: password!, mailbox: mailboxId!, callback: { (error, message) in
                guard error == nil else {
                    print(error!)
                    return
                }
                
                self.setting.inited = true
                self.setting.email = email
                self.setting.password = password
                self.setting.mailbox = mailboxId
                self.setting.save()
                
                self.socket.sendConnectMessage(email: email!, password: password!, callback: { (error, message) in
                    
                    let mainBarViewController = storyboard.instantiateViewController(withIdentifier: "mainTabBarController")
                    self.present(mainBarViewController, animated: true, completion: nil)
                })
                
                print("registered!")
            })
        }
    }
    
}
