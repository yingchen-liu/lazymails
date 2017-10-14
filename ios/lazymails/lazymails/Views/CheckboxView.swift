//
//  CheckboxImage.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 12/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class CheckboxView: UIView {
    
    @IBOutlet var contentView: CheckboxView!
    
    @IBOutlet weak var checkboxImage: UIImageView!
    
    var checkedImage: UIImage?
    
    var uncheckedImage: UIImage?
    
    var checked = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadView()
    }
    
    func loadView() {
        Bundle.main.loadNibNamed("CheckboxView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func setup(unchecked: String, checked: String) {
        checkedImage = UIImage(named: checked)!
        uncheckedImage = UIImage(named: unchecked)!
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped))
        
        checkboxImage.image = uncheckedImage
        checkboxImage.isUserInteractionEnabled = true
        checkboxImage.addGestureRecognizer(gestureRecognizer)
    }
    @objc func checkboxTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        checked = !checked
        checkboxImage.image = checked ? checkedImage : uncheckedImage
    }
    
}
