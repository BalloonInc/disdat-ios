//
//  DiscoveredWordCollection.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import Foundation

class DiscoveredWordCollection {
    private static var instance: DiscoveredWordCollection?
    
    var rootLanguage = ""
    var learningLanguage = ""
    
    var englishLanguageJson: [[String:Any]]
    var englishLanguageWords: [String]
    var englishLanguageCategories: [String]
    
    var englishLabelDict: [String:Int] = [:]
    
    var rootLanguageJson: [[String:Any]]
    var rootLanguageWords: [String]
    var rootLanguageCategories: [String]

    var learningLanguageJson: [[String:Any]]
    var learningLanguageWords: [String]
    var learningLanguageCategories: [String]
    
    var discoveredIndexes: [String:[Int]] = [:]
    var totalWordCount = 0

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
        if let indexesForCurrentLanguageSet = discoveredIndexes["\(rootLanguage)-\(learningLanguage)-discovered"]{
            return indexesForCurrentLanguageSet.contains(englishLabelDict[englishWord]!)
        }
        return false
    }
    
    func isDiscovered(index: Int)-> Bool {
        if let indexesForCurrentLanguageSet = discoveredIndexes["\(rootLanguage)-\(learningLanguage)-discovered"]{
            return indexesForCurrentLanguageSet.contains(index)
        }
        return false
    }
    
    func discovered(index: Int){
        if !isDiscovered(index: index){
            if discoveredIndexes["\(rootLanguage)-\(learningLanguage)-discovered"] == nil {
                discoveredIndexes["\(rootLanguage)-\(learningLanguage)-discovered"] = []
            }

            discoveredIndexes["\(rootLanguage)-\(learningLanguage)-discovered"]!.append(index)
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
    
    func getCurrentDiscoveredCount() -> Int{
        return discoveredIndexes["\(rootLanguage)-\(learningLanguage)-discovered"]?.count ?? 0
    }
    
    func resetProgress(){
        discoveredIndexes["\(rootLanguage)-\(learningLanguage)-discovered"] = []
        save()
    }
    
    func resetProgressForAllLanguages(){
        discoveredIndexes = [:]
        save()
    }
    
    private func save(){
        UserDefaults.standard.set(discoveredIndexes, forKey: "\(rootLanguage)-\(learningLanguage)-discovered")
    }
    
    static func setLanguages(rootLanguage: String, learningLanguage: String){
        let localInstance = DiscoveredWordCollection(rootLanguage: rootLanguage, learningLanguage: learningLanguage)
        if let savedDiscoveries = UserDefaults.standard.value(forKey:"\(rootLanguage)-\(learningLanguage)-discovered") as? [String:[Int]] {
            localInstance.discoveredIndexes = savedDiscoveries
        }
        instance = localInstance
    }
}
