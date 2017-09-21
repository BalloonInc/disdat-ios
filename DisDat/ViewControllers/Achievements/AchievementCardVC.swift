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
import PopupDialog

class AchievementCardVC: UIViewController {
    var englishWord: String?
    var rootLanguageWord: String?
    var learningLanguageWord: String?
    var parentPVC: AchievementCardPVC?

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardImageView: UIImageView!
    
    @IBOutlet weak var translatedLabel: UILabel!
    @IBOutlet weak var rootLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
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
        let language = Locale.current.localizedString(forLanguageCode: DiscoveredWordCollection.getInstance()!.learningLanguage)!
        let objectsToShare = [ cardImageView.image!, String(format:NSLocalizedString("Looks like I just discovered '%@' in %@. Try it yourself? Check disdat.ai! #disdat", comment: ""), learningLanguageWord!, language) ] as [Any]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    @IBAction func removeButtonPressed(_ sender: Any) {
        let alert = PopupDialog(title:NSLocalizedString("Remove discovery", comment: ""), message:NSLocalizedString("Are you sure you want to remove the current word and it's linked image?", comment: ""))
        
        alert.addButton(DestructiveButton(title: NSLocalizedString("Yes", comment:"")){
            DiscoveredWordCollection.getInstance()!.undiscover(englishWord: self.englishWord!)
            FirebaseConnection.removeImageFromFirebase(englishWord: self.englishWord!, correct: true)
            self.removeCurrentCard()
        })
        alert.addButton(CancelButton(title: NSLocalizedString("No", comment: "")){})

        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardView.layer.shadowColor = #colorLiteral(red: 0.1490027606, green: 0.1490303874, blue: 0.1489966214, alpha: 1)

        cardView.layer.shadowOpacity = 0.4;
        cardView.layer.shadowRadius = 3.0;
        cardView.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        
        deleteButton.isHidden = true
        speakerButton.isHidden = true
        shareButton.isHidden = true
        
        let index = DiscoveredWordCollection.getInstance()!.englishLabelDict[englishWord!]!
        rootLanguageWord = DiscoveredWordCollection.getInstance()!.getRootWord(at: index, withArticle: true)
        learningLanguageWord = DiscoveredWordCollection.getInstance()!.getLearningWord(at: index, withArticle: true)
        
        let attributedRootWord = NSMutableAttributedString.init(string: rootLanguageWord!)
        let attributedTranslatedWord = NSMutableAttributedString.init(string: learningLanguageWord!)
        
        attributedRootWord.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1) , range: (rootLanguageWord! as NSString).range(of: rootLanguageWord!))
        attributedTranslatedWord.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) , range: (learningLanguageWord! as NSString).range(of: learningLanguageWord!))
        translatedLabel.text = nil
        rootLabel.text = nil
        
        let rootLanguage = DiscoveredWordCollection.getInstance()!.rootLanguage
        let learningLanguage = DiscoveredWordCollection.getInstance()!.learningLanguage
        
        let auth = Authentication.getInstance()
        let userFolder = auth.isAnonymous ? auth.userId! : auth.email!.sha256()
        
        let storageRef = Storage.storage().reference()
        
        let rootFolder = storageRef.child("correct_images").child(userFolder).child("\(rootLanguage)-\(learningLanguage)")
        
        let imageRef = rootFolder.child(englishWord!+".jpg")
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

                        self.deleteButton.isHidden = false
                        self.speakerButton.isHidden = false
                        self.shareButton.isHidden = false
                        self.cardImageView.isUserInteractionEnabled = true

                        self.translatedLabel.attributedText = attributedTranslatedWord
                        self.rootLabel.attributedText = attributedRootWord
                    })
                }
            }
        })
    }
    
    func removeCurrentCard(){
        var newIndex: Int
        var direction: UIPageViewControllerNavigationDirection
        let currentIndex = parentPVC!.orderedViewControllers.index(of: self)!
        if currentIndex==0{
            newIndex = 0
            direction = .forward
        }
        else {
            newIndex = currentIndex-1
            direction = .reverse
        }
        parentPVC!.orderedViewControllers.remove(at: currentIndex)
        parentPVC!.setViewControllers([parentPVC!.orderedViewControllers[newIndex]], direction: direction, animated: true, completion: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFullSizeImageSegue" {
            if let destVC = segue.destination as? ImageFullScreenViewController{
                destVC.image = cardImageView.image!
            }
        }
    }
}
