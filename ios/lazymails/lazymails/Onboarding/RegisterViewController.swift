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
    
    @IBOutlet weak var mailboxIdLabel: UILabel!
    
    @IBOutlet weak var scanCodeButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var registerButton: UIButton!
    
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

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
        
    }
    
    func removeTextfieldBorder(textfield : UITextField) {
        textfield.layer.borderWidth = 0
    }
    func addTextfieldBorder(textfield : UITextField) {
        textfield.layer.borderColor = UIColor(red: 255/255, green: 102/255, blue: 82/255, alpha: 1).cgColor
        textfield.layer.borderWidth = 1.0
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        self.reset()
        
        (sender as! UIButton).backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        (sender as! UIButton).setTitleColor(UIColor.white, for:.normal)
        
        self.registerButton.setTitleColor(UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1), for: .normal)
        self.registerButton.backgroundColor = UIColor.white
        
        
        self.mailboxIdLabel.isHidden = true
        self.mailboxIdErrorLabel.isHidden = true
        self.mailboxIdField.isHidden = true
        self.scanCodeButton.isHidden = true
        self.nextButton.setTitle("Login", for: .normal)
        
        self.validator.unregisterField(mailboxIdField)
        
    }
    
    func reset() {
        self.emailErrorLabel.text = ""
        self.psdErrorLabel.text = ""
        self.mailboxIdErrorLabel.text = ""
        removeTextfieldBorder(textfield: emailField)
        removeTextfieldBorder(textfield: passwordField)
        removeTextfieldBorder(textfield: mailboxIdField)
        self.nextButton.backgroundColor = UIColor(red: 122/255, green: 195/255, blue: 246/255, alpha: 1)
    }
    
    func login() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let email = emailField.text
        let password = passwordField.text

        socket.sendConnectMessage(email: email!, password: password!, callback: { (error, message) in
            guard error == nil else {
                print("login error: \(error!)")
                self.psdErrorLabel.text = "Incorrect Email or Password"
                self.addTextfieldBorder(textfield: self.emailField)
                self.addTextfieldBorder(textfield: self.passwordField)
                
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
    
    func register () {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let email = emailField.text
        let password = passwordField.text
        let mailboxId = mailboxIdField.text
        socket.sendRegisterMessage(email: email!, password: password!, mailbox: mailboxId!, callback: { (error, message) in
            guard error == nil else {
                print("register: \(error!)")
                if (error?.contains ("Incorrect mailbox ID"))! {
                    self.mailboxIdErrorLabel.text = "Incorrect mailbox ID."
                }
                if (error?.contains ("Email already exists"))! {
                    self.emailErrorLabel.text = "Email address Exist."
                }
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
            
//            print("registered!")
        })
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        self.reset()
        (sender as! UIButton).backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        (sender as! UIButton).setTitleColor(UIColor.white, for:.normal)
        
        self.loginButton.setTitleColor(UIColor(red: 0/255,green: 122/255, blue: 255/255, alpha: 1), for: .normal)
        self.loginButton.backgroundColor = UIColor.white
        self.mailboxIdLabel.isHidden = false
        self.mailboxIdErrorLabel.isHidden = false
        self.mailboxIdField.isHidden = false
        self.scanCodeButton.isHidden = false
        self.nextButton.setTitle("Register", for: .normal)
        self.validator.registerField(mailboxIdField,errorLabel: mailboxIdErrorLabel, rules: [MinLengthRule(length: 24, message: "ID should be 24 digits")])
        
    }
    
    
    func validationSuccessful() {
        //self.nextButton.isEnabled = true
        reset()
        
        if nextButton.currentTitle == "Login" {
            login()
        } else {
            register()
        }
        return
    }
    
    @IBAction func idInputChanged(_ sender: Any) {
        self.mailboxIdErrorLabel.text = ""
        validator.validate(self)
        if (sender as! UITextField).text != "" {
            self.validator.registerField(mailboxIdField,errorLabel: mailboxIdErrorLabel, rules: [MinLengthRule(length: 24, message: "ID should be 24 digits")])
        } else {
            self.validator.unregisterField(mailboxIdField)
        }
    }
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        reset()
        for (field, error) in errors {
            print(field, error)
            if let field = field as? UITextField {
                addTextfieldBorder(textfield: field)
            }
            
            if let label = error.errorLabel {
                label.text = error.errorMessage
                label.isHidden = false
            }
        }
        
    }
    
    /**
     Init validation
     */
    func initValidation() {
        self.validator.registerField(emailField, errorLabel: emailErrorLabel , rules: [RequiredRule(message: "Please enter your Email!"),EmailRule(message: "Invalid email")])
        
        self.validator.registerField(passwordField,errorLabel: psdErrorLabel, rules: [RequiredRule(message: "Please enter your password!"),MinLengthRule(length: 6,message: "Should be more than 6 digits")])
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        validator.validate(self)
    }
    
    
}
