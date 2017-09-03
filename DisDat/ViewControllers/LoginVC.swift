//
//  LoginVCViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 20/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
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
        Authentication.getInstance().signInFacebook(caller: self, onFinished: {self.loginCompleted()})
    }
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        Authentication.getInstance().signInAnonymously(caller:self, onFinished:{self.loginCompleted()})
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
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "LanguageSelectorVC")
        
        navigationVC.view.frame = rootViewController.view.frame
        navigationVC.view.layoutIfNeeded()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = navigationVC
        })
    }
}
