//
//  EditReceiverTableViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class EditReceiverTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var titlePicker: UIPickerView!
    
    @IBOutlet weak var firstnameText: UITextField!
    
    @IBOutlet weak var lastnameText: UITextField!
    
    
    var receiver: Receiver?
    
    let titles = ["Mr", "Miss", "Mrs", "Ms", "Mx"]
    
    var isEdit = false
    
    var receiverSettingTableDelegate: ReceiverSettingTableDelegate?
    
    let data = Data.shared
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.titlePicker.delegate = self
        self.titlePicker.dataSource = self
        
        if !isEdit {
            // for adding
            disableRightButton()
        } else {
            // for editing
            titlePicker.selectRow(titles.index(of: receiver!.title)!, inComponent: 0, animated: false)
            firstnameText.text = receiver?.firstname
            lastnameText.text = receiver?.lastname
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return titles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return titles[row]
    }
    
    @IBAction func firstnameEditingChanged(_ sender: Any) {
        if firstnameText.text == "" {
            firstnameText.showError()
            disableRightButton()
        } else {
            firstnameText.hideError()
            enableRightButton()
        }
    }
    
    @IBAction func lastnameEditingChanged(_ sender: Any) {
        if lastnameText.text == "" {
            lastnameText.showError()
            disableRightButton()
        } else {
            lastnameText.hideError()
            enableRightButton()
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        if !isEdit {
            // For adding
            
            let uuid = UUID().uuidString
            let receiver = Receiver.insertNewObject(id: uuid, title: titles[titlePicker.selectedRow(inComponent: 0)], firstname: firstnameText.text!, lastname: lastnameText.text!)
                
            do {
                try data.save()
                receiverSettingTableDelegate?.addReceiver(receiver: receiver)
            } catch {
                if (error.localizedDescription.contains("NSConstraintConflict")) {
                    self.showError(message: "You already have a receiver with the same name.")
                } else {
                    self.showError(message: "Could not save receiver: \(error)")
                }
                return
            }
        } else {
            // For editing
            
            receiver?.title = titles[titlePicker.selectedRow(inComponent: 0)]
            receiver?.firstname = firstnameText.text!
            receiver?.lastname = lastnameText.text!
            
            receiverSettingTableDelegate?.editReceiver(receiver: receiver!)
            
            do {
                try data.save()
            } catch {
                self.showError(message: "Could not save receiver: \(error)")
                return
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
