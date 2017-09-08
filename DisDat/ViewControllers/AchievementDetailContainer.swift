//
//  AchievementsTableViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class AchievementDetailContainer: UIViewController {
    var categoryIndex: Int?
    var englishCategoryText: String?
    
    @IBOutlet weak var cardContainerView: UIView!
    @IBOutlet weak var categoryImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let categoryImage = UIImage(named:englishCategoryText!.lowercased())
        categoryImageView.image = categoryImage
        title = DiscoveredWordCollection.getInstance()!.getLearningCategory(index: categoryIndex!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AchievementCardSegue"{
            if let dest = segue.destination as? AchievementCardPVC {
                dest.categoryIndex = categoryIndex
            }
        }
    }
}
