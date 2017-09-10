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
    @IBOutlet weak var categoryBorder: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let categoryImage = UIImage(named:englishCategoryText!.lowercased())
        categoryImageView.image = categoryImage
        categoryImageView.layer.cornerRadius = categoryImageView.frame.width/2;
        categoryBorder.layer.cornerRadius = categoryBorder.frame.width/2;
        
        title = DiscoveredWordCollection.getInstance()!.getLearningCategory(index: categoryIndex!)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor:#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
        
        self.navigationController?.navigationBar.largeTitleTextAttributes = [ NSAttributedStringKey.foregroundColor:#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
            self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1)

        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AchievementCardSegue"{
            if let dest = segue.destination as? AchievementCardPVC {
                dest.categoryIndex = categoryIndex
            }
        }
    }
}
