//
//  LanguageSelectorViewController.swift
//  VisionSample
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class LanguageSelectorVC: UIViewController {
    
    @IBOutlet weak var rootLanguagePicker: LanguageSelectionPickerView!
    @IBOutlet weak var newLanguagePicker: LanguageSelectionPickerView!
    @IBOutlet weak var modelSelector: UISegmentedControl!
    
    @IBOutlet weak var nativeLanguageTile: UIView!
    @IBOutlet weak var learningLanguageTile: UIView!
    @IBOutlet weak var readyTile: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTileUI(tile: nativeLanguageTile, id: 1)
        setTileUI(tile: learningLanguageTile, id: 2)
        setTileUI(tile: readyTile, id: 3)
        
        if let patternImage = UIImage(named: "settings_bg_\(Int(arc4random_uniform(2)+1))"){
            self.scrollView.backgroundColor = UIColor(patternImage: patternImage)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newLanguagePicker.selectRow(1, inComponent: 0, animated: false)
        self.newLanguagePicker.selectedLanguageCode = LanguageSelectionPickerView.languageKeys[1]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "languageSelectedSegue"){
            if let destination = segue.destination as? DiscoverVC {
                Authentication.getInstance().setLanguages(rootLanguage: rootLanguagePicker.selectedLanguageCode, learningLanguage: newLanguagePicker.selectedLanguageCode)
                destination.modelName = modelSelector.titleForSegment(at: modelSelector.selectedSegmentIndex)!
                
                DiscoveredWordCollection.setLanguages(rootLanguage: rootLanguagePicker.selectedLanguageCode, learningLanguage: newLanguagePicker.selectedLanguageCode)
            }
        }
    }
    
    func setTileUI(tile: UIView, id: Int){
        tile.layer.cornerRadius = 25;
        tile.layer.masksToBounds = false;
        
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        circleView.layer.cornerRadius = 25;  // half the width/height
        circleView.backgroundColor = UIColor(red: CGFloat(254.0/255), green: CGFloat(217.0/255), blue: CGFloat(77.0/255), alpha: 1.0)
        circleView.center = CGPoint(x: self.view.frame.width/2-tile.frame.origin.x, y: 0)
        
        circleView.layer.borderWidth = 4;
        circleView.layer.borderColor = UIColor.white.cgColor

        tile.addSubview(circleView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        label.text = "\(id)"
        label.textAlignment = .center
        label.center = CGPoint(x: self.view.frame.width/2-tile.frame.origin.x, y: 0)

        tile.addSubview(label)
    }
}
