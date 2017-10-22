//
//  OnboardingPageThreeViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 3/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class OnboardingPageThreeViewController: UIViewController {

    @IBOutlet weak var getStartedButton: UIButton!
    
    @IBOutlet weak var checkboxImage: UIImageView!
    
    
    var checked = false
    
    let setting = Setting.shared
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getStartedButton.layer.cornerRadius = 5
        getStartedButton.backgroundColor = UIColor.lightGray
        
        let checkboxTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped(tapGestureRecognizer:)))
        checkboxImage.isUserInteractionEnabled = true
        checkboxImage.addGestureRecognizer(checkboxTapGestureRecognizer)
    }
    
    @objc func checkboxTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        checked = !checked
        checkboxImage.image = UIImage(named: checked ? "checkbox-checked-small" : "checkbox-small")
        getStartedButton.backgroundColor = checked ? UIColor(red: 122.0/255, green: 195.0/255, blue: 246.0/255, alpha: 1) : UIColor.lightGray
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getStartedSegue" {
            
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "getStartedSegue" {
            return checked
        }
        return true
    }

}
