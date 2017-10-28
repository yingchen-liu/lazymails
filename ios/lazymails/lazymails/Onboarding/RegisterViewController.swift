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
import SwiftValidator


class RegisterViewController: UIViewController, QRCodeReaderViewControllerDelegate, ValidationDelegate {
    
    
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var mailboxIdField: UITextField!
    
    @IBOutlet weak var emailErrorLabel: UILabel!
    
    @IBOutlet weak var psdErrorLabel: UILabel!
    
    @IBOutlet weak var mailboxIdErrorLabel: UILabel!
    
    let socket = Socket.shared
    
    let setting = Setting.shared
    
    let validator = Validator()
    
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        //  https://stackoverflow.com/questions/5711434/how-can-i-dismiss-the-keyboard-if-a-user-taps-off-the-on-screen-keyboard
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        
        self.view.addGestureRecognizer(tap)
        
        // validate input user name and psd
        initValidation()
        self.emailErrorLabel.text = ""
        self.psdErrorLabel.text = ""
        self.mailboxIdErrorLabel.text = ""
        mailboxIdField.isUserInteractionEnabled = false
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
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
        validator.validate(self)
        self.emailErrorLabel.text = ""
        self.psdErrorLabel.text = ""
        self.mailboxIdErrorLabel.text = ""
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let email = emailField.text
        let password = passwordField.text
        let mailboxId = mailboxIdField.text
        
        if mailboxId == "" {
            // Login
            if email != "" && password != "" {
                socket.sendConnectMessage(email: email!, password: password!, callback: { (error, message) in
                    guard error == nil else {
                        print("login error: \(error!)")
                        self.psdErrorLabel.text = "Incorrect Email or Password"
                        return
                    }
                    
                    self.setting.inited = true
                    self.setting.email = email
                    self.setting.password = password
                    self.setting.save()
                    
                    let mainBarViewController = storyboard.instantiateViewController(withIdentifier: "mainTabBarController")
                    self.present(mainBarViewController, animated: true, completion: nil)
                })
            }
            
        } else {
            // Register
            
            socket.sendRegisterMessage(email: email!, password: password!, mailbox: mailboxId!, callback: { (error, message) in
                guard error == nil else {
                    print("register: \(error!)")
                    self.emailErrorLabel.text = "Email already exists."
                    return
                }
                
                self.setting.inited = true
                self.setting.email = email
                self.setting.password = password
                self.setting.mailbox = mailboxId
                self.setting.save()
                
                self.socket.sendConnectMessage(email: email!, password: password!, callback: { (error, message) in
                    guard error == nil else {
                        print("connect: \(error!)")
                        return
                    }
                    
                    let mainBarViewController = storyboard.instantiateViewController(withIdentifier: "mainTabBarController")
                    self.present(mainBarViewController, animated: true, completion: nil)
                })
                
                print("registered!")
            })
        }
    }
    
    
    func validationSuccessful() {
        return
    }
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        var i = 0
        for (field, error) in errors {
            if let field = field as? UITextField {
                
                field.layer.borderColor = UIColor(red: 255/255, green: 102/255, blue: 82/255, alpha: 1).cgColor
                field.layer.borderWidth = 1.0
            }
            
            if let label = error.errorLabel {
                // scroll to the first error
                
                
                label.text = error.errorMessage
                label.isHidden = false
            }
            
            i = i + 1
        }
    }
    
    /**
     Init validation
     */
    func initValidation() {
        self.validator.registerField(emailField, errorLabel: emailErrorLabel , rules: [RequiredRule(message: "Please enter your Email!")])
        
        self.validator.registerField(passwordField,errorLabel: psdErrorLabel, rules: [RequiredRule(message: "Please enter your password!")])
        
//        self.validator.registerField(mailboxIdField,errorLabel: mailboxIdErrorLabel, rules: [RequiredRule(message: "error?")])
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        validator.validate(self)
    }
    
    
}
