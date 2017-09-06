//
//  AchievementDetailCell.swift
//  DisDat
//
//  Created by Wouter Devriendt on 30/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import AVKit
import Kingfisher

import Firebase

class AchievementDetailCell: UITableViewCell {
    var discovered = false
    
    @IBOutlet weak var translatedWordLabel: UILabel!
    @IBOutlet weak var originalWordLabel: UILabel!
    @IBOutlet weak var discoveredWordImageView: UIImageView!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    lazy var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBAction func speakerButtonPressed(_ sender: UIButton) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let speechUtterance = AVSpeechUtterance(string: translatedWordLabel.text!)
            speechUtterance.voice  = AVSpeechSynthesisVoice(language: DiscoveredWordCollection.getInstance()!.learningLanguage)
            self.speechSynthesizer.speak(speechUtterance)
        }
        catch let error as NSError {
            print("Error: error activating speech: \(error), \(error.userInfo)")
        }
    }
    
    func setContent(englishWord: String, rootWord: String, learningWord: String, discovered: Bool){
        self.speakerButton.isHidden = !discovered
        
        if discovered {
            self.originalWordLabel.text = rootWord
            self.translatedWordLabel.text = learningWord
            
            let rootLanguage = DiscoveredWordCollection.getInstance()!.rootLanguage
            let learningLanguage = DiscoveredWordCollection.getInstance()!.learningLanguage
            
            guard let currentUser = Auth.auth().currentUser else {return}
            
            let storageRef = Storage.storage().reference()
            
            let rootFolder = storageRef.child("correct_images").child(currentUser.uid).child("\(rootLanguage)-\(learningLanguage)")
            
            let imageRef = rootFolder.child(englishWord+".png")
            imageRef.downloadURL(completion: { (url, error) in
                if let err = error {
                    print(err)
                    self.activityIndicator.stopAnimating()
                }
                else {
                    DispatchQueue.main.async {
                        self.discoveredWordImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (_, _, cacheType, _) in
                            self.activityIndicator.stopAnimating()
                            print("cached from: \(cacheType)")
                        })
                    }
                }
            })
        }
        else {
            self.originalWordLabel.text = nil
            self.translatedWordLabel.text = NSLocalizedString("Unknown", comment: "word still to discover")
            self.discoveredWordImageView?.image = UIImage(named: "box")
            self.activityIndicator.stopAnimating()
        }
    }
    
    func clear(){
        self.translatedWordLabel.text = nil
        self.originalWordLabel.text = nil
        self.discoveredWordImageView.image = nil
        self.speakerButton.isHidden = true
        self.activityIndicator.startAnimating()
    }
}
