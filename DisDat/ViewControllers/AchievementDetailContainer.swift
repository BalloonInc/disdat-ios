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
        categoryImageView.layer.cornerRadius = categoryImageView.frame.width/2;  // half the width/height
        categoryImageView.layer.borderWidth = 8;
        categoryImageView.layer.borderColor = UIColor.white.cgColor

        title = DiscoveredWordCollection.getInstance()!.getLearningCategory(index: categoryIndex!)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont.systemFont(ofSize: 24, weight: .bold), NSAttributedStringKey.foregroundColor:#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AchievementCardSegue"{
            if let dest = segue.destination as? AchievementCardPVC {
                dest.categoryIndex = categoryIndex
            }
        }
    }
}
