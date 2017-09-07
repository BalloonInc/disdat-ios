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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.collectionView?.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCategoryDetailSegue"{
            if let destVC = segue.destination as? AchievementDetailTVC {
                destVC.categoryIndex = (sender as! AchievementCategoryCell).categoryIndex
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
        cell.categoryIndex = indexPath.item
        let englishCategoryText = DiscoveredWordCollection.getInstance()!.englishLanguageCategories[indexPath.item]
        let categoryText = DiscoveredWordCollection.getInstance()!.learningLanguageCategories[indexPath.item]
        
        let jsonCategory = DiscoveredWordCollection.getInstance()!.englishLanguageJson[indexPath.item]["words"] as! [String]
        
        let discoveredProgress = jsonCategory.map({DiscoveredWordCollection.getInstance()!.isDiscovered(englishWord:$0) ? 1 : 0}).reduce(0,+)
            
        let totalProgress =  jsonCategory.count
        let progressString = "\(discoveredProgress)/\(totalProgress)"
        var imagename = englishCategoryText.lowercased()
        if discoveredProgress == 0 {
            imagename += "-grey"
        }
        let categoryImage = UIImage(named:imagename)
        
        cell.setContent(categoryText:categoryText, categoryImage: categoryImage, progressString:progressString )
        
    
        return cell
    }
}
