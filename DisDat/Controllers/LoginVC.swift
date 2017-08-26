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

class LoginVC: UIViewController, GIDSignInUIDelegate {

    @IBOutlet weak var googleLoginButton: GIDSignInButton!
    @IBOutlet weak var facebookLoginButton: UIButton!
    
    @IBAction func googleLoginPressed(_ sender: Any) {
    }
    
    @IBAction func facebookLoginPressed(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setButtonUI(button: googleLoginButton)
        setButtonUI(button: facebookLoginButton)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }

    func setButtonUI(button: UIView){
        button.layer.cornerRadius = 10;
        button.layer.borderWidth = 1;
        button.layer.borderColor = UIColor.white.cgColor
    }
}
