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
    var discoveredIndexes: [Int] = []
    var totalWordCount = 0

    private init(rootLanguage: String, learningLanguage: String){
        self.rootLanguage = rootLanguage
        self.learningLanguage = learningLanguage
        rootLanguageWords = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(rootLanguage)")!
        learningLanguageWords = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(learningLanguage)")!
        totalWordCount = rootLanguageWords.count
    }
    
    static func getInstance() -> DiscoveredWordCollection {
        return instance!
    }
    
    func isDiscovered(index: Int)-> Bool {
        return discoveredIndexes.contains(index)
    }
    
    func discovered(index: Int){
        if !isDiscovered(index: index){
            discoveredIndexes.append(index)
            save()
        }
    }
    
    func resetProgress(){
        discoveredIndexes = []
        save()
    }
    
    private func save(){
        UserDefaults.standard.set(discoveredIndexes, forKey: "\(rootLanguage)-\(learningLanguage)-discovered")
    }
    
    static func setLanguages(rootLanguage: String, learningLanguage: String){
        let localInstance = DiscoveredWordCollection(rootLanguage: rootLanguage, learningLanguage: learningLanguage)
        if let savedDiscoveries = UserDefaults.standard.value(forKey:"\(rootLanguage)-\(learningLanguage)-discovered") as? [Int] {
            localInstance.discoveredIndexes = savedDiscoveries
        }
        instance = localInstance
    }
}
