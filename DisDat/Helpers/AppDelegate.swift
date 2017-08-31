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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        reloginIfPossible()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        if FBSDKApplicationDelegate.sharedInstance().application(application, open:url, options: options){
            return true
        }
        
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: [:])
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
            goToViewController(named: "MainPVC", inNav: "DisDatNavigationVC", storyBoard: "Main", animated: animated)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            let alert = PopupDialog(title:NSLocalizedString("An error occurred during login:", comment:""), message:error.localizedDescription)
            alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
            getCurrentVC().present(alert, animated: true, completion: nil)
            
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        Authentication.getInstance().login(fullname: user.profile.name, email: user.profile.email, authenticationMethod: .google)
        loginCompleted(animated: true)
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
