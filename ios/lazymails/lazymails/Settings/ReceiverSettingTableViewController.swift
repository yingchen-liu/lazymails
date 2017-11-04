//
//  ReceiverSettingTableViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

protocol ReceiverSettingTableDelegate {

    func addReceiver(receiver: Receiver)

    func editReceiver(receiver: Receiver)
    
}

class ReceiverSettingTableViewController: UITableViewController, ReceiverSettingTableDelegate {
    
    var receiverEditIndexPath: IndexPath?
    
    var receivers: [Receiver] = []
    
    var settingTableDelegate: SettingTableDelegate?
    
    let data = DataManager.shared
    
    let socket = Socket.shared
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
//        tableView.allowsSelectionDuringEditing = true
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
        return receivers.count + (isEditing ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "receiverCell", for: indexPath) as! ReceiverSettingTableViewCell
        
        if indexPath.row < receivers.count {
            let receiver = receivers[indexPath.row]
            cell.nameLabel.text = "\(receiver.firstname) \(receiver.lastname)"
            
            cell.editButton.isHidden = !isEditing
        } else {
            cell.nameLabel.text = "Add Receiver"
            cell.editButton.isHidden = true
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        let indexPath = IndexPath(row: receivers.count, section: 0)
            if indexPath.row < tableView.numberOfRows(inSection: 0) {
            if editing {
                tableView.insertRows(at: [indexPath], with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        // Update the view so that it can toggle the edit button
        tableView.reloadData()
    }
    
    // ✴️ Attributes:
    // Website: Insert Table Row
    // http://www.ryanwright.me/cookbook/ios/objc/uitableview/add-table-row
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if isEditing {
            if indexPath.row < receivers.count {
                return .delete
            } else {
                return .insert
            }
        } else {
            return .none
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.data.delete(object: self.receivers[indexPath.row])
            do {
                try self.data.save()
            } catch {
                self.showError(message: "Could not save receiver: \(error)")
                return
            }
            
            self.settingTableDelegate?.deleteReceiver(receiver: self.receivers[indexPath.row])
            self.receivers.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
            socket.sendUpdateMailboxMessage { (error, message) in
                guard error == nil else {
                    self.showError(message: "Error occurs when updating mailbox setting to server: \(error!)")
                    return
                }
            }
        } else if editingStyle == .insert {
            let controller = storyboard?.instantiateViewController(withIdentifier: "editReceiverTableViewController") as! EditReceiverTableViewController
            
            controller.isEdit = false
            controller.receiverSettingTableDelegate = self
            
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editReceiverSegue" {
            let button = sender
            let cell = (button as AnyObject).superview?!.superview! as! ReceiverSettingTableViewCell
            receiverEditIndexPath = tableView.indexPath(for: cell)
            
            let controller = segue.destination as! EditReceiverTableViewController
            
            controller.isEdit = true
            controller.receiver = receivers[receiverEditIndexPath!.row]
            controller.receiverSettingTableDelegate = self
        }
    }
    
    /**
     Add new receiver to tableview
     - Parameters:
         - receiver: Receiver
     */
    func addReceiver(receiver: Receiver) {
        receivers.append(receiver)
        tableView.reloadData()
        settingTableDelegate?.addReceiver(receiver: receiver)
    }
    
    /**
     Edit new receiver
     - Parameters:
         - receiver: Receiver
     */
    func editReceiver(receiver: Receiver) {
        tableView.reloadData()
        settingTableDelegate?.editReceiver(receiver: receiver)
    }
    

}
