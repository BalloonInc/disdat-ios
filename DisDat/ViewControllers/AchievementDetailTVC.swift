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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DiscoveredWordCollection.getInstance()!.learningLanguageWords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoveredCell", for: indexPath)
        
        let rootWord = DiscoveredWordCollection.getInstance()!.learningLanguageWords[indexPath.row]
        let learningWord = DiscoveredWordCollection.getInstance()!.rootLanguageWords[indexPath.row]

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
