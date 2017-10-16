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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    static let liveFrameKeepLive = 10
    
    var numOfLoadingDots = 0
    
    var loadingDotsTimer: Timer?
    
    var frameReceived = 0
    
    let socket = Socket.shared
    

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
        
        socket.sendStartLiveMessage { (error, message) in
            
            self.activityIndicator.isHidden = true
            self.loadingLabel.text = ""
            self.loadingDotsTimer?.invalidate()
            self.loadingDotsLabel.text = ""
            
            guard error == nil else {
                self.loadingLabel.text = error
                return
            }
            
            let mailbox = message["mailbox"] as! NSDictionary as! Dictionary<String, Any>
            let base64 = mailbox["content"] as! String

            if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) {
                let image = UIImage(data: data)
                self.liveImageView.image = image
            }
            
            self.frameReceived += 1
            // send heartbeat half the time of the mailbox keeping alive time
            if self.frameReceived % (LiveViewController.liveFrameKeepLive / 2) == 0 {
                self.socket.sendLiveHeartbeatMessage()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // StackOverflow: swift3 - Using Swift 3 Stopping a scheduledTimer, Timer continue firing even if timer is nil - Stack Overflow
        //      https://stackoverflow.com/questions/40081574/using-swift-3-stopping-a-scheduledtimer-timer-continue-firing-even-if-timer-is
        
        loadingDotsTimer?.invalidate()
        socket.sendStopLiveMessage()
        activityIndicator.isHidden = false
        loadingLabel.text = "Connecting to your mailbox"
        liveImageView.image = nil
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
