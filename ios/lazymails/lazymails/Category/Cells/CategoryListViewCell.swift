//
//  CategoryListViewCell.swift
//  lazymails
//
//  Created by QIUXIAN CAI on 10/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit

class CategoryListViewCell: UITableViewCell {

    @IBOutlet weak var cateIconImgView: UIImageView!
    @IBOutlet weak var cateNameLabel: UILabel!
    @IBOutlet weak var cateUnreadNoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
