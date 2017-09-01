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

        reloginIfPossible()
        
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
    
    func reloginIfPossible(){
        if let authMethod = Authentication.getInstance().authenticationMethod{
            switch authMethod {
            case .google:
                goToViewController(named: "LaunchVC", inNav: nil, storyBoard: "LaunchScreen", animated: false)
                GIDSignIn.sharedInstance().signInSilently()
                return
            case .facebook:
                if FBSDKAccessToken.current() != nil{
                    loginCompleted(animated: false)
                    return
                }
            case .anonymous:
                loginCompleted(animated: false)
                return
            }
        }
        goToViewController(named: "LoginVC", inNav: nil, storyBoard: "Main", animated: false)
    }
    
    func loginCompleted(animated: Bool) {
        if Authentication.getInstance().currentRootLanguage == nil {
            goToViewController(named:"LanguageSelectorVC", inNav: "DisDatNavigationVC", storyBoard: "Main", animated: animated)
        }
        else {
            goToViewController(named: "MainPVCContainer", inNav: "DisDatNavigationVC", storyBoard: "Main", animated: animated)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            let alert = PopupDialog(title:errorLoginMessage, message:error.localizedDescription)
            alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
            getCurrentVC().present(alert, animated: true, completion: nil)
            
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (firebaseUser, error) in
            if let error = error {
                let alert = PopupDialog(title:self.errorLoginMessage, message:error.localizedDescription)
                alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
                self.getCurrentVC().present(alert, animated: true, completion: nil)
                return
            }
            print("firebase user: \(firebaseUser!.displayName ?? "")")
            print("Google user: \(user.profile.name)")
            print("firebase email: \(firebaseUser!.email ?? "")")
            print("Google email: \(user.profile.email)")

            Authentication.getInstance().login(fullname: user.profile.name, email: user.profile.email, authenticationMethod: .google)
            self.loginCompleted(animated: true)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            let alert = PopupDialog(title:NSLocalizedString("An error occurred during logout:", comment:""), message:error.localizedDescription)
            alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
            getCurrentVC().present(alert, animated: true, completion: nil)
            
            return
        }
        goToViewController(named: "LoginVC", inNav: nil, storyBoard: "Main", animated: true)
    }
    
    func goToViewController(named: String, inNav: String?, storyBoard: String, animated:Bool){
        if self.window == nil {
            self.window = UIWindow(frame: UIScreen.main.bounds)
        }
        let window = self.window!
        
        let storyboard = UIStoryboard(name: storyBoard, bundle: nil)
        
        var newVC = storyboard.instantiateViewController(withIdentifier: named)
        
        if let navigationVCName = inNav {
            let navigationVC = storyboard.instantiateViewController(withIdentifier: navigationVCName) as! UINavigationController
            navigationVC.viewControllers = [storyboard.instantiateViewController(withIdentifier: named)]
            newVC = navigationVC
        }
        
        newVC.view.frame = window.rootViewController?.view.frame ?? UIScreen.main.bounds
        newVC.view.layoutIfNeeded()

        UIView.transition(with: window, duration: animated ? 0.3 : 0, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = newVC
            window.makeKeyAndVisible()
        })
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
