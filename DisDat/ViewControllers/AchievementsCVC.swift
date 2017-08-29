//
//  AchievementsCVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 29/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

private let reuseIdentifier = "AchievementCategoryCell"

class AchievementsCVC: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCategoryDetailSegue"{
            if let destVC = segue.destination as? AchievementDetailTVC {
                destVC.categoryIndex = (sender as! IndexPath).item
            }
        }
    }
 
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DiscoveredWordCollection.getInstance()!.learningLanguageCategories.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AchievementCategoryCell
    
        // Configure the cell
        let categoryText = DiscoveredWordCollection.getInstance()!.learningLanguageCategories[indexPath.item]
        let categoryImage = UIImage(named:"")
        
        let jsonCategory = DiscoveredWordCollection.getInstance()!.englishLanguageJson[indexPath.item]["words"] as! [String]
        
        let discoveredProgress = jsonCategory.map({DiscoveredWordCollection.getInstance()!.isDiscovered(englishWord:$0) ? 1 : 0}).reduce(0,+)
            
        let totalProgress =  jsonCategory.count
        let progressString = "\(discoveredProgress)/\(totalProgress)"
        
        cell.setContent(categoryText:categoryText, categoryImage: categoryImage, progressString:progressString )
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowCategoryDetailSegue", sender: indexPath)
    }
}
