//
//  LaunchScreenVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 02/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

import Firebase
import GoogleSignIn

import FBSDKCoreKit
import FBSDKLoginKit

import PopupDialog

class LaunchScreenVC: UIViewController {
    let errorLoginMessage: String = NSLocalizedString("An error occurred during login:", comment:"")

    @IBOutlet weak var robotContainer: UIView!
    @IBOutlet var disView: UILabel!
    @IBOutlet var datView: UILabel!
    
    static var animator: UIDynamicAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disView.isHidden = true
        datView.isHidden = true        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGravity()

        reloginIfPossible()
    }
    
    func setupGravity(){
        disView.center = CGPoint(x: disView.center.x, y:-40)
        datView.center = CGPoint(x: datView.center.x, y: -800)
        
        disView.isHidden = false
        datView.isHidden = false

        LaunchScreenVC.animator = UIDynamicAnimator(referenceView: self.view)
        
        let gravity = UIGravityBehavior(items: [disView!,
                                                datView!])
        gravity.gravityDirection = CGVector(dx: 0.0, dy: 1.0)
        gravity.magnitude = 2
        
        let collision = UICollisionBehavior(items: [disView!,datView!])
        
        collision.addBoundary(withIdentifier: "disdatShelf" as NSCopying, for: UIBezierPath(rect: robotContainer.frame))
        
        let behavior = UIDynamicItemBehavior(items: [disView!])
        behavior.elasticity = 0.1
        
        LaunchScreenVC.animator?.addBehavior(behavior)
        
        LaunchScreenVC.animator?.addBehavior(collision)
        LaunchScreenVC.animator?.addBehavior(gravity)
    }
    
    func reloginIfPossible(){
        if let authMethod = Authentication.getInstance().authenticationMethod{
            switch authMethod {
            case .google:
                GIDSignIn.sharedInstance().signInSilently()
                return
            case .facebook:
                if FBSDKAccessToken.current() != nil{
                    Authentication.getInstance().getFBUserData(caller:self, onFinished:{success in
                            LaunchScreenVC.loginCompleted(success: success, animated: true)
                        })
                    return
                }
            case .anonymous:
                Authentication.getInstance().signInAnonymously(caller:self, onFinished:{success in LaunchScreenVC.loginCompleted(success: success, animated: true)})
                return
            }
        }
        LaunchScreenVC.goToViewController(named: "LoginVC", inNav: nil, animated: true)
    }
    
    static func loginCompleted(success: Bool, animated: Bool) {
        if !success {
            goToViewController(named:"LoginVC", inNav: nil, animated: animated)
        }
        if Authentication.getInstance().currentRootLanguage == nil {
            goToViewController(named:"LanguageSelectorVC", inNav: "DisDatNavigationVC", animated: animated)
        }
        else {
            goToViewController(named: "MainPVCContainer", inNav: "DisDatNavigationVC", animated: animated)
        }
    }
    
    static func goToViewController(named: String, inNav: String?, animated:Bool){
        if LaunchScreenVC.animator?.isRunning ?? false{
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100) , execute: {
                goToViewController(named: named, inNav: inNav, animated:animated)
                })
            return
        }
            
        DispatchQueue.global().async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            var newVC = storyboard.instantiateViewController(withIdentifier: named)
            
            if let navigationVCName = inNav {
                let navigationVC = storyboard.instantiateViewController(withIdentifier: navigationVCName) as! UINavigationController
                navigationVC.viewControllers = [storyboard.instantiateViewController(withIdentifier: named)]
                newVC = navigationVC
            }
            
            DispatchQueue.main.async {
                guard let window = UIApplication.shared.keyWindow else { return }

                newVC.view.frame = window.rootViewController?.view.frame ?? UIScreen.main.bounds
                newVC.view.layoutIfNeeded()
                
                UIView.transition(with: window, duration: animated ? 0.3 : 0, options: .transitionFlipFromLeft, animations: {
                    window.rootViewController = newVC
                    window.makeKeyAndVisible()
                })
            }
        }
    }
}
