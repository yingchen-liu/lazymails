//
//  LiveViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 3/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class LiveViewController: UIViewController {
    
    @IBOutlet weak var loadingLabel: UILabel!
    
    @IBOutlet weak var loadingDotsLabel: UILabel!
    
    @IBOutlet weak var liveImageView: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    
    var numOfLoadingDots = 0
    
    var loadingDotsTimer: Timer?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // StackOverflow: ios - How can I make a function execute every second in swift? - Stack Overflow
        //      https://stackoverflow.com/questions/30090309/how-can-i-make-a-function-execute-every-second-in-swift
        
        loadingDotsTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.refreshLoadingDots), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // StackOverflow: swift3 - Using Swift 3 Stopping a scheduledTimer, Timer continue firing even if timer is nil - Stack Overflow
        //      https://stackoverflow.com/questions/40081574/using-swift-3-stopping-a-scheduledtimer-timer-continue-firing-even-if-timer-is
        
        loadingDotsTimer?.invalidate()
    }
    
    @objc func refreshLoadingDots() {
        switch numOfLoadingDots {
        case 0:
            loadingDotsLabel.text = ""
            numOfLoadingDots = numOfLoadingDots + 1
            break
        case 1:
            loadingDotsLabel.text = "."
            numOfLoadingDots = numOfLoadingDots + 1
            break
        case 2:
            loadingDotsLabel.text = ".."
            numOfLoadingDots = numOfLoadingDots + 1
            break
        case 3:
            loadingDotsLabel.text = "..."
            numOfLoadingDots = 0
            break
        default:
            numOfLoadingDots = 0
            break
        }
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
