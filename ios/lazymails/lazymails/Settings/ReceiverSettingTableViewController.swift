//
//  ReceiverSettingTableViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class ReceiverSettingTableViewController: UITableViewController {
    
    var receivers = [["firstname": "Yingchen", "lastname": "Liu", "title": "Mr"]]

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
            cell.nameLabel.text = "\(receiver["firstname"] as! String) \(receiver["lastname"] as! String)"
            
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
            receivers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            let controller = storyboard?.instantiateViewController(withIdentifier: "editReceiverTableViewController") as! EditReceiverTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
