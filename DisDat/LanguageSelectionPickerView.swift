//
//  LanguageSelectionPickerView.swift
//  VisionSample
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit

class LanguageSelectionPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    static let supportedLanguageKeys = ["nl","en","fr","de","it","es"]
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
        LanguageSelectionPickerView.getSupportedLanguages()
        self.selectedLanguageCode = LanguageSelectionPickerView.languageKeys[0]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return LanguageSelectionPickerView.languageKeys.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return LanguageSelectionPickerView.languageNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedLanguageCode = LanguageSelectionPickerView.languageKeys[row]
    }
    
    static func getSupportedLanguages() {
        for supportedCode in NSLocale.isoLanguageCodes {
            if supportedLanguageKeys.contains(supportedCode){
                let langId = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.languageCode.rawValue:supportedCode])
                let currentLocale = Locale.current
                let langName = currentLocale.localizedString(forLanguageCode: langId)!
                if !languageKeys.contains(langId){
                    languageKeys.append(langId)
                    languageNames.append(langName)
                }
            }
        }
    }
}
