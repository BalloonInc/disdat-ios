//
//  Helpers.swift
//  DisDat
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import Foundation
import UIKit

public class Helpers {    
    static func arrayToReverseDictionary<T>(_ array: [T]) -> [T: Int] {
        var dict: [T: Int] = [:]
        for index in 0...array.count-1 {
            dict[array[index]] = index
        }
        return dict
    }
    
    static func readJson(fileName: String) -> [Any]   {
        do {
            guard let file = Bundle.main.url(forResource: fileName, withExtension: "json") else{
                fatalError("No file")
            }
                
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [Any] {
                    return object
                } else {
                    fatalError("JSON is invalid")
                }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    static func getOrientationString() -> String{
        switch UIDevice.current.orientation {
        case .faceDown:
            return "faceDown"
        case .unknown:
            return "unknown"
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .faceUp:
            return "faceUp"
        }
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
        if self.count < to {
            return self
        }
        return String(self[..<index(from: to)])
    }
}

extension UIImage {
    func resize(toWidth: CGFloat) -> UIImage? {
        
        let scale = toWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: toWidth, height:newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: toWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension CGImage {
    func cropToSquare() -> CGImage?{
        let newDimension = min(self.height, self.width)
        
        let cropRect = CGRect(x: (self.width - newDimension) / 2, y: (self.height - newDimension) / 2, width: newDimension, height: newDimension)
        return self.cropping(to: cropRect)
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

