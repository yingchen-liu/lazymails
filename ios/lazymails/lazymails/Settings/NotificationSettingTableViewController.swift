//
//  NotificationSettingTableViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class NotificationSettingTableViewController: UITableViewController {

    var categoryList : [Category] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        categoryList = DataManager.shared.categoryList
        
        categoryList.sort { (a, b) -> Bool in
            return a.name! > b.name!
        }
        
        Socket.shared.mailCallbacks.append(newMailReceived)
    }
    
    func newMailReceived(mail: Mail) {
        if !categoryList.contains(mail.category) {
            categoryList.append(mail.category)
            
            categoryList.sort { (a, b) -> Bool in
                return a.name! > b.name!
            }
            
            tableView.reloadData()
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
        return categoryList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notificationCell", for: indexPath) as! NotificationSettingTableViewCell

        cell.categoryNameLabel.text = categoryList[indexPath.row].name
        cell.categoryNotificationSwitch.isOn = categoryList[indexPath.row].notified
        cell.categoryNotificationSwitch.tag = indexPath.row
        cell.categoryNotificationSwitch.addTarget(self, action: #selector(notificationTriggerd(sender:)), for: .valueChanged)
        return cell
    }
    
    @objc func notificationTriggerd(sender: UISwitch) {
        if sender.isOn {
            categoryList[sender.tag].notified = true
        }else {
            categoryList[sender.tag].notified = false
        }
        do {
            try DataManager.shared.save()
        } catch {
            print ("Can not save notification settings")
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

}
