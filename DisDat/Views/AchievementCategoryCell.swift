//
//  AchievementCategoryCell.swift
//  DisDat
//
//  Created by Wouter Devriendt on 29/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class AchievementCategoryCell: UICollectionViewCell {
    @IBOutlet weak var categoryImageView: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var progressCell: UILabel!
    
    func setContent(categoryText: String, categoryImage: UIImage?, progressString: String){
        categoryImageView.image = categoryImage
        categoryLabel.text = categoryText
        progressCell.text = progressString
    }
    
    func clear(){
        categoryImageView.image = nil
        categoryLabel.text = nil
        progressCell.text = nil
    }
}
