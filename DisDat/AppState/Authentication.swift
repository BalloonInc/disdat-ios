//
//  Authentication.swift
//  DisDat
//
//  Created by Wouter Devriendt on 26/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import Foundation
import OneSignal

class Authentication{
    
    private static var instance: Authentication?
    
    public private(set) var email: String?
    public private(set) var fullname: String?
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
    
    func login(fullname: String, email: String, authenticationMethod: Method){
        OneSignal.syncHashedEmail(email)

        self.email = email
        self.fullname = fullname
        self.authenticationMethod = authenticationMethod
        let authentication = ["email":email, "fullname":fullname, "authenticationMethod":authenticationMethod.rawValue]
        
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
        UserDefaults.standard.set(nil, forKey: "authentication")
        UserDefaults.standard.set(nil, forKey: "languages")
        DiscoveredWordCollection.getInstance()?.resetProgressForAllLanguages()
    }
    
    enum Method: String {
        case google = "Google"
        case facebook = "Facebook"
        case anonymous = "Anonymous"
    }
}
