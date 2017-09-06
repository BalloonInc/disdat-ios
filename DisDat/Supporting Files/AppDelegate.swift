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

import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
     var window: UIWindow?
     
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
          configurePopup()
          FirebaseApp.configure()
          GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
          GIDSignIn.sharedInstance().delegate = self
          
          FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
          
          configureOneSignal(launchOptions: launchOptions)
          Fabric.with([Crashlytics.self])

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
     
     func configurePopup(){
          // Customize dialog appearance
//          let pv = PopupDialogDefaultView.appearance()
//          pv.titleFont    = UIFont(name: "HelveticaNeue-Light", size: 16)!
//          pv.titleColor   = UIColor.white
//          pv.messageFont  = UIFont(name: "HelveticaNeue", size: 14)!
//          pv.messageColor = UIColor(white: 0.8, alpha: 1)
          
          // Customize the container view appearance
          let pcv = PopupDialogContainerView.appearance()
//          pcv.backgroundColor = UIColor(red:0.23, green:0.23, blue:0.27, alpha:1.00)
          pcv.cornerRadius    = 10
//          pcv.shadowEnabled   = true
//          pcv.shadowColor     = UIColor.black
          
          // Customize overlay appearance
//          let ov = PopupDialogOverlayView.appearance()
//          ov.blurEnabled = true
//          ov.blurRadius  = 30
//          ov.liveBlur    = true
//          ov.opacity     = 0.7
//          ov.color       = UIColor.black
          
          // Customize default button appearance
//          let db = DefaultButton.appearance()
//          db.titleFont      = UIFont(name: "HelveticaNeue-Medium", size: 14)!
//          db.titleColor     = UIColor.white
//          db.buttonColor    = UIColor(red:0.25, green:0.25, blue:0.29, alpha:1.00)
//          db.separatorColor = UIColor(red:0.20, green:0.20, blue:0.25, alpha:1.00)
          
          // Customize cancel button appearance
//          let cb = CancelButton.appearance()
//          cb.titleFont      = UIFont(name: "HelveticaNeue-Medium", size: 14)!
//          cb.titleColor     = UIColor(white: 0.6, alpha: 1)
//          cb.buttonColor    = UIColor(red:0.25, green:0.25, blue:0.29, alpha:1.00)
//          cb.separatorColor = UIColor(red:0.20, green:0.20, blue:0.25, alpha:1.00)
          
          // Customize cancel button appearance
//          let desb = DestructiveButton.appearance()
//          desb.titleFont      = UIFont(name: "HelveticaNeue-Medium", size: 14)!
//          desb.titleColor     = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
//          desb.buttonColor    = UIColor(red:0.25, green:0.25, blue:0.29, alpha:1.00)
//          desb.separatorColor = UIColor(red:0.20, green:0.20, blue:0.25, alpha:1.00)
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
               let alert = PopupDialog(title:Constants.error.login, message:error.localizedDescription)
               alert.addButton(DefaultButton(title: Constants.error.tryAgain){
                    LaunchScreenVC.goToViewController(named: "LoginVC", inNav: nil, animated: true)
               })
               getCurrentVC().present(alert, animated: true, completion: nil)
               
               return
          }
          
          guard let authentication = user.authentication else { return }
          let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                         accessToken: authentication.accessToken)
          
          Auth.auth().signIn(with: credential) { (firebaseUser, error) in
               if let error = error {
                    let alert = PopupDialog(title:Constants.error.login, message:error.localizedDescription)
                    alert.addButton(DefaultButton(title: Constants.error.tryAgain){
                         LaunchScreenVC.goToViewController(named: "LoginVC", inNav: nil, animated: true)
                    })
                    self.getCurrentVC().present(alert, animated: true, completion: nil)
                    LaunchScreenVC.loginCompleted(success: false, animated: true)
                    return
               }
               Authentication.getInstance().login(userId: firebaseUser!.uid, fullname: user.profile.name, email: user.profile.email, authenticationMethod: .google)
               LaunchScreenVC.loginCompleted(success: true, animated: true)
          }
     }
     
     func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
          if let error = error {
               let alert = PopupDialog(title:Constants.error.logout, message:error.localizedDescription)
               alert.addButton(DefaultButton(title: "Oops, let me try again!"){})
               getCurrentVC().present(alert, animated: true, completion: nil)
               
               return
          }
          LaunchScreenVC.goToViewController(named: "LoginVC", inNav: nil, animated: true)
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
