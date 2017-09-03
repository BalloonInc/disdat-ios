//
//  AppDelegate.swift
//  VisionSample
//
//  Created by chris on 19/06/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

import FBSDKCoreKit
import FBSDKLoginKit
import PopupDialog
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    let errorLoginMessage: String = NSLocalizedString("An error occurred during login:", comment:"")

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
     
        configureOneSignal(launchOptions: launchOptions)
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        if FBSDKApplicationDelegate.sharedInstance().application(application, open:url, options: options){
            return true
        }
        
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: [:])
    }
    
    func configureOneSignal(launchOptions: [UIApplicationLaunchOptionsKey: Any]?){
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "__ONESIGNAL_APP_ID__",
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            let alert = PopupDialog(title:errorLoginMessage, message:error.localizedDescription)
            alert.addButton(DefaultButton(title: Constants.error.tryAgain){
               LaunchScreenVC.goToViewController(named: "LoginVC", inNav: nil, storyBoard: "Main", animated: true)
            })
            getCurrentVC().present(alert, animated: true, completion: nil)
            
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (firebaseUser, error) in
            if let error = error {
                let alert = PopupDialog(title:self.errorLoginMessage, message:error.localizedDescription)
                alert.addButton(DefaultButton(title: Constants.error.tryAgain){
                    LaunchScreenVC.goToViewController(named: "LoginVC", inNav: nil, storyBoard: "Main", animated: true)
                })
                self.getCurrentVC().present(alert, animated: true, completion: nil)
                return
            }

            Authentication.getInstance().login(fullname: user.profile.name, email: user.profile.email, authenticationMethod: .google)
            LaunchScreenVC.loginCompleted(animated: true)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            let alert = PopupDialog(title:NSLocalizedString("An error occurred during logout:", comment:""), message:error.localizedDescription)
            alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
            getCurrentVC().present(alert, animated: true, completion: nil)
            
            return
        }
        LaunchScreenVC.goToViewController(named: "LoginVC", inNav: nil, storyBoard: "Main", animated: true)
    }
    
    func getCurrentVC() -> UIViewController{
        guard let wd = UIApplication.shared.delegate?.window else {
            fatalError("No delegate window. Oops.")
        }
        var vc = wd!.rootViewController
        if(vc is UINavigationController){
            vc = (vc as! UINavigationController).visibleViewController
            
        }
        guard let resultingVC = vc else {
            fatalError("No viewcontroller shown. Oops.")
        }
        
        return resultingVC
    }
}
