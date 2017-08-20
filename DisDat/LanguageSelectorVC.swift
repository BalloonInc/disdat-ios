//
//  LanguageSelectorViewController.swift
//  VisionSample
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit

class LanguageSelectorVC: UIViewController {
    
    @IBOutlet weak var rootLanguagePicker: LanguageSelectionPickerView!
    @IBOutlet weak var newLanguagePicker: LanguageSelectionPickerView!
    @IBOutlet weak var modelSelector: UISegmentedControl!
    
    @IBOutlet weak var nativeLanguageTile: UIView!
    @IBOutlet weak var learningLanguageTile: UIView!
    @IBOutlet weak var readyTile: UIView!
    
    
    override func viewDidLoad() {
        setTileUI(tile: nativeLanguageTile, id: 1)
        setTileUI(tile: learningLanguageTile, id: 2)
        setTileUI(tile: readyTile, id: 3)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "languageSelectedSegue"){
            if let destination = segue.destination as? TranslateVC {
                destination.rootLanguage = rootLanguagePicker.selectedLanguageCode
                destination.learningLanguage = newLanguagePicker.selectedLanguageCode
                destination.modelName = modelSelector.titleForSegment(at: modelSelector.selectedSegmentIndex)!
                
                DiscoveredWordCollection.setLanguages(rootLanguage: rootLanguagePicker.selectedLanguageCode, learningLanguage: newLanguagePicker.selectedLanguageCode)
            }
        }
    }
    
    func setTileUI(tile: UIView, id: Int){
        tile.layer.cornerRadius = 5;
        tile.layer.masksToBounds = false;
        
        let circleView = UIView(frame: CGRect(x: tile.frame.origin.x + tile.frame.width/2, y: tile.frame.origin.y, width: 50, height: 50))

        circleView.layer.cornerRadius = 45;  // half the width/height
        circleView.backgroundColor = UIColor.yellow
        tile.addSubview(circleView)
        
        let label = UILabel(frame: circleView.frame)
        label.text = "\(id)"
        
        circleView.addSubview(label)
    }
}
