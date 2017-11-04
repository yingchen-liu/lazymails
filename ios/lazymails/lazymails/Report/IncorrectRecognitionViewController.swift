//
//  IncorrectRecognitionViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class IncorrectRecognitionViewController: UITableViewController {

    @IBOutlet weak var checkboxImgView: UIImageView!
    
    @IBOutlet weak var submitButton: UIButton!
    
    
    var checked = false
    var currentMail: Mail?
    var mainContentDictionary : Dictionary<String, String> = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 5
        submitButton.backgroundColor = UIColor.lightGray
        
        let checkboxTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped(tapGestureRecognizer:)))
        checkboxImgView.isUserInteractionEnabled = true
        checkboxImgView.addGestureRecognizer(checkboxTapGestureRecognizer)
        self.submitButton.isEnabled = false
    }
    
    // report agreement checkbox
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return mainContentDictionary.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recognitionCell", for: indexPath) as! IncorrectRecognitionViewCell

        // Configure the cell...
        var keys = Array(mainContentDictionary.keys)
        cell.titleLabel.text = keys[indexPath.row]
        var values = Array(mainContentDictionary.values)
        cell.valueLabel.text = values[indexPath.row]
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // submit report button
    @IBAction func submitButtonTapped(_ sender: Any) {
        if checked {
            Socket.shared.sendReportRecognition(id: currentMail!.id)
        }
        navigationController?.popViewController(animated: true)
    }

}
