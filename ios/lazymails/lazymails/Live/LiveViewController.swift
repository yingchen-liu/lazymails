//
//  LiveViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 3/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class LiveViewController: UIViewController, UIScrollViewDelegate{
    
    @IBOutlet weak var loadingLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var loadingDotsLabel: UILabel!
    
    @IBOutlet weak var liveImageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    static let liveFrameKeepLive = 10
    
    var numOfLoadingDots = 0
    
    var loadingDotsTimer: Timer?
    
    var heartbeatTimer: Timer?
    
    var timeBetweenTwoFrames: [Double] = []
    
    var lastReceivedFrameAt: Double?
    
    let socket = Socket.shared
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.timeLabel.text = ""
        
        
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
            let time = message["time"] as! String

            //  https://stackoverflow.com/questions/25678373/swift-split-a-string-into-an-array
            
            self.timeLabel.text = time.components(separatedBy: " ")[1]
            
            if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) {
                let image = UIImage(data: data)
                self.liveImageView.image = image
            }
            
            // Calculate mean latency
            if let lastReceivedFrameAt = self.lastReceivedFrameAt {
                //  https://stackoverflow.com/questions/358207/iphone-how-to-get-current-milliseconds
                
                let delay = self.timeBetweenTwoFrames.count > 0 ? (self.timeBetweenTwoFrames.average + (CACurrentMediaTime() - lastReceivedFrameAt)) / 2 : (CACurrentMediaTime() - lastReceivedFrameAt)
                
                self.timeBetweenTwoFrames.append(delay)
                
                //      https://stablekernel.com/swift-subarrays-array-and-arrayslice/
                
                var start = self.timeBetweenTwoFrames.count - 5
                start = start >= 0 ? start : 0
                let end = self.timeBetweenTwoFrames.count
                self.timeBetweenTwoFrames = Array(self.timeBetweenTwoFrames[start..<end])
                
                let latency = self.timeBetweenTwoFrames[self.timeBetweenTwoFrames.count - 1]
                if latency > 2 {
                    self.loadingLabel.text = "[!] High latency"
                    self.activityIndicator.isHidden = false
                } else {
                    self.loadingLabel.text = ""
                    self.activityIndicator.isHidden = true
                }
            }
            
            self.lastReceivedFrameAt = CACurrentMediaTime()
        }
        
        heartbeatTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.heartbeat), userInfo: nil, repeats: true)
        
        // double tapped on the live image to zoom in and out
        let imageDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageDoubleTapped(tapGestureRecognizer:)))
        liveImageView.isUserInteractionEnabled = true
        imageDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        liveImageView.addGestureRecognizer(imageDoubleTapGestureRecognizer)
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        
        
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.liveImageView
    }
    
    @objc func imageDoubleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        //dismiss(animated: true) { }
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: tapGestureRecognizer.location(in: tapGestureRecognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    // https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll/46143499#46143499
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = liveImageView.frame.size.height / scale
        zoomRect.size.width  = liveImageView.frame.size.width  / scale
        let newCenter = liveImageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            
            if let image = liveImageView.image {
                
                let ratioW = liveImageView.frame.width / image.size.width
                let ratioH = liveImageView.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW:ratioH
                
                let newWidth = image.size.width*ratio
                let newHeight = image.size.height*ratio
                
                let left = 0.5 * (newWidth * scrollView.zoomScale > liveImageView.frame.width ? (newWidth - liveImageView.frame.width) : (scrollView.frame.width - scrollView.contentSize.width))
                let top = 0.5 * (newHeight * scrollView.zoomScale > liveImageView.frame.height ? (newHeight - liveImageView.frame.height) : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsetsMake(top, left, top, left)
            }
        } else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // StackOverflow: swift3 - Using Swift 3 Stopping a scheduledTimer, Timer continue firing even if timer is nil - Stack Overflow
        //      https://stackoverflow.com/questions/40081574/using-swift-3-stopping-a-scheduledtimer-timer-continue-firing-even-if-timer-is
        
        loadingDotsTimer?.invalidate()
        heartbeatTimer?.invalidate()
        socket.sendStopLiveMessage()
        activityIndicator.isHidden = false
        lastReceivedFrameAt = nil
        loadingLabel.text = "Connecting to your mailbox"
        timeLabel.text = ""
        liveImageView.image = nil
    }
    
    @objc func heartbeat() {
        self.socket.sendLiveHeartbeatMessage()
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
