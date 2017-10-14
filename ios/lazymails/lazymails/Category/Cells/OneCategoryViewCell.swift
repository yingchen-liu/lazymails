//
//  OneCategoryViewCell.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 10/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class OneCategoryViewCell: UITableViewCell {

   
    @IBOutlet weak var letterPhotoImgView: UIImageView!
    @IBOutlet weak var letterTitleLabel: UILabel!
    @IBOutlet weak var receiveDateLabel: UILabel!
    @IBOutlet weak var letterDescriptionLabel: UILabel!
    @IBOutlet weak var letterMarkImgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
