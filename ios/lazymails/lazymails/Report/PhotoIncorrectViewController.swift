//
//  PhotoIncorrectViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class PhotoIncorrectViewController: UITableViewController {

    @IBOutlet weak var checkboxImgView: UIImageView!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var fullImageView: UIImageView!
    
    var checked = false
    var currentMail : Mail?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 5
        submitButton.backgroundColor = UIColor.lightGray
        
        let checkboxTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped(tapGestureRecognizer:)))
        checkboxImgView.isUserInteractionEnabled = true
        checkboxImgView.addGestureRecognizer(checkboxTapGestureRecognizer)
        
        if let data = Data(base64Encoded: (currentMail?.boxImage)!, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: data)
            self.fullImageView.image = image
        }
        self.submitButton.isEnabled = false
        
        
    }
    
    @objc func checkboxTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        checked = !checked
        checkboxImgView.image = UIImage(named: checked ? "checkbox-checked-small" : "checkbox-small")
        submitButton.backgroundColor = checked ? UIColor(red: 1, green: 102.0/255, blue: 82.0/255, alpha: 1) : UIColor.lightGray
        if checked {
            self.submitButton.isEnabled = true
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        Socket.shared.sendReportPhoto(id: currentMail!.id)
        navigationController?.popViewController(animated: true)
    }

}
