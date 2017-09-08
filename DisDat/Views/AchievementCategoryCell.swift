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
    
    var categoryIndex: Int?
    var englishCategoryText: String?
    
    func setContent(englishCategoryText: String, categoryText: String, categoryImage: UIImage?, progressString: String){
        self.englishCategoryText = englishCategoryText
        self.categoryImageView.image = categoryImage
        self.categoryLabel.text = categoryText
        self.progressCell.text = progressString
    }
    
    func clear(){
        englishCategoryText = nil
        categoryImageView.image = nil
        categoryLabel.text = nil
        progressCell.text = nil
    }
}
