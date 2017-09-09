//
//  DiscoveredWordCollection.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import Foundation
import Firebase

class DiscoveredWordCollection {
    private static var instance: DiscoveredWordCollection?
    
    var rootLanguage = ""
    var learningLanguage = ""
    
    var englishLanguageJson: [[String:Any]]
    var englishLanguageWords: [String]
    var englishLanguageCategories: [String]
    
    var englishLabelDict: [String:Int] = [:]
    
    let englishWordsToExclude = ["ruler"]
    
    var rootLanguageJson: [[String:Any]]
    var rootLanguageWords: [String]
    var rootLanguageCategories: [String]
    
    var learningLanguageJson: [[String:Any]]
    var learningLanguageWords: [String]
    var learningLanguageCategories: [String]
    
    var discoveredWords: [String:[String]] = [:]
    var totalWordCount = 0
    
    var ref = Database.database().reference()
    
    private init(rootLanguage: String, learningLanguage: String){
        self.rootLanguage = rootLanguage
        self.learningLanguage = learningLanguage
        
        englishLanguageJson = Helpers.readJson(fileName: "labels_en-US") as! [[String:Any]]
        englishLanguageCategories = englishLanguageJson.map({$0["category"] as! String})
        englishLanguageWords = englishLanguageJson.map({Array($0["words"]! as! [String])}).flatMap({$0})
        
        englishLabelDict = Helpers.arrayToReverseDictionary(englishLanguageWords)
        
        rootLanguageJson = Helpers.readJson(fileName: "labels_\(rootLanguage)") as! [[String:Any]]
        rootLanguageCategories = rootLanguageJson.map({$0["category"] as! String})
        rootLanguageWords = rootLanguageJson.map({Array($0["words"]! as! [String])}).flatMap({$0})
        
        learningLanguageJson = Helpers.readJson(fileName: "labels_\(learningLanguage)") as! [[String:Any]]
        learningLanguageCategories = learningLanguageJson.map({$0["category"] as! String})
        learningLanguageWords = learningLanguageJson.map({Array($0["words"]! as! [String])}).flatMap({$0})
        
        totalWordCount = rootLanguageWords.count
    }
    
    static func getInstance() -> DiscoveredWordCollection? {
        return instance
    }
    
    func isDiscovered(englishWord: String)-> Bool {
        if let discoveredWordsForCurrentLanguageSet = discoveredWords["\(rootLanguage)-\(learningLanguage)"]{
            return discoveredWordsForCurrentLanguageSet.contains(englishWord)
        }
        return false
    }
    
    func discovered(englishWord: String){
        if !isDiscovered(englishWord: englishWord){
            if discoveredWords["\(rootLanguage)-\(learningLanguage)"] == nil {
                discoveredWords["\(rootLanguage)-\(learningLanguage)"] = []
            }
            
            discoveredWords["\(rootLanguage)-\(learningLanguage)"]!.append(englishWord)
            save()
        }
    }
    
    func getEnglishCategory(word: String) -> String{
        return englishLanguageJson.first(where: {($0["words"] as! [String]).contains(word)})!["category"] as! String
    }
    
    func getRootCategory(word: String) -> String{
        return rootLanguageJson.first(where: {($0["words"] as! [String]).contains(word)})!["category"] as! String
    }
    
    func getLearningCategory(word: String) -> String{
        return learningLanguageJson.first(where: {($0["words"] as! [String]).contains(word)})!["category"] as! String
    }
    
    func getLearningCategory(index: Int) -> String{
        return learningLanguageJson[index]["category"] as! String
    }
    
    func getCurrentDiscoveredCount() -> Int{
        return discoveredWords["\(rootLanguage)-\(learningLanguage)"]?.count ?? 0
    }
    
    func resetProgress(){
        discoveredWords["\(rootLanguage)-\(learningLanguage)"] = []
        save()
    }
    
    func resetProgressForAllLanguages(){
        discoveredWords = [:]
        save()
    }
    
    private func save(){
        if let email = Authentication.getInstance().email{
            self.ref.child("discoveredIndexes").child(email.sha256()).child("discoveries").updateChildValues(discoveredWords)
        }
        else {
            UserDefaults.standard.set(discoveredWords, forKey: "discoveries")
        }
    }
    
    static func setLanguages(rootLanguage: String, learningLanguage: String){
        let localInstance = DiscoveredWordCollection(rootLanguage: rootLanguage, learningLanguage: learningLanguage)
        
        if let email = Authentication.getInstance().email{
            localInstance.ref.child("discoveredIndexes").child(email.sha256()).child("discoveries").observe(.value, with: { (snapshot) in
                localInstance.discoveredWords = snapshot.value as? [String : [String]] ?? [:]
            })
        }
        else {
            if let savedDiscoveries = UserDefaults.standard.value(forKey:"discoveries") as? [String:[String]] {
                localInstance.discoveredWords = savedDiscoveries
            }
        }

        instance = localInstance
    }
}
