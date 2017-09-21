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
        self.collectionView?.reloadData()

        let cellWidth = 125
        let numberOfCells = Int(self.view.frame.width) / cellWidth
        let spacing = self.view.frame.width - CGFloat(numberOfCells * cellWidth)
        let margin = spacing / CGFloat(numberOfCells)
        
        let collectionViewLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
        
        collectionViewLayout?.sectionInset = UIEdgeInsetsMake(0, margin/2, 0, margin/2)
            
        collectionViewLayout?.invalidateLayout()
        
        self.navigationItem.largeTitleDisplayMode = .automatic
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCategoryDetailSegue"{
            if let destVC = segue.destination as? AchievementDetailContainer {
                if let cell = sender as? AchievementCategoryCell{
                    destVC.englishCategoryText = cell.englishCategoryText
                    destVC.categoryIndex = cell.categoryIndex
                }
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
        
        cell.setContent(englishCategoryText: englishCategoryText, categoryText:categoryText, categoryImage: categoryImage, progressString:progressString )
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionViewHeader", for: indexPath as IndexPath) as! AchievementsHeader
            headerView.reloadUI()
            return headerView
            
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionViewFooter", for: indexPath as IndexPath)
            return footerView
            
        default:
            fatalError("Unexpected element kind in collectionView")
        }
    }
}
