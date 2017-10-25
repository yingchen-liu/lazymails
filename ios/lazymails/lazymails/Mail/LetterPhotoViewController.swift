//
//  LetterPhotoViewController.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class LetterPhotoViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var photoImgView: UIImageView!
    
    var imageBase64 : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //      https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll/46143499#46143499

        let imageTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        photoImgView.isUserInteractionEnabled = true
        imageTapGestureRecognizer.numberOfTapsRequired = 2
        photoImgView.addGestureRecognizer(imageTapGestureRecognizer)
        //show large photo
        if let data = Data(base64Encoded: imageBase64!, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: data)
            self.photoImgView.image = image
        }
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.photoImgView
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        //dismiss(animated: true) { }
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: tapGestureRecognizer.location(in: tapGestureRecognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = photoImgView.frame.size.height / scale
        zoomRect.size.width  = photoImgView.frame.size.width  / scale
        let newCenter = photoImgView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
