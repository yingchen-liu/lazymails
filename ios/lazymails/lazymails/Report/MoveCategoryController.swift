//
//  MoveCategoryController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 8/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class MoveCategoryController: UITableViewController {

    @IBOutlet weak var checkboxImgView: UIImageView!
    @IBOutlet weak var submitButton: UIButton!
    
    var reportChecked = false
    var currentMail : Mail?
    var categoryList = DataManager.shared.categoryList
    var filteredCategoryList: [Category] = []
    var delegate: RemoveMailDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filteredCategoryList = categoryList.filter { (category) -> Bool in
            return currentMail?.category.id != category.id
        }
        
        let checkboxTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped(tapGestureRecognizer:)))
        checkboxImgView.isUserInteractionEnabled = true
        checkboxImgView.addGestureRecognizer(checkboxTapGestureRecognizer)
        
    }
    
    
    @objc func checkboxTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        reportChecked = !reportChecked
        checkboxImgView.image = UIImage(named: reportChecked ? "checkbox-checked-small" : "checkbox-small")
        
        submitButton.setTitle((reportChecked ? "Move and Submit" : "Move"), for: .normal)
    }
    
   

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section \(section)"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 18
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return filteredCategoryList.count
        } else {
            return 1
        }
    }
    
    var checked: Int? = nil
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "currentCategoryCell", for: indexPath) as! CurrentCategoryViewCell
            //set the data here
            //cell.lazyMailIcon.image = UIImage(named: "mailboxImg")
            cell.currentCategoryLabel.text = currentMail?.category.name
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "targetCategoryCell", for: indexPath) as! MoveToCagetoryViewCell
            //set the data here
            cell.categoryNameLabel.text = filteredCategoryList[indexPath.row].name
            if checked != nil {
                cell.moveCheckBoxImgView.image = UIImage(named: checked == indexPath.row ? "checkbox-checked" : "checkbox")
            }
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if indexPath.section == 1 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "targetCategoryCell", for: indexPath) as! MoveToCagetoryViewCell
//            checked = !checked
//            cell.moveCheckBoxImgView.image = UIImage(named: checked ? "checkbox-checked" : "checkbox" )
//        }
        checked = indexPath.row
        tableView.reloadData()
    }
    
    @IBAction func moveCategory(_ sender: Any) {
        currentMail?.category.removeFromMail(currentMail!)
        filteredCategoryList[checked!].addToMail(currentMail!)
        do {
            try DataManager.shared.save()
        } catch {
            self.showError(message: "Could not save: \(error)")
            return
        }
        
        delegate?.removeMail()
        
        if reportChecked {
            Socket.shared.sendReportCategory(category: filteredCategoryList[checked!].name!)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
    

}
