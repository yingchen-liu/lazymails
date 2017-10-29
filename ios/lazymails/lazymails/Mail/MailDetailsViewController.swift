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
    
    var categoryDetailsList = ["Category:" : "Bills","From:" : "Po Box 6324 WETHERILL PARK NSW 1851","To:" : "MISS QIUXIAN CAI"]
    var selectedMail : Mail?
    var mailContentDictionary: NSDictionary?
    var delegate : removeMailDelegate?
    
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        categoryDetailsTableView.dataSource = self
        categoryDetailsTableView.delegate = self
        categoryDetailsTableView.estimatedRowHeight = 44
        categoryDetailsTableView.rowHeight = UITableViewAutomaticDimension
        // convert mailinfo jsonString to dictionary
        mailContentDictionary = convertToDictionary(text: (selectedMail?.info!)!) as NSDictionary?
        
        //show mail photo
        let base64 = selectedMail?.image
        if let data = Data(base64Encoded: base64!, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: data)
            self.letterPhotoImgView.image = image
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        categoryDetailsTableView.reloadData()
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
        return mailContentDictionary!.count + 1
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mailInfoCell")! as! MailInfoCell
        receivedAtLabel.text = convertDateToString(date: (selectedMail?.receivedAt!)!)
        
        if indexPath.row == 0 {
            cell.detailsTitleLabel.text = "Category"
            cell.detailsValueLabel.text = selectedMail?.category?.name
        } else {
            var keys = mailContentDictionary?.allKeys
            cell.detailsTitleLabel.text = keys?[indexPath.row - 1] as? String
            var values = mailContentDictionary?.allValues
            cell.detailsValueLabel.text = (values?[indexPath.row - 1] as! String)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func convertDateToString(date : Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let str = formatter.string(from: date)
        return str
    }
    
    
    //https://stackoverflow.com/questions/30480672/how-to-convert-a-json-string-to-a-dictionary
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "reportSegue" {
            let destination : ReportIssuesViewController = segue.destination as! ReportIssuesViewController
            destination.currentMail = selectedMail
            destination.mainContentDictionary = mailContentDictionary
            destination.delegate = delegate
        }
        
        if segue.identifier == "showLargePhotoSegue" {
            let destination : LetterPhotoViewController = segue.destination as! LetterPhotoViewController
            destination.imageBase64 = selectedMail?.image
            
            
        }
    }

}
