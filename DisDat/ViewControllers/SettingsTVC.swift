//
//  AchievementsTableViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit
import PopupDialog
import Firebase
import GoogleSignIn

import FBSDKCoreKit
import FBSDKLoginKit

class SettingsTVC: UITableViewController {
    
    @IBOutlet weak var localNavigationBar: UINavigationBar!
    
    @IBOutlet weak var fromLanguage: UILabel!
    @IBOutlet weak var toLanguage: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var emailCell: UITableViewCell!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var loginMethodLabel: UILabel!
    
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
        let anonymousWarning = Authentication.getInstance().authenticationMethod == .anonymous ? " " + NSLocalizedString("Since you are not logged in via Facebook or Google, this means you will lose all progress.", comment: "") : ""
        let alert = PopupDialog(title:NSLocalizedString("Logout", comment: ""), message:NSLocalizedString("Are you sure you want to logout?"+anonymousWarning, comment: ""))
        alert.addButton(DefaultButton(title: NSLocalizedString("Yes, I am done here.", comment:"")){
            self.signout()
        })
        alert.addButton(CancelButton(title: NSLocalizedString("No", comment:"")){})
        
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
            DiscoveredWordCollection.getInstance()!.resetProgress()
            self.setContent()
        })
        alert.addButton(CancelButton(title: NSLocalizedString("No", comment:"")){
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if cell.reuseIdentifier == "EmailCell" && Authentication.getInstance().email == nil {
            return 0
        }
            
         if cell.reuseIdentifier == "NameCell" && Authentication.getInstance().fullname == nil{
            return 0
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    func setContent(){
        nameLabel.text = Authentication.getInstance().fullname
        emailLabel.text = Authentication.getInstance().email
        loginMethodLabel.text = Authentication.getInstance().authenticationMethod?.rawValue
        
        let currentLocale = Locale.current
        fromLanguage.text = currentLocale.localizedString(forLanguageCode: DiscoveredWordCollection.getInstance()!.rootLanguage)
        toLanguage.text = currentLocale.localizedString(forLanguageCode: DiscoveredWordCollection.getInstance()!.learningLanguage)
        let progress = 100*DiscoveredWordCollection.getInstance()!.getCurrentDiscoveredCount() / DiscoveredWordCollection.getInstance()!.totalWordCount
        progressLabel.text = "\(progress)%"
    }
    
    func signout(){
        switch Authentication.getInstance().authenticationMethod! {
        case .google:
            signoutGoogle()
        case .facebook:
            signoutFacebook()
        case .anonymous:
            signoutCompleted()
        }
        
        Authentication.getInstance().logout()
    }
    
    func signoutGoogle(){
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            GIDSignIn.sharedInstance().signOut()
            GIDSignIn.sharedInstance().disconnect()
        } catch let signOutError as NSError {
            let alert = PopupDialog(title:NSLocalizedString("An error occurred during logout:", comment:""), message:signOutError.localizedDescription)
            alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func signoutFacebook(){
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        signoutCompleted()
    }
    
    func signoutCompleted(){
        guard let window = UIApplication.shared.keyWindow else { return }
        guard let rootViewController = window.rootViewController else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
        
        loginVC.view.frame = rootViewController.view.frame
        loginVC.view.layoutIfNeeded()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = loginVC
        })
    }
}