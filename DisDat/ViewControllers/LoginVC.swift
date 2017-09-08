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
    @IBOutlet weak var overlayView: UIView!
    
    @IBAction func googleLoginPressed(_ sender: Any) {
        overlayView.isHidden = false
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func facebookLoginPressed(_ sender: Any) {
        overlayView.isHidden = false
        Authentication.getInstance().signInFacebook(caller: self, onFinished: {success in self.loginCompleted(success)})
    }
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        overlayView.isHidden = false
        Authentication.getInstance().signInAnonymously(caller:self, onFinished:{success in self.loginCompleted(success)})
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        GIDSignIn.sharedInstance().uiDelegate = self
        
        setButtonUI(button: googleLoginButton)
        setButtonUI(button: facebookLoginButton)
        
        overlayView.isHidden = true
    }
    
    func setButtonUI(button: UIView){
        button.layer.cornerRadius = 10;
        button.layer.borderWidth = 1;
        button.layer.borderColor = UIColor.white.cgColor
    }
    
    func loginCompleted(_ success: Bool){
        overlayView.isHidden = true
        guard success else { return }
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
