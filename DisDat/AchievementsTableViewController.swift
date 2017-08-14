//
//  AchievementsTableViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit

class AchievementsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DiscoveredWordCollection.getInstance().learningLanguageWords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoveredCell", for: indexPath)
        
        let rootWord = DiscoveredWordCollection.getInstance().learningLanguageWords[indexPath.row]
        let learningWord = DiscoveredWordCollection.getInstance().rootLanguageWords[indexPath.row]

        if DiscoveredWordCollection.getInstance().discoveredIndexes.contains(indexPath.row){
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
