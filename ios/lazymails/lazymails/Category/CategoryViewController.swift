//
//  CategoryViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 10/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit
import CoreData

protocol mailBoxDelegate {
    func didRead (mail : Mail)
    func addImportant (mail : Mail)
    func removeImportant (mail : Mail)
}

class CategoryViewController: UITableViewController, mailBoxDelegate {
    
    var socket = Socket.shared
    
    var readAndImportantList = ["Unread","Important"]
    var categoryList: [Category] = []
    var mailList : [Mail] = []
    var specificMailList : [Mail] = []
    var mailUnreadList : [Mail] = []
    var mailImportantList : [Mail] = []
    var managedObjectContext : NSManagedObjectContext
    
    required init (coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.managedObjectContext = appDelegate.persistentContainer.viewContext
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DataManager.shared.fetchCategories()
        categoryList = DataManager.shared.categoryList
        categoryList.sort { (a, b) -> Bool in
            return a.name! > b.name!
        }
        
        DataManager.shared.fetchMails()
        mailList = DataManager.shared.mailList
        mailUnreadList = mailList.filter { (mail) -> Bool in
            return !mail.didRead
        }
        mailUnreadList.sort { (a, b) -> Bool in
            return a.receivedAt > b.receivedAt
        }
        
        mailImportantList = mailList.filter { (mail) -> Bool in
            return mail.isImportant
        }
        
        Socket.shared.iconDownloadCallbacks.append(categoryIconReceived)
        Socket.shared.mailCallbacks.append(mailCallback)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for category in categoryList {
            if category.icon == "" {
            socket.sendDownloadIconMessage(categoryName: category.name!)
            }
        }
        tableView.reloadData()
    }
    
    
    func mailCallback(mail: Mail) {
        mailList.append(mail)
        mailUnreadList.append(mail)
        mailUnreadList.sort { (a, b) -> Bool in
            return a.receivedAt > b.receivedAt
        }
        if !categoryList.contains(mail.category) {
            categoryList.append(mail.category)
            categoryList.sort { (a, b) -> Bool in
                return a.name! > b.name!
            }
        }
        
        tableView.reloadData()
    }
    
    func categoryIconReceived() {
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return readAndImportantList.count
        } else {
            return categoryList.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "specialCell", for: indexPath) as! SpecialCategoryCell
            //set the data here
            cell.cateNameLabel.text = readAndImportantList[indexPath.row]
            if cell.cateNameLabel.text == readAndImportantList[0] {
                cell.cateUnreadNoLabel.text = String(mailUnreadList.count)
                // ✴️ Attributes:
                // Stackoverflow: Swift: Programmatically make UILabel bold without changing its size?
                // https://stackoverflow.com/questions/39999093/swift-programmatically-make-uilabel-bold-without-changing-its-size
                
                if (mailUnreadList.count > 0) {
                    cell.cateNameLabel.font = UIFont.boldSystemFont(ofSize: cell.cateNameLabel.font.pointSize)
                    cell.cateUnreadNoLabel.font = UIFont.boldSystemFont(ofSize: cell.cateUnreadNoLabel.font.pointSize)
                } else {
                    cell.cateNameLabel.font = UIFont.systemFont(ofSize: cell.cateNameLabel.font.pointSize, weight: UIFont.Weight.regular)
                    cell.cateUnreadNoLabel.font = UIFont.systemFont(ofSize: cell.cateUnreadNoLabel.font.pointSize, weight: UIFont.Weight.regular)
                }
                
                cell.cateIconImgView.image = UIImage(named: "unread")
                print ( mailUnreadList.count)
            } else if cell.cateNameLabel.text == readAndImportantList[1] {
                cell.cateUnreadNoLabel.text = String(mailImportantList.count)
                cell.cateIconImgView.image = UIImage(named: "star-outline")
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as! CategoryCell
            //set the data here
            cell.cateNameLabel.text = categoryList[indexPath.row].name
            
            let unread = mailList.filter({ (mail) -> Bool in
                return mail.category.name == cell.cateNameLabel.text && !mail.didRead
            }).count
            
            if unread > 0 {
                cell.cateNameLabel.font = UIFont.boldSystemFont(ofSize: cell.cateNameLabel.font.pointSize)
                cell.cateUnreadNoLabel.font = UIFont.boldSystemFont(ofSize: cell.cateUnreadNoLabel.font.pointSize)
                cell.cateUnreadNoLabel.isHidden = false
            } else {
                cell.cateNameLabel.font = UIFont.systemFont(ofSize: cell.cateNameLabel.font.pointSize, weight: UIFont.Weight.regular)
                cell.cateUnreadNoLabel.isHidden = true
            }
            
            if let icon = categoryList[indexPath.row].icon {
                if let data = Data(base64Encoded: icon, options: .ignoreUnknownCharacters) {
                    let image = UIImage(data: data)
                    
                    cell.cateIconImgView.image = image
                }
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func prepare(for segue: UIStoryboardSegue,sender: Any?) {
        if segue.identifier == "showOneCategorySegue" {
            let destination : MailListViewController = segue.destination as! MailListViewController
            let selectedRowIndexPath = tableView.indexPathForSelectedRow
            destination.mailboxDelegate = self
            if selectedRowIndexPath?.section == 0 {
                if selectedRowIndexPath?.row == 0 {
                    destination.currentMails = mailUnreadList
                    destination.isUnread = true
                    destination.title = "Unread"
                }else {
                    destination.currentMails = mailImportantList
                    destination.title = "Important"
                }
            }
            
            if selectedRowIndexPath?.section == 1 {
                let selectedRow = tableView.indexPathForSelectedRow?.row
                var currentMails = categoryList[selectedRow!].mail?.allObjects as! [Mail]
                currentMails = currentMails.sorted { $0.receivedAt > $1.receivedAt}
                destination.currentMails = currentMails
                destination.category = categoryList[selectedRow!]
            }
            
        }
    }
    
    func didRead(mail: Mail) {
        if let index = mailUnreadList.index(of: mail) {
            mailUnreadList.remove(at: index)
        }
        tableView.reloadData()
    }
    
    func addImportant(mail: Mail) {
        if !mailImportantList.contains(mail) {
            mailImportantList.append(mail)
        }
        tableView.reloadData()
    }
    
    func removeImportant(mail: Mail) {
        if let index = mailImportantList.index(of: mail) {
            mailImportantList.remove(at: index)
        }
        tableView.reloadData()
    }
}
