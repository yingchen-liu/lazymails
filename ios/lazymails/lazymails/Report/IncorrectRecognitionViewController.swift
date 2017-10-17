//
//  IncorrectRecognitionViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class IncorrectRecognitionViewController: UITableViewController {

    @IBOutlet weak var checkboxImgView: UIImageView!
    @IBOutlet weak var submitButton: UIButton!
    
    var checked = false
    var contentList = ["From:": "Unit 5 5 Moodie Street Unit 5 5 Moodie Street Unit 5 5 Moodie Street Unit 5 5 Moodie Street","To:": "Monash University ","Websites:": "http://www.coolmelb.ml"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 5
        submitButton.backgroundColor = UIColor.lightGray
        
        let checkboxTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped(tapGestureRecognizer:)))
        checkboxImgView.isUserInteractionEnabled = true
        checkboxImgView.addGestureRecognizer(checkboxTapGestureRecognizer)
    }
    
    @objc func checkboxTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        checked = !checked
        checkboxImgView.image = UIImage(named: checked ? "checkbox-checked-small" : "checkbox-small")
        submitButton.backgroundColor = checked ? UIColor(red: 1, green: 102.0/255, blue: 82.0/255, alpha: 1) : UIColor.lightGray
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
        return contentList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recognitionCell", for: indexPath) as! IncorrectRecognitionViewCell

        // Configure the cell...
        var keys = Array(contentList.keys)
        cell.titleLabel.text = keys[indexPath.row]
        var values = Array(contentList.values)
        cell.valueLabel.text = values[indexPath.row]
        
        return cell
    }
    

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
