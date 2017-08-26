//
//  LoginVCViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 20/08/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet weak var googleLoginButton: UIButton!
    @IBOutlet weak var facebookLoginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setButtonUI(button: googleLoginButton)
        setButtonUI(button: facebookLoginButton)
    }

    func setButtonUI(button: UIButton){
        button.layer.cornerRadius = 10;
        button.layer.borderWidth = 1;
        button.layer.borderColor = UIColor.white.cgColor
    }
}
