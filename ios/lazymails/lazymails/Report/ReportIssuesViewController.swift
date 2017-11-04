//
//  ReportIssuesViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class ReportIssuesViewController: UITableViewController {

    var currentMail : Mail?
    
    var mainContentDictionary : Dictionary<String, String> = [:]
    
    var delegate : RemoveMailDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "incorrectCategorySegue" {
            let destination: MoveCategoryController = segue.destination as! MoveCategoryController
            destination.currentMail = currentMail
            destination.delegate = delegate
        } else if segue.identifier == "incorrectDisplaySegue" {
            let destination: PhotoIncorrectViewController = segue.destination as! PhotoIncorrectViewController
            destination.currentMail = currentMail
        } else {
            let destination: IncorrectRecognitionViewController = segue.destination as! IncorrectRecognitionViewController
            destination.currentMail = currentMail
            destination.mainContentDictionary = mainContentDictionary
        }
    }

}
