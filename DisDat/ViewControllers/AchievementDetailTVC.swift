//
//  AchievementsTableViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class AchievementDetailTVC: UITableViewController {
    var categoryIndex: Int?
    
    var englishCategoryWords: [String]!
    var rootCategoryWords: [String]!
    var learningCategoryWords: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        englishCategoryWords = DiscoveredWordCollection.getInstance()!.englishLanguageJson[categoryIndex!]["words"] as! [String]
        rootCategoryWords = DiscoveredWordCollection.getInstance()!.rootLanguageJson[categoryIndex!]["words"] as! [String]
        learningCategoryWords = DiscoveredWordCollection.getInstance()!.learningLanguageJson[categoryIndex!]["words"] as! [String]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.title = DiscoveredWordCollection.getInstance()?.learningLanguageCategories[categoryIndex!]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rootCategoryWords!.count
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoveredCell", for: indexPath) as! AchievementDetailCell
        
        let englishWord = englishCategoryWords![indexPath.row]
        let rootWord = rootCategoryWords![indexPath.row]
        let learningWord = learningCategoryWords![indexPath.row]

        let discovered = DiscoveredWordCollection.getInstance()!.isDiscovered(englishWord: englishWord)
        
        cell.setContent(englishWord: englishWord, rootWord: rootWord, learningWord: learningWord, discovered:discovered)
    
        return cell
    }
}
