//
//  EnergySavingSettingViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class EnergySavingSettingTableViewController: UITableViewController {

    @IBOutlet weak var energySavingSwitch: UISwitch!
    
    let setting = Setting.shared
    
    var settingTableDelegate: SettingTableDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        energySavingSwitch.isOn = setting.isEnergySavingOn
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func energySavingSwitchChanged(_ sender: Any) {
        setting.isEnergySavingOn = energySavingSwitch.isOn
        setting.save()
        settingTableDelegate?.editEnergySaving()
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
