//
//  Authentication.swift
//  DisDat
//
//  Created by Wouter Devriendt on 26/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import Foundation
import OneSignal

import Firebase
import GoogleSignIn
import PopupDialog

import FBSDKCoreKit
import FBSDKLoginKit

class Authentication{
    
    private static var instance: Authentication?
    
    public private(set) var email: String?
    public private(set) var fullname: String?
    public private(set) var userId: String?
    public private(set) var authenticationMethod: Method?
    
    public private(set) var currentRootLanguage: String?
    public private(set) var currentLearningLanguage: String?
    
    private init(){
    }
    
    static func getInstance() -> Authentication{
        if instance == nil {
            instance = Authentication()
            if let authentication = UserDefaults.standard.value(forKey: "authentication") as? [String: String]{
                instance!.email = authentication["email"]
                instance!.fullname = authentication["fullname"]
                if let authMethodRaw = authentication["authenticationMethod"] {
                    instance!.authenticationMethod = Method(rawValue: authMethodRaw)
                }
            }
            if let languages = UserDefaults.standard.value(forKey: "languages") as? [String: String]{
                instance!.currentRootLanguage = languages["rootLanguage"]
                instance!.currentLearningLanguage = languages["learningLanguage"]
                DiscoveredWordCollection.setLanguages(rootLanguage: languages["rootLanguage"]!, learningLanguage: languages["learningLanguage"]!)
            }
        }
        return instance!
    }
    
    var isAnonymous: Bool {
        return authenticationMethod! == .anonymous
    }
    
    func signInAnonymously(caller: UIViewController, onFinished: @escaping (Bool)->()) {
        Auth.auth().signInAnonymously() { (user, error) in
            if let error = error {
                let alert = PopupDialog(title:NSLocalizedString("Something is wrong. Please try again later or send an email to disdat@ballooninc.be indicating what you experience.",comment:""), message:error.localizedDescription)
                alert.addButton(DefaultButton(title: NSLocalizedString("Ok then...",comment:"")){})
                caller.present(alert, animated: true, completion: nil)
                onFinished(false)
                return
            }
            Authentication.getInstance().login(userId: user!.uid, fullname: nil, email: nil, authenticationMethod: .anonymous)
            onFinished(true)
        }
    }
    
    func signInFacebook(caller: UIViewController, onFinished: @escaping (Bool)->()) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["email"], from: caller, handler: { (result, error) -> Void in
            if error != nil {
                let alert = PopupDialog(title:Constants.error.login, message:error?.localizedDescription)
                alert.addButton(DefaultButton(title: Constants.error.tryAgain){})
                caller.present(alert, animated: true, completion: nil)
            }
            else if let fbloginresult = result {
            if(fbloginresult.grantedPermissions != nil && fbloginresult.grantedPermissions.contains("email"))
                {
                    self.getFBUserData(caller: caller, onFinished: onFinished)
                    return
                }
            }
            onFinished(false)
        })
    }
    
    func getFBUserData(caller: UIViewController, onFinished: @escaping (Bool)->()){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name, email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error != nil){
                    let alert = PopupDialog(title:NSLocalizedString(Constants.error.login, comment:""), message:error?.localizedDescription)
                    alert.addButton(DefaultButton(title: Constants.error.tryAgain){})
                    caller.present(alert, animated: true, completion: nil)
                    onFinished(false)
                }
                else if let res = result as? [String:AnyObject]  {
                    let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                    
                    Auth.auth().signIn(with: credential) { (user, error) in
                        if let error = error {
                            let alert = PopupDialog(title:NSLocalizedString(Constants.error.login, comment:""), message:error.localizedDescription)
                            alert.addButton(DefaultButton(title: Constants.error.tryAgain){})
                            caller.present(alert, animated: true, completion: nil)
                            onFinished(false)
                            return
                        }
                        self.login(userId: user!.uid, fullname: (res["name"] as! String), email: (res["email"] as! String), authenticationMethod: .facebook)
                        onFinished(true)
                    }
                }
            })
        }
        else {
            onFinished(false)
        }
    }

    
    func login(userId: String,fullname: String?, email: String?, authenticationMethod: Method){
        OneSignal.syncHashedEmail(email)

        self.userId = userId
        self.email = email
        self.fullname = fullname
        self.authenticationMethod = authenticationMethod
        var authentication = ["authenticationMethod":authenticationMethod.rawValue]
        if email != nil{
            authentication["email"]=email
        }
        if fullname != nil {
            authentication["fullname"]=fullname
        }
        logUser()
        UserDefaults.standard.set(authentication, forKey: "authentication")
    }
    
    func setLanguages(rootLanguage: String, learningLanguage: String){
        self.currentRootLanguage = rootLanguage
        self.currentLearningLanguage = learningLanguage
        let languages = ["rootLanguage": rootLanguage, "learningLanguage": learningLanguage]
        UserDefaults.standard.set(languages, forKey: "languages")
    }
    
    func logout(){
        self.email = nil
        self.fullname = nil
        self.authenticationMethod = nil
        self.currentRootLanguage = nil
        self.currentLearningLanguage = nil
        logUser()
        UserDefaults.standard.set(nil, forKey: "authentication")
        UserDefaults.standard.set(nil, forKey: "languages")
        DiscoveredWordCollection.getInstance()?.resetProgressForAllLanguages()
    }
    
    func logUser() {
        Crashlytics.sharedInstance().setUserEmail(self.email)
        Crashlytics.sharedInstance().setUserName(self.fullname)
    }

    
    enum Method: String {
        case google = "Google"
        case facebook = "Facebook"
        case anonymous = "Anonymous"
    }
}
