//
//  SettingTableViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

protocol SettingTableDelegate {
    
    func addReceiver(receiver: Receiver)
    
    func editReceiver(receiver: Receiver)
    
    func deleteReceiver(receiver: Receiver)
    
    func editAddress(address: Address)
    
    func editEnergySaving()
    
}

class SettingTableViewController: UITableViewController, SettingTableDelegate {
    
    @IBOutlet weak var addressLine1Label: UILabel!
    
    @IBOutlet weak var addressLine2Label: UILabel!
    
    @IBOutlet weak var receiver1Label: UILabel!
    
    @IBOutlet weak var receiver2Label: UILabel!
    
    @IBOutlet weak var receiverMoreLabel: UILabel!
    
    @IBOutlet weak var energySavingStatusLabel: UILabel!
    
    
    var receivers: [Receiver] = []
    
    var address: Address?
    
    let setting = Setting.shared
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        receivers = Receiver.fetchAll()
        showReceivers()
        showAddress()
        showEnergySaving()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source


    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReceiverSettingSegue" {
            let controller = segue.destination as! ReceiverSettingTableViewController
            
            controller.settingTableDelegate = self
            controller.receivers = receivers
        } else if segue.identifier == "showEditAddressSegue" {
            let controller = segue.destination as! AddressSettingTableViewController
            
            controller.settingTableDelegate = self
        } else if segue.identifier == "showEnergySavingSegue" {
            let controller = segue.destination as! EnergySavingSettingTableViewController
            
            controller.settingTableDelegate = self
        }
    }
    
    func showReceivers() {
        receiver1Label.text = ""
        receiver2Label.text = ""
        receiverMoreLabel.text = ""
        
        if receivers.count > 0 {
            receiver1Label.text = "\(receivers[0].firstname) \(receivers[0].lastname)"
        }
        if receivers.count > 1 {
            receiver2Label.text = "\(receivers[1].firstname) \(receivers[1].lastname)"
        }
        if receivers.count > 2 {
            receiverMoreLabel.text = "..."
        }
        tableView.reloadData()
    }
    
    func showAddress() {
        address = setting.address
        if let address = address {
            addressLine1Label.text = "\(address.unit != nil ? "UNIT \(address.unit!) " : "")\(address.streetNo) \(address.streetName) \(address.streetType)"
            addressLine2Label.text = "\(address.suburb), \(address.state) \(address.postalCode)"
        }
    }
    
    func showEnergySaving() {
        energySavingStatusLabel.text = setting.isEnergySavingOn ? "On" : "Off"
    }
    
    func addReceiver(receiver: Receiver) {
        receivers.append(receiver)
        showReceivers()
    }
    
    func editReceiver(receiver: Receiver) {
        showReceivers()
    }
    
    func deleteReceiver(receiver: Receiver) {
        for i in 0..<receivers.count {
            if receivers[i].id == receiver.id {
                receivers.remove(at: i)
                break
            }
        }
        showReceivers()
    }
    
    func editAddress(address: Address) {
        showAddress()
    }
    
    func editEnergySaving() {
        showEnergySaving()
    }

}
