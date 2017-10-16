//
//  OneCategoryDetailsViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 10/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class OneCategoryDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var categoryDetailsTableView: UITableView!
    @IBOutlet weak var letterPhotoImgView: UIImageView!
    
    var categoryDetailsList = ["Category:" : "Bills","From:" : "Po Box 6324 WETHERILL PARK NSW 1851","To:" : "MISS QIUXIAN CAI"]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        categoryDetailsTableView.dataSource = self
        categoryDetailsTableView.delegate = self
        categoryDetailsTableView.estimatedRowHeight = 44
        categoryDetailsTableView.rowHeight = UITableViewAutomaticDimension
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
        return categoryDetailsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryDetailsCell")! as! OneCategoryDetailsViewCell
        
        var keys = Array(categoryDetailsList.keys)
        cell.detailsTitleLabel.text = keys[indexPath.row]
        var values = Array(categoryDetailsList.values)
        cell.detailsValueLabel.text = values[indexPath.row]
       return cell
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
