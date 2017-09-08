//
//  AchievementCardViewController.swift
//  DisDat
//
//  Created by Wouter Devriendt on 07/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import Firebase
import AVKit
import Kingfisher

class AchievementCardVC: UIViewController {
    var englishWord: String?
    var rootLanguageWord: String?
    var learningLanguageWord: String?

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardImageView: UIImageView!
    
    @IBOutlet weak var translatedLabel: UILabel!
    @IBOutlet weak var rootLabel: UILabel!
    
    @IBOutlet weak var placeholder1: UIView!
    @IBOutlet weak var placeholder2: UIView!
    @IBOutlet weak var placeholder3: UIView!
    @IBOutlet weak var placeholder4: UIView!
    @IBOutlet weak var placeholder5: UIView!
    
    lazy var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBAction func speakerButtonPressed(_ sender: UIButton) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let speechUtterance = AVSpeechUtterance(string: learningLanguageWord!)
            speechUtterance.voice  = AVSpeechSynthesisVoice(language: DiscoveredWordCollection.getInstance()!.learningLanguage)
            self.speechSynthesizer.speak(speechUtterance)
        }
        catch let error as NSError {
            print("Error: error activating speech: \(error), \(error.userInfo)")
        }
    }

    @IBAction func shareImageButton(_ sender: UIButton) {
        let objectsToShare = [ cardImageView.image!, String(format:NSLocalizedString("Looks like I just discovered %s in %s. Try it yourself? Check disdat.ai!", comment: ""), learningLanguageWord!, DiscoveredWordCollection.getInstance()!.learningLanguage) ] as [Any]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardView.layer.shadowColor = #colorLiteral(red: 0.1490027606, green: 0.1490303874, blue: 0.1489966214, alpha: 1)

        cardView.layer.shadowOpacity = 0.3;
        cardView.layer.shadowRadius = 1.0;
        cardView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        
        let index = DiscoveredWordCollection.getInstance()!.englishLabelDict[englishWord!]!
        rootLanguageWord = DiscoveredWordCollection.getInstance()!.rootLanguageWords[index]
        learningLanguageWord = DiscoveredWordCollection.getInstance()!.learningLanguageWords[index]

        let attributedRootWord = NSMutableAttributedString.init(string: rootLanguageWord!)
        let attributedTranslatedWord = NSMutableAttributedString.init(string: learningLanguageWord!)
        
        attributedRootWord.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1) , range: (rootLanguageWord! as NSString).range(of: rootLanguageWord!))
        attributedTranslatedWord.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) , range: (learningLanguageWord! as NSString).range(of: learningLanguageWord!))
        translatedLabel.text = nil
        rootLabel.text = nil
        
        let rootLanguage = DiscoveredWordCollection.getInstance()!.rootLanguage
        let learningLanguage = DiscoveredWordCollection.getInstance()!.learningLanguage
        
        guard let currentUser = Auth.auth().currentUser else {return}
        
        let storageRef = Storage.storage().reference()
        
        let rootFolder = storageRef.child("correct_images").child(currentUser.uid).child("\(rootLanguage)-\(learningLanguage)")
        
        let imageRef = rootFolder.child(englishWord!+".png")
        imageRef.downloadURL(completion: { (url, error) in
            if let err = error {
                print(err)
            }
            else {
                DispatchQueue.main.async {
                    self.cardImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (_, _, cacheType, _) in

                        print("cached from: \(cacheType)")
                        self.placeholder1.isHidden = true
                        self.placeholder2.isHidden = true
                        self.placeholder3.isHidden = true
                        self.placeholder4.isHidden = true
                        self.placeholder5.isHidden = true

                        self.translatedLabel.attributedText = attributedTranslatedWord
                        self.rootLabel.attributedText = attributedRootWord

                    })
                }
            }
        })
    }
    
    

}
