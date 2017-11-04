//
//  AboutViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 4/11/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func chrisVeigtTapped(_ sender: Any) {
        openBrowser(url: "http://chrisveigt.com/")
    }
    
    @IBAction func freepikTapped(_ sender: Any) {
        openBrowser(url: "http://www.freepik.com/")
    }
    
    @IBAction func swiftValidatorTapped(_ sender: Any) {
        openBrowser(url: "https://github.com/SwiftValidatorCommunity/SwiftValidator")
    }
    
    @IBAction func qrCodeReaderTapped(_ sender: Any) {
        openBrowser(url: "https://github.com/yannickl/QRCodeReader.swift")
    }
    
    @IBAction func whisperTapped(_ sender: Any) {
        openBrowser(url: "https://github.com/hyperoslo/Whisper")
    }
    
    func openBrowser(url: String) {
        UIApplication.shared.openURL(URL(string: url)!)
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
