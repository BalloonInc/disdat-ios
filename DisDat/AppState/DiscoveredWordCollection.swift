//
//  DiscoveredWordCollection.swift
//  DisDat
//
//  Created by Wouter Devriendt on 14/08/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import Foundation

class DiscoveredWordCollection {
    private static var instance: DiscoveredWordCollection?
    
    var rootLanguage = ""
    var learningLanguage = ""
    var rootLanguageWords: [String]
    var learningLanguageWords: [String]
    var discoveredIndexes: [String:[Int]] = [:]
    var totalWordCount = 0

    private init(rootLanguage: String, learningLanguage: String){
        self.rootLanguage = rootLanguage
        self.learningLanguage = learningLanguage
        rootLanguageWords = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(rootLanguage)")!
        learningLanguageWords = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(learningLanguage)")!
        totalWordCount = rootLanguageWords.count
    }
    
    static func getInstance() -> DiscoveredWordCollection? {
        return instance
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
