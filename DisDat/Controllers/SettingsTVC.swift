//
//  AchievementsTableViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit
import PopupDialog

class SettingsTVC: UITableViewController {

    @IBOutlet weak var localNavigationBar: UINavigationBar!
    
    @IBOutlet weak var fromLanguage: UILabel!
    @IBOutlet weak var toLanguage: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.localNavigationBar.isHidden=true
        self.navigationController?.isNavigationBarHidden = false
        self.tableView.contentInset = UIEdgeInsetsMake(-self.localNavigationBar.frame.height, 0, 0, 0);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        let alert = PopupDialog(title:NSLocalizedString("Todo", comment: ""), message:NSLocalizedString("Later you will be able to logout here. Swipe down to dismiss.", comment: ""))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func removeAccountButtonPressed(_ sender: UIButton) {
        let alert = PopupDialog(title:NSLocalizedString("Todo", comment: ""), message:NSLocalizedString("Later you will be able to remove your account here. Swipe down to dismiss.", comment: ""))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeLanguageButtonPressed(_ sender: UIButton) {
        let alert = PopupDialog(title:NSLocalizedString("Change languages", comment: ""), message:NSLocalizedString("Are you sure you want to change the current languages? Your progress for your current languages will be saved.", comment: ""))
        
        alert.addButton(DestructiveButton(title: NSLocalizedString("Yes, let me change languages", comment:"")){
            self.performSegue(withIdentifier: "selectLanguageAgainSegue", sender: self)
        })
        alert.addButton(CancelButton(title: NSLocalizedString("No", comment:"")){
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func resetProgressButtonPressed(_ sender: UIButton) {
        let alert = PopupDialog(title:NSLocalizedString("Reset progress", comment: ""), message:NSLocalizedString("Are you sure you want to reset all progress for the current language?", comment: ""))
        
        alert.addButton(DestructiveButton(title: NSLocalizedString("Yes, let me start over", comment:"")){
            DiscoveredWordCollection.getInstance().resetProgress()
            self.setContent()
        })
        alert.addButton(CancelButton(title: NSLocalizedString("No", comment:"")){
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func setContent(){
        let currentLocale = Locale.current
        fromLanguage.text = currentLocale.localizedString(forLanguageCode: DiscoveredWordCollection.getInstance().rootLanguage)
        toLanguage.text = currentLocale.localizedString(forLanguageCode: DiscoveredWordCollection.getInstance().learningLanguage)
        let progress = 100*DiscoveredWordCollection.getInstance().discoveredIndexes.count / DiscoveredWordCollection.getInstance().totalWordCount
        progressLabel.text = "\(progress)%"
    }
}
