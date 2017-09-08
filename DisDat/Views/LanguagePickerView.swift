//
//  LanguageSelectionPickerView.swift
//  VisionSample
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import AVFoundation

class LanguagePickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    static let supportedLanguageKeys = ["nl-BE","en-US","fr-FR"]
    static var languageKeys: [String] = []
    static var languageNames: [String] = []
    var selectedLanguageCode = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initClass()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initClass()
    }
    
    func initClass(){
        self.dataSource = self
        self.delegate = self
        LanguagePickerView.getSupportedLanguages()
        self.selectedLanguageCode = LanguagePickerView.languageKeys[0]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return LanguagePickerView.languageKeys.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return LanguagePickerView.languageNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedLanguageCode = LanguagePickerView.languageKeys[row]
    }
    
    static func getSupportedLanguages() {
        for supportedCode in AVSpeechSynthesisVoice.speechVoices() {
            let langId = supportedCode.language
            if supportedLanguageKeys.contains(langId){
                if !languageKeys.contains(langId){
                    languageKeys.append(langId)
                    languageNames.append(Locale.current.localizedString(forLanguageCode: langId)!)
                }
            }
        }
    }
}
