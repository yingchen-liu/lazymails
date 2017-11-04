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
        // ✴️ Attributes:
        // Stackoverflow: How to Zoom In/Out Photo on double Tap in the iPhone WWDC 2010 - 104 PhotoScroller
        //      https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll/46143499#46143499
        
        // single tapped on the photo to go back
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageSingleTapped(tapGestureRecognizer:)))
        photoImgView.isUserInteractionEnabled = true
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        photoImgView.addGestureRecognizer(singleTapGestureRecognizer)
        
        // double tapped on the photo to zoom in and out
        let imageDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageDoubleTapped(tapGestureRecognizer:)))
        photoImgView.isUserInteractionEnabled = true
        imageDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        photoImgView.addGestureRecognizer(imageDoubleTapGestureRecognizer)
        
        singleTapGestureRecognizer.require(toFail: imageDoubleTapGestureRecognizer)
        
        //show large photo
        if let data = Data(base64Encoded: imageBase64!, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: data)
            self.photoImgView.image = image
        }
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        // hide scrollview scrollbar
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.photoImgView
    }
    
    
    @objc func imageSingleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        dismiss(animated: true) { }
        
    }
    // ✴️ Attributes:
    // Stackoverflow: UIScrollView Zooming & contentInset
    //     https://stackoverflow.com/questions/39460256/uiscrollview-zooming-contentinset
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            
            if let image = photoImgView.image {
                
                let ratioW = photoImgView.frame.width / image.size.width
                let ratioH = photoImgView.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW:ratioH
                
                let newWidth = image.size.width*ratio
                let newHeight = image.size.height*ratio
                
                let left = 0.5 * (newWidth * scrollView.zoomScale > photoImgView.frame.width ? (newWidth - photoImgView.frame.width) : (scrollView.frame.width - scrollView.contentSize.width))
                let top = 0.5 * (newHeight * scrollView.zoomScale > photoImgView.frame.height ? (newHeight - photoImgView.frame.height) : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsetsMake(top, left, top, left)
            }
        } else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
    
    @objc func imageDoubleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        //dismiss(animated: true) { }
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: tapGestureRecognizer.location(in: tapGestureRecognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    // ✴️ Attributes:
    // Stackoverflow: How to Zoom In/Out Photo on double Tap in the iPhone WWDC 2010 - 104 PhotoScroller
    //      https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll/46143499#46143499
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
    
}
