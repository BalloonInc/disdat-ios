//
//  LanguageSelectorViewController.swift
//  VisionSample
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit

class LanguageSelectorViewController: UIViewController {    
    
    @IBOutlet weak var rootLanguagePicker: LanguageSelectionPickerView!
    @IBOutlet weak var newLanguagePicker: LanguageSelectionPickerView!
    @IBOutlet weak var modelSelector: UISegmentedControl!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "languageSelectedSegue"){
            if let destination = segue.destination as? TranslateViewController {
                destination.rootLanguage = rootLanguagePicker.selectedLanguageCode
                destination.learningLanguage = newLanguagePicker.selectedLanguageCode
                destination.modelName = modelSelector.titleForSegment(at: modelSelector.selectedSegmentIndex)!
            }
        }
    }
}
