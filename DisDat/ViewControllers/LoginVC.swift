//
//  LoginVCViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 20/08/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import PopupDialog

import FBSDKCoreKit
import FBSDKLoginKit

class LoginVC: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var googleLoginButton: GIDSignInButton!
    @IBOutlet weak var facebookLoginButton: UIButton!
    
    @IBAction func googleLoginPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func facebookLoginPressed(_ sender: Any) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["email"], from: self, handler: { (result, error) -> Void in
            if error != nil {
                let alert = PopupDialog(title:NSLocalizedString("An error occurred during login:", comment:""), message:error?.localizedDescription)
                alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
                self.present(alert, animated: true, completion: nil)
            }
            else if let fbloginresult = result {
                if(fbloginresult.grantedPermissions.contains("email"))
                {
                    self.getFBUserData()
                }
            }
        })
    }
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        Authentication.getInstance().login(fullname: "", email: "", authenticationMethod: .anonymous)
        loginCompleted()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        
        setButtonUI(button: googleLoginButton)
        setButtonUI(button: facebookLoginButton)
    }
    
    func setButtonUI(button: UIView){
        button.layer.cornerRadius = 10;
        button.layer.borderWidth = 1;
        button.layer.borderColor = UIColor.white.cgColor
    }
    
    func loginCompleted(){
        guard let window = UIApplication.shared.keyWindow else { return }
        guard let rootViewController = window.rootViewController else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "DisDatNavigationVC")
        
        navigationVC.view.frame = rootViewController.view.frame
        navigationVC.view.layoutIfNeeded()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = navigationVC
        })
    }
    
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name, email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error != nil){
                    let alert = PopupDialog(title:NSLocalizedString("An error occurred during login:", comment:""), message:error?.localizedDescription)
                    alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
                    self.present(alert, animated: true, completion: nil)
                }
                else if let res = result as? [String:AnyObject]  {
                    Authentication.getInstance().login(fullname: res["name"] as! String, email: res["email"] as! String, authenticationMethod: .facebook)
                    self.loginCompleted()
                }
            })
        }
    }
}
