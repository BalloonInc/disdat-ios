//
//  Helpers.swift
//  DisDat
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import Foundation

class Helpers {
    static func arrayFromContentsOfFileWithName(fileName: String) -> [String]? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "txt") else {
            return nil
        }
        
        do {
            let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
            return content.components(separatedBy: "\n")
        } catch _ as NSError {
            return nil
        }
    }
    
    static func arrayToReverseDictionary<T>(_ array: [T]) -> [T: Int] {
        var dict: [T: Int] = [:]
        for index in 0...array.count-1 {
            dict[array[index]] = index
        }
        return dict
    }
}

extension Date {
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
}

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(to: Int) -> String {
        if self.characters.count < to {
            return self
        }
         let toIndex = index(from: to)
        return substring(to: toIndex)
    }
}
