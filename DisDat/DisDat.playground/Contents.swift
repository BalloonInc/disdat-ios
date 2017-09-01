//: Playground - noun: a place where people can play

import UIKit

let englishLanguageJson =  Helpers.readJson(fileName: "labels_en-US") as! [[String:Any]]

let englishLanguageCategories = englishLanguageJson.map({$0["category"] as! String})
let englishLanguageWords = englishLanguageJson.map({Array($0["words"] as! [String])}).flatMap({$0})

print(englishLanguageCategories)
print(englishLanguageWords)

let cat = englishLanguageJson.first(where: {($0["words"] as! [String]).contains("keyboard")})!["category"]!
print(cat)
