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
    //var categoryList = ["card","bills","statements"]
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
        //createData()
        //saveToCoreData()
        //modifyData()
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
        mailImportantList = mailList.filter { (mail) -> Bool in
            return mail.isImportant
        }
        
        Socket.shared.iconDownloadCallbacks.append(categoryIconReceived)
        Socket.shared.mailCallbacks.append(mailCallback)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func mailCallback(mail: Mail) {
        mailList.append(mail)
        mailUnreadList.append(mail)
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
    
    func fetchCategories(){
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        do {
            categoryList = try self.managedObjectContext.fetch(fetchRequest)
            
        }catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        fetchReadOrImportantMail()
    }
 
    func fetchReadOrImportantMail (){
        let fetchRequest = NSFetchRequest<Mail>(entityName: "Mail")
        var mailList : [Mail] = []
        do {
            mailList = try self.managedObjectContext.fetch(fetchRequest)
            for mail in mailList {
                if mail.didRead == false {
                    mailUnreadList.append(mail)
                }
                if mail.isImportant == true {
                    mailImportantList.append(mail)
                }
            }
        }catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    func modifyData() {
        let fetchRequest = NSFetchRequest<Mail>(entityName: "Mail")
        var mailList : [Mail] = []
        do {
            mailList = try self.managedObjectContext.fetch(fetchRequest)
            for mail in mailList {
//                if mail.id == "1" {
//                    let jsonObj = ["Category":"Parcel Collection Cards","Text":"A parcel collection card from Australia Post", "Website":"https://auspost.com.au/"]
//                    let jsonData = try! JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions())
//                    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
//                    print(jsonString)
//                    mail.info = jsonString
//                }
                
//                if mail.id == "2" {
//
//                    let para: NSMutableDictionary = NSMutableDictionary()
//                    para.setValue("Normal Letters", forKey: "Category")
//                    para.setValue("Australia Post", forKey: "From")
//                    para.setValue("MISS QIUXIAN CAI", forKey: "To")
//                    para.setValue("https://auspost.com.au/", forKey: "Website")
//
//                    let jsonData = try! JSONSerialization.data(withJSONObject: para, options: JSONSerialization.WritingOptions())
//                    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
//                    print(jsonString)
//                    mail.info = jsonString
//                }
                
//                if mail.id == "3" {
//                    let jsonObj = ["Category":mail.category?.name,"From":"PO Box7525,Silverwater NSW 2128","To": "Miss Qiuxian Cai Unit 5 5 Moodie St Caulfield EAST VIC 3145", "Website":"https://commbank.com.au/"]
//                    let jsonData = try! JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions())
//                    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
//                    print(jsonString)
//                    mail.info = jsonString
//                }
//                if mail.id == "4" {
//                    let jsonObj = ["Category":mail.category?.name,"From":"EnergyAustralia","To": "Miss Qiuxian Cai Unit 5 5 Moodie St Caulfield EAST VIC 3145", "Website":"https://www.energyaustralia.com.au/"]
//                    let jsonData = try! JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions())
//                    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
//                    print(jsonString)
//                    mail.info = jsonString
//                }
//                if mail.id == "5" {
//                    let jsonObj = ["Category":mail.category?.name,"Text": "When you purchase two or more Clarins products, one being skincare. For you, our most powerful age control concentrate ever.", "Website":"https://www.myer.com.au/"]
//                    let jsonData = try! JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions())
//                    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
//                    print(jsonString)
//                    mail.info = jsonString
//                }
                if mail.id == "6" {
                    let jsonObj = ["Category":mail.category.name,"Text": "Feel hotter in city? This is because of the Urban Heat Island Effect, visit to our website to learn more about this issues.", "Website":"http://www.coolmelb.ml/"]
                    let jsonData = try! JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions())
                    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
                    print(jsonString)
                    mail.info = jsonString
                }
                
            }
        }catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        saveToCoreData()
        
    }
    
//    func createData(){
//        
//        let newCategory1 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as! Category;
//        newCategory1.name = "Parcel Collection Cards"
//        newCategory1.id = "1"
//        
//        let newMail1 = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: managedObjectContext) as! Mail;
//        newMail1.id = "1"
//        newMail1.didRead = false
//        newMail1.isImportant = false
//        newMail1.title = "Autralian Post"
//        let todaysDate:NSDate = NSDate()
//        newMail1.receivedAt = todaysDate
//        newMail1.mainText = "A parcel collection card"
//        newCategory1.addToMail(newMail1)
//        //
//        let newCategory2 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as! Category;
//        newCategory2.name = "Normal Letters"
//        newCategory2.id = "2"
//        
//        let newMail2 = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: managedObjectContext) as! Mail;
//        newMail2.id = "2"
//        newMail2.didRead = false
//        newMail2.isImportant = false
//        newMail2.title = "Post"
//        let todaysDate2: NSDate = NSDate()
//        newMail2.receivedAt = todaysDate2
//        newMail2.mainText = "To: MISS QIUXIAN CAI UNIT 5 5 MOODLE ST CAULFIELD EAST VIC 3145"
//        newCategory2.addToMail(newMail2)
//        //
//        let newCategory3 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as! Category;
//        newCategory3.name = "Bank Statements"
//        newCategory3.id = "3"
//        
//        let newMail3 = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: managedObjectContext) as! Mail;
//        newMail3.id = "3"
//        newMail3.didRead = false
//        newMail3.isImportant = false
//        newMail3.title = "Commonwealth"
//        let todaysDate3: NSDate = NSDate()
//        newMail3.receivedAt = todaysDate3
//        newMail3.mainText = "Every convenience at a great rate. Low Rate credit card Apply today."
//        newCategory3.addToMail(newMail3)
//        
//        //
//        let newCategory4 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as! Category;
//        newCategory4.name = "Utility Bills"
//        newCategory4.id = "4"
//        
//        let newMail4 = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: managedObjectContext) as! Mail;
//        newMail4.id = "4"
//        newMail4.didRead = false
//        newMail4.isImportant = false
//        newMail4.title = "STATE GRID"
//        let todaysDate4: NSDate = NSDate()
//        newMail4.receivedAt = todaysDate4
//        newMail4.mainText = "To: MISS QIUXIAN CAI UNIT 5 5 MOODLE ST CAULFIELD EAST VIC 3145"
//        newCategory4.addToMail(newMail4)
//        
//        //
//        let newCategory5 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as! Category;
//        newCategory5.name = "Ads"
//        newCategory5.id = "5"
//        
//        let newMail5 = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: managedObjectContext) as! Mail;
//        newMail5.id = "5"
//        newMail5.didRead = false
//        newMail5.isImportant = false
//        newMail5.title = "Myer"
//        let todaysDate5: NSDate = NSDate()
//        newMail5.receivedAt = todaysDate5
//        newMail5.mainText = "When you purchase two or more Clarins products, one being skincare."
//        newCategory5.addToMail(newMail5)
//        
//        
//        //
//        let newCategory6 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObjectContext) as! Category;
//        newCategory6.name = "Others"
//        newCategory6.id = "6"
//        
//        let newMail6 = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: managedObjectContext) as! Mail;
//        newMail6.id = "6"
//        newMail6.didRead = false
//        newMail6.isImportant = false
//        newMail6.title = "Other.."
//        let todaysDate6: NSDate = NSDate()
//        newMail6.receivedAt = todaysDate6
//        newMail6.mainText = "this is others section."
//        newCategory6.addToMail(newMail6)
//    }
//    
    func saveToCoreData() {
        do {
            try managedObjectContext.save()
            
        }catch {
            print("Can not save data to core data")
        }
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
//                print (selectedRow)
                var currentMails = categoryList[selectedRow!].mail?.allObjects as! [Mail]
                currentMails = currentMails.sorted { $0.receivedAt > $1.receivedAt}
                destination.currentMails = currentMails
                destination.category = categoryList[selectedRow!]
            }
            
        }
    }
    func didRead (mail: Mail){
        if let index = mailUnreadList.index(of:mail) {
            mailUnreadList.remove(at: index)
        }
        tableView.reloadData()
    }
    
    func addImportant (mail : Mail) {
        if !mailImportantList.contains(mail) {
            mailImportantList.append(mail)
        }
        tableView.reloadData()
    }
    func removeImportant(mail: Mail) {
        if let index = mailImportantList.index(of:mail) {
            mailImportantList.remove(at: index)
        }
        tableView.reloadData()
    }
}
