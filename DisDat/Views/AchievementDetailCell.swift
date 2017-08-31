//
//  AchievementDetailCell.swift
//  DisDat
//
//  Created by Wouter Devriendt on 30/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import AVKit

class AchievementDetailCell: UITableViewCell {
    var discovered = false

    @IBOutlet weak var translatedWordLabel: UILabel!
    @IBOutlet weak var originalWordLabel: UILabel!
    @IBOutlet weak var discoveredWordImageView: UIImageView!
    @IBOutlet weak var speakerButton: UIButton!
    
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
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)

            if let dirPath = paths.first
            {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(englishWord).png")
                self.discoveredWordImageView?.image = UIImage(contentsOfFile: imageURL.path)
            }
        }
        else {
            self.originalWordLabel.text = nil
            self.translatedWordLabel.text = NSLocalizedString("Unknown", comment: "word still to discover")
            self.discoveredWordImageView?.image = UIImage(named: "box")
        }
    }
    
    func clear(){
        self.translatedWordLabel.text = nil
        self.originalWordLabel.text = nil
        self.discoveredWordImageView.image = nil
        self.speakerButton.isHidden = true
    }
}
