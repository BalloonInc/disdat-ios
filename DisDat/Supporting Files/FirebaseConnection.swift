//
//  FirebaseConnection.swift
//  DisDat
//
//  Created by Wouter Devriendt on 10/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import Firebase

class FirebaseConnection {
    static func saveImageToFirebase(englishWord: String, fullPredictions: [String], image: UIImage, correct: Bool) {
        let auth = Authentication.getInstance()
        let userFolder = auth.isAnonymous ? auth.userId! : auth.email!.sha256()
        
        let storageRef = Storage.storage().reference()
        
        var rootFolder = storageRef.child(correct ? "correct_images" : "false_positives").child(userFolder)
        
        if correct {
            rootFolder = rootFolder.child("\(DiscoveredWordCollection.getInstance()!.rootLanguage)-\(DiscoveredWordCollection.getInstance()!.learningLanguage)")
        }
        var fileName = englishWord
        if !correct {
            fileName += "-\(Date().timeIntervalSinceReferenceDate)"
        }
        
        let imageRef = rootFolder.child(fileName + ".jpg")
        let txtRef = rootFolder.child(fileName + ".json")
        
        let data = UIImageJPEGRepresentation(image.resize(toWidth: 600)!, 0.8)!
        
        let metaData: [String:Any] = ["Predictions":Array(fullPredictions[0...10]),
                                      "Device":UIDevice.current.modelName,
                                      "Orientation":Helpers.getOrientationString(),
                                      "OS version":UIDevice.current.systemVersion,
                                      "Battery level":UIDevice.current.batteryLevel,
                                      "App version":Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                                      "App build number": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String,
                                      "Login Type": Authentication.getInstance().authenticationMethod!.rawValue,
                                      "Email": Authentication.getInstance().email ?? ""
        ]
        
        let fileURL = self.getTempURL(fileName: "metadata_temp.json")
        
        imageRef.putData(data, metadata:nil) { (metadata, error) in
            guard let metadata = metadata else {
                print("Could not upload image: \(error?.localizedDescription ?? "")")
                return
            }
            print("uploaded image to path: \(metadata.downloadURL()?.absoluteString ?? "")")
            
            do {
                let data = try JSONSerialization.data(withJSONObject: metaData, options: [])
                try data.write(to: fileURL!, options: [])
                txtRef.putFile(from: fileURL!, metadata: nil, completion: { (metadata, error) in
                    if let error = error {
                        print("Could not upload text json: \(error.localizedDescription)")
                        return
                    }
                    else {
                        print("File succesfully uploaded at path: \(metadata?.downloadURL()?.absoluteString ?? "")")
                    }
                    try? FileManager.default.removeItem(atPath: fileURL!.path)
                })
            } catch {
                print(error)
            }
        }
    }
    
    static func removeImageFromFirebase(englishWord: String, correct: Bool) {
        let auth = Authentication.getInstance()
        let userFolder = auth.isAnonymous ? auth.userId! : auth.email!.sha256()
        
        let storageRef = Storage.storage().reference()
        
        var rootFolder = storageRef.child(correct ? "correct_images" : "false_positives").child(userFolder)
        
        if correct {
            rootFolder = rootFolder.child("\(DiscoveredWordCollection.getInstance()!.rootLanguage)-\(DiscoveredWordCollection.getInstance()!.learningLanguage)")
        }
        var fileName = englishWord
        if !correct {
            fileName += "-\(Date().timeIntervalSinceReferenceDate)"
        }
        
        let imageRef = rootFolder.child(fileName + ".jpg")
        let txtRef = rootFolder.child(fileName + ".json")

        imageRef.delete { (error) in
            if let err = error {
                print(err)
            }
        }
        txtRef.delete { (error) in
            if let err = error {
                print(err)
            }
        }
    }

    static func getTempURL(fileName: String) -> URL? {
        do {
            let dirURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return dirURL.appendingPathComponent(fileName)
        }
        catch {
            return nil
        }
    }
}
