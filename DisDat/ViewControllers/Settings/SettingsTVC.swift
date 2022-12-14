//
//  AchievementsTableViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import PopupDialog
import Firebase
import GoogleSignIn

import FBSDKCoreKit
import FBSDKLoginKit

class SettingsTVC: UITableViewController {
    @IBOutlet weak var fromLanguage: UILabel!
    @IBOutlet weak var toLanguage: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var emailCell: UITableViewCell!
    @IBOutlet weak var removeAccountCell: UITableViewCell!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var loginMethodLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        setContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toggleNavigationBar(hidden: false)
        setNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        toggleNavigationBar(hidden: true)
    }

    fileprivate func toggleNavigationBar(hidden: Bool) {
        UIView.animate(withDuration: 0.15, delay: 0.05, options: [], animations: {
            self.navigationController?.isNavigationBarHidden = hidden
            self.setNavigationBar()
        }, completion: nil)
    }
    
    func setNavigationBar(){
        if let navigationBar = self.navigationController?.navigationBar{
            navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .automatic
            navigationBar.barStyle = .black


            navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
            navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
            navigationBar.isOpaque = true
            navigationBar.barTintColor = #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1)

        }
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
        let alert = PopupDialog(title:NSLocalizedString("Remove account", comment: ""), message:NSLocalizedString("We can delete your account and all data and images linked to it. Are you sure you want this? This will bring you to the e-mail composer.", comment: ""))
        
        alert.addButton(DestructiveButton(title:NSLocalizedString("Yes", comment: "")){
            let email = "disdat@ballooninc.be"
            let subject = "Account deletion"
            let body = "Hi,\n\nI would like request an account removal for \(Authentication.getInstance().email!) (user id: \(Authentication.getInstance().userId!))."
            let encodedParams = "subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if let url = URL(string: "mailto:\(email)?\(encodedParams!)") {
                UIApplication.shared.open(url)
            }
            })
        alert.addButton(CancelButton(title: NSLocalizedString("No", comment: "")){})
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func contactButtonpressed(_ sender: Any) {
        let email = "disdat@ballooninc.be"
        let subject = "About the app DisDat"
        let body = "Hi DisDat team,\n\n ... \n\n Kind regards,\n\(Authentication.getInstance().fullname ?? "")"
        let encodedParams = "subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url = URL(string: "mailto:\(email)?\(encodedParams!)") {
            UIApplication.shared.open(url)
        }
    }
    
    
    @IBAction func changeLanguageButtonPressed(_ sender: UIButton) {
        let alert = PopupDialog(title:NSLocalizedString("Change languages", comment: ""), message:NSLocalizedString("Are you sure you want to change the current languages? Your progress for your current languages will be saved.", comment: ""))
        
        alert.addButton(DefaultButton(title: NSLocalizedString("Yes, let me change languages", comment:"")){
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
        
        if cell.tag == 1 && Authentication.getInstance().email?.isEmpty ?? true {
            return 0
        }
            
         if cell.tag == 2 && Authentication.getInstance().fullname?.isEmpty ?? true {
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
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            let alert = PopupDialog(title:Constants.error.logout, message:signOutError.localizedDescription)
            alert.addButton(DefaultButton(title: Constants.error.tryAgain){})
            self.present(alert, animated: true, completion: nil)
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
            let alert = PopupDialog(title:Constants.error.logout, message:signOutError.localizedDescription)
            alert.addButton(DefaultButton(title: Constants.error.tryAgain){})
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
