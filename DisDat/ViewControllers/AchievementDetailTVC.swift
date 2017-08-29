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
    var rootCategoryWords: [String]!
    var learningCategoryWords: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoveredCell", for: indexPath)
        
        let rootWord = rootCategoryWords![indexPath.row]
        let learningWord = learningCategoryWords![indexPath.row]

        if DiscoveredWordCollection.getInstance()!.isDiscovered(index: indexPath.row){
            cell.textLabel?.text = learningWord
            cell.detailTextLabel?.text = rootWord
        }
        else {
            
            cell.textLabel?.text = learningWord.substring(to: 2)+"..."
            cell.detailTextLabel?.text = rootWord.substring(to: 2)+"..."
        }
        return cell
    }
}
