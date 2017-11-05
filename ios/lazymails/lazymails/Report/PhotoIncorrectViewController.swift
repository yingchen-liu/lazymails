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
    
    @IBOutlet weak var agreementLabel: UILabel!
    
    
    var checked = false
    
    var currentMail : Mail?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 5
        
        let checkboxTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped(tapGestureRecognizer:)))
        checkboxImgView.isUserInteractionEnabled = true
        checkboxImgView.addGestureRecognizer(checkboxTapGestureRecognizer)
        
        let agreementLabelTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped(tapGestureRecognizer:)))
        agreementLabel.isUserInteractionEnabled = true
        agreementLabel.addGestureRecognizer(agreementLabelTapGestureRecognizer)
        
        if let data = Data(base64Encoded: (currentMail?.boxImage)!, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: data)
            self.fullImageView.image = image
        }
    }
    
    // report agreement checkbox 
    @objc func checkboxTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        checked = !checked
        checkboxImgView.image = UIImage(named: checked ? "checkbox-checked-small" : "checkbox-small")
        submitButton.setTitle((checked ? "Show Original and Report" : "Show Original"), for: .normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        currentMail?.showFullImage = true
        
        do {
            try DataManager.shared.save()
        } catch {
            self.showError(message: "Could not save: \(error)")
            return
        }
        
        if checked {
            Socket.shared.sendReportPhoto(id: currentMail!.id)
        }
            
        navigationController?.popViewController(animated: true)
        navigationController?.popViewController(animated: true)
    }

}
