//
//  OneCategoryDetailsViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 10/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class MailDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var categoryDetailsTableView: UITableView!
    
    @IBOutlet weak var letterPhotoImgView: UIImageView!
    
    @IBOutlet weak var receivedAtLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var selectedMail: Mail?
    
    var mailContentDictionary: Dictionary<String, String> = [:]
    
    var filterDictionary: Dictionary<String, String> = [:]
    
    var delegate: RemoveMailDelegate?
    
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        categoryDetailsTableView.dataSource = self
        categoryDetailsTableView.delegate = self
        categoryDetailsTableView.estimatedRowHeight = 44
        categoryDetailsTableView.rowHeight = UITableViewAutomaticDimension
        
        // convert mailinfo jsonString to dictionary
        mailContentDictionary = convertToDictionary(text: (selectedMail?.info!)!)!
        
        for (key, value) in mailContentDictionary {
            if mailContentDictionary[key] != "" {
                filterDictionary[key] = value
            }
//            print("\(filterDictionary)")
            title = selectedMail?.title
        }
        
        activityIndicator.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // show mail photo
        
        let base64 = (selectedMail?.showFullImage)! ? selectedMail?.boxImage : selectedMail?.image
        if let data = Data(base64Encoded: base64!, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: data)
            self.letterPhotoImgView.image = image
        }
        
        categoryDetailsTableView.reloadData()
        
        activityIndicator.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterDictionary.count + 1
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mailInfoCell")! as! MailInfoCell
        receivedAtLabel.text = convertDateToString(date: (selectedMail?.receivedAt)!)
        // ✴️ Attributes:
        // Stackoverflow: Can't make URL clickable in UITextView
        //      https://stackoverflow.com/questions/14387024/cant-make-url-clickable-in-uitextview
        // Stackoverflow: how to make UITextView height dynamic according to text length?
        //      https://stackoverflow.com/questions/38714272/how-to-make-uitextview-height-dynamic-according-to-text-length
        
        cell.detailsValueLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.detailsValueLabel.isScrollEnabled = false
        
        // ✴️ Attributes:
        // Stackoverflow: How to lose margin/padding in UITextView?
        //      https://stackoverflow.com/questions/746670/how-to-lose-margin-padding-in-uitextview
        
        cell.detailsValueLabel.textContainerInset = .zero
        cell.detailsValueLabel.textContainer.lineFragmentPadding = 0
        
        if indexPath.row == 0 {
            cell.detailsTitleLabel.text = "Category"
            cell.detailsValueLabel.text = selectedMail?.category.name
        } else {
            var keys = Array(filterDictionary.keys)
            
            cell.detailsTitleLabel.text = keys[indexPath.row - 1]
            
            if cell.detailsTitleLabel.text == "Website" {
                cell.detailsValueLabel.isSelectable = true
            }
            
            var values = Array(filterDictionary.values)
            cell.detailsValueLabel.text = values[indexPath.row - 1]
        }
        cell.selectionStyle = .none
        return cell
    }
    
    // ✴️ Attributes:
    // Stackoverflow: How to get a user's time zone?
    //      https://stackoverflow.com/questions/27053135/how-to-get-a-users-time-zone
    
    func convertDateToString(date : Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let str = formatter.string(from: date)
        return str
    }
    
    // ✴️ Attributes:
    // Stackoverflow: How to convert a JSON string to a dictionary?
    //      https://stackoverflow.com/questions/30480672/how-to-convert-a-json-string-to-a-dictionary
    func convertToDictionary(text: String) -> [String: String]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "reportSegue" {
            let destination : ReportIssuesViewController = segue.destination as! ReportIssuesViewController
            destination.currentMail = selectedMail
            destination.mainContentDictionary = filterDictionary
            destination.delegate = delegate
        }
        
        if segue.identifier == "showLargePhotoSegue" {
            let destination : LetterPhotoViewController = segue.destination as! LetterPhotoViewController
            destination.imageBase64 = (selectedMail?.showFullImage)! ? selectedMail?.boxImage : selectedMail?.image
            
            
        }
    }

}
