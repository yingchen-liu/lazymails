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

    var currentMails : [Mail] = []
    var selectedRow : Int?
    var mailboxDelegate : mailBoxDelegate?
    var indexForCell : Int?
    var category : Category?
    var isUnread = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension

        if let category = category {
            title = category.name
        }
        
        Socket.shared.mailCallbacks.append(newMailArrived)
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
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currentMails.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentMails[selectedRow!].didRead = true
        mailboxDelegate?.didRead(mail: currentMails[selectedRow!])
        do {
            try DataManager.shared.save()
        } catch {
            self.showError(message: "Could not save: \(error)")
            return
        }
        
        
        
    }
    func firstChar(str:String) -> String {
        return String(Array(str)[0])
    }
    func setCharacterRange(str : String) -> CharacterSet {
        
        return CharacterSet(charactersIn: str)
    }
    var checked: Int? = nil
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mailCell", for: indexPath) as! MailCell

        // display content
        let mail = currentMails[indexPath.row]
        if mail.title != "" {
            cell.letterTitleLabel.text = mail.title
            cell.imgLabel.text = firstChar(str: mail.title!).uppercased()
            // set image background color
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "AIU")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red:0.10, green:0.74, blue:0.61, alpha:1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "BJPV")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red:0.95, green:0.61, blue:0.07, alpha:1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "CKQW")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red:0.20, green:0.60, blue:0.86, alpha:1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "DLRX")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "EMSY")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red:0.61, green:0.35, blue:0.71, alpha:1.0)
            }
            
            if (firstChar(str: mail.title!).uppercased().rangeOfCharacter(from: setCharacterRange(str: "FNTZ")) != nil) {
                cell.letterPhotoImgView.backgroundColor = UIColor(red:0.20, green:0.29, blue:0.37, alpha:1.0)
            }
        }else {
            cell.letterTitleLabel.text = "Others"
            cell.imgLabel.text = "O"
            cell.letterPhotoImgView.backgroundColor = UIColor(red:0.09, green:0.63, blue:0.52, alpha:1.0)
        }
            cell.imgLabel.font = UIFont.boldSystemFont(ofSize: 25.0)
            cell.imgLabel.textColor = UIColor.white
            //cell.receiveDateLabel.text = convertDateToString(date: mail.receivedAt!)
        if isDateInToday(date: mail.receivedAt) {
            //print ("receiveeeeeee:\(mail.receivedAt)")
            cell.receiveDateLabel.text = formatDateAndTime(date: mail.receivedAt)
        }else {
            cell.receiveDateLabel.text = formatDate(date: mail.receivedAt)
        }
        
        
        
            cell.letterDescriptionLabel.text = mail.mainText
            cell.letterMarkImgView.image =  UIImage(named: mail.isImportant ? "star" : "star-outline")
        
        // set font systle
        if mail.didRead {
            cell.receiveDateLabel.font = UIFont.systemFont(ofSize: 15.0)
            cell.letterTitleLabel.font = UIFont.systemFont(ofSize: 17.0)
            cell.letterDescriptionLabel.font = UIFont.systemFont(ofSize: 15.0)
        }else {
            cell.receiveDateLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
            cell.letterTitleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.letterDescriptionLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
        }
        
        // mark important
        
        cell.letterMarkImgView.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(tapped(_sender:))))

        cell.letterMarkImgView.isUserInteractionEnabled = true
        cell.letterMarkImgView.tag = indexPath.row
        
        return cell
    }
    
    func isDateInToday(date: Date) -> Bool {
        //let today = NSDate()
        var calendar = NSCalendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())!
        calendar.locale = Locale.current
        return calendar.isDateInToday(date)
    }
    
    func tapped(_sender : AnyObject ) {
        var index = _sender.view.tag
        var mail = currentMails[index]
        if !mail.isImportant  {
            mail.isImportant = true
            mailboxDelegate?.addImportant(mail: mail)
        }else {
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
    
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 97
    }
    
    //  
    
    func convertDateToString(date : Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        //print ("dateeeeeeeee is \(date)")
        let str = formatter.string(from: date)
//        print ("\(str)")
        return str
    }
    
    func formatDate(date : Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyy-MM-dd"
        //print ("dateeeeeeeee is \(date)")
        let str = formatter.string(from: date)
//        print ("\(str)")
        return str
    }
    func formatDateAndTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "HH:mm"
        //print ("dateeeeeeeee is \(date)")
        let str = formatter.string(from: date)
//        print ("\(str)")
        return str
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
    
    func removeMail() {
        currentMails.remove(at: selectedRow!)
        tableView.reloadData()
    }
}
