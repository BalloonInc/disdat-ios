//
//  QuizVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 21/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class QuizVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
 

}
