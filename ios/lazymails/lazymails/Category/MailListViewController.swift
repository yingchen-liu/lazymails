//
//  OneCategoryViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 10/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

protocol RemoveMailDelegate {
    func removeMail()
}

class MailListViewController: UITableViewController, RemoveMailDelegate {
    
    @IBOutlet weak var markAsReadButton: UIBarButtonItem!
    

    var currentMails : [Mail] = []
    
    var selectedRow : Int?
    
    var mailboxDelegate : mailBoxDelegate?
    
    var indexForCell : Int?
    
    var category : Category?
    
    var isUnread = false
    
    var firstSelected = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension

        if let category = category {
            title = category.name
        }
        
        Socket.shared.mailCallbacks.append(newMailArrived)
        
        // ✴️ Attributes:
        // Stackoverflow: ios - How to select multiple rows in UITableView in edit mode? - Stack Overflow
        //      https://stackoverflow.com/questions/33970807/how-to-select-multiple-rows-in-uitableview-in-edit-mode
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        navigationItem.rightBarButtonItems = [editButtonItem]
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func newMailArrived(mail: Mail) {
        if mail.category == category || isUnread {
            currentMails.insert(mail, at: 0)
        }
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentMails.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isEditing && !currentMails[selectedRow!].didRead {
            currentMails[selectedRow!].didRead = true
            mailboxDelegate?.toggleRead(mail: currentMails[selectedRow!], read: true)
            do {
                try DataManager.shared.save()
            } catch {
                self.showError(message: "Could not save: \(error)")
                return
            }
        } else {
            if !firstSelected {
                firstSelected = true
                markAsReadButton.isEnabled = true
                
                if currentMails[indexPath.row].didRead {
                    markAsReadButton.title = "Mark as Unread"
                } else {
                    markAsReadButton.title = "Mark as Read"
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let selectedRows = tableView.indexPathsForSelectedRows
        if selectedRows == nil {
            markAsReadButton.isEnabled = false
            firstSelected = false
            markAsReadButton.title = "Mark as Read"
        }
    }
    
    /**
     get first character of string and return as a string
     - Parameters:
         - str: String input
     - Returns: a string
     */
    func firstChar(str:String) -> String {
        return String(Array(str)[0])
    }
    
    /**
     Convert string to charatersets
     - Parameters:
         - str: String input
     - Returns: CharacterSet
     */
    func setCharacterRange(str : String) -> CharacterSet {
        
        return CharacterSet(charactersIn: str)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mailCell", for: indexPath) as! MailCell

        // display content
        let mail = currentMails[indexPath.row]
        if mail.title != "" {
            cell.letterTitleLabel.text = mail.title
            cell.imgLabel.text = firstChar(str: mail.title!).uppercased()
            // set image background color
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "AIU")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red: 0.10, green: 0.74, blue: 0.61, alpha: 1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "BJPV")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "CKQW")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha:1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "DLRX")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "EMSY")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "FNTZ")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red: 0.20, green: 0.29, blue: 0.37, alpha: 1.0)
            }
        } else {
            cell.letterTitleLabel.text = "Others"
            cell.imgLabel.text = "O"
            cell.letterPhotoImgView.backgroundColor = UIColor(red: 0.09, green: 0.63, blue: 0.52, alpha: 1.0)
        }
            cell.imgLabel.font = UIFont.boldSystemFont(ofSize: 25.0)
            cell.imgLabel.textColor = UIColor.white
        
        // check if date is today
        if isDateInToday(date: mail.receivedAt) {
            // today shows time
            cell.receiveDateLabel.text = mail.receivedAt.formatDateAndTime()
            
        } else {
            // before today shows date
            cell.receiveDateLabel.text = mail.receivedAt.formatDate()
        }
        
        cell.letterDescriptionLabel.text = mail.mainText
        cell.letterMarkImgView.image =  UIImage(named: mail.isImportant ? "star" : "star-outline")
        
        // set font systle
        if mail.didRead {
            cell.receiveDateLabel.font = UIFont.systemFont(ofSize: 15.0)
            cell.letterTitleLabel.font = UIFont.systemFont(ofSize: 17.0)
            cell.letterDescriptionLabel.font = UIFont.systemFont(ofSize: 15.0)
        } else {
            cell.receiveDateLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
            cell.letterTitleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.letterDescriptionLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
        }
        
        cell.letterDescriptionLabel.sizeToFit()
        
        // mark important
        cell.letterMarkImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_sender:))))

        cell.letterMarkImgView.isUserInteractionEnabled = true
        cell.letterMarkImgView.tag = indexPath.row
        
        return cell
    }
    
    /**
     Check whether date is today
     - Parameters:
         - date: a date
     - Returns: date is today or not
     */
    func isDateInToday(date: Date) -> Bool {
        //let today = NSDate()
        var calendar = NSCalendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())!
        calendar.locale = Locale.current
        return calendar.isDateInToday(date)
    }
    
    // tap star to mark important
    @objc func tapped(_sender : AnyObject) {
        let index = _sender.view.tag
        let mail = currentMails[index]
        if !mail.isImportant {
            mail.isImportant = true
            mailboxDelegate?.addImportant(mail: mail)
        } else {
            mail.isImportant = false
            mailboxDelegate?.removeImportant(mail: mail)
        }
        do {
            try DataManager.shared.save()
        } catch {
            print ("can not save")
        }
        
        tableView.reloadData()
//        print("you tap image number : \(_sender.view.tag)")
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        navigationController?.setToolbarHidden(!editing, animated: true)
        firstSelected = !editing
        markAsReadButton.isEnabled = false
        markAsReadButton.title = "Mark as Read"
    }
    
    
    // tap mark as read/unread in the toolbar
    @IBAction func markAsReadButtonTapped(_ sender: Any) {
        if let selectedRows = tableView.indexPathsForSelectedRows {
            
            for row in selectedRows {
                currentMails[row.row].didRead = markAsReadButton.title == "Mark as Read"
                mailboxDelegate?.toggleRead(mail: currentMails[row.row], read: markAsReadButton.title == "Mark as Read")
            }
            
            do {
                try DataManager.shared.save()
            } catch {
                print("can not save")
            }
            
            tableView.reloadData()
            
            firstSelected = false
            markAsReadButton.isEnabled = false
            markAsReadButton.title = "Mark as Read"
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 97
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !isEditing
    }
    
    override func prepare(for segue: UIStoryboardSegue,sender: Any?) {
        if segue.identifier == "showCategoryDetailsSegue" {
            let destination : MailDetailsViewController = segue.destination as! MailDetailsViewController
            selectedRow = tableView.indexPathForSelectedRow?.row
                //print (selectedRow)
            destination.selectedMail = currentMails[selectedRow!]
            destination.delegate = self
            //destination.mailboxDelegate = mailboxDelegate
        }
    }
    
    /**
     Remove mail from tableview
     
     */
    func removeMail() {
        currentMails.remove(at: selectedRow!)
        tableView.reloadData()
    }
}
