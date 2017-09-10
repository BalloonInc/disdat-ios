//
//  LanguageSelectionPickerView.swift
//  VisionSample
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import AVFoundation

class LanguagePickerView: UIStackView {
    var languageKeys: [String] = []
    var languageNames: [String] = []
    var elements: [UIButton] = []
    var selectedLanguageCode = ""
    
    fileprivate func setUI() {
        self.axis = .vertical
        self.distribution = .fillEqually
        self.alignment = .center
        self.spacing = 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setUI()
    }
    
    @objc func buttonPressed(_ sender: UIButton){
        selectRow(elements.index(of: sender)!, animated: true)
    }
    
    func selectRow(_ row: Int, animated: Bool){
        selectedLanguageCode = languageKeys[row]
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.elements[row].isSelected = true
            self.elements.filter({$0 != self.elements[row]}).forEach({$0.isSelected = false})
        }
    }
    
    func setSupportedLanguages(_ languages: [String]) {
        elements.removeAll()
        subviews.forEach({ $0.removeFromSuperview() })
        for supportedCode in AVSpeechSynthesisVoice.speechVoices() {
            let langId = supportedCode.language
            if languages.contains(langId){
                if !languageKeys.contains(langId){
                    languageKeys.append(langId)
                    let languageName = Locale.current.localizedString(forLanguageCode: langId)!
                    languageNames.append(languageName)
                    let button = UIButton()
                    let selectedTitle = NSAttributedString(string: languageName, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 20, weight: .bold),NSAttributedStringKey.foregroundColor:#colorLiteral(red: 0.1919409633, green: 0.4961107969, blue: 0.745100379, alpha: 1)])
                    let unselectedTitle = NSAttributedString(string: languageName, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 18, weight: .regular), NSAttributedStringKey.foregroundColor:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)])
                    button.setAttributedTitle(selectedTitle, for: .selected )
                    button.setAttributedTitle(unselectedTitle, for: .normal )
                    button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
                    
                    elements.append(button)
                    self.addArrangedSubview(button)

                    let widthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant:0)
                    
                    NSLayoutConstraint.activate([widthConstraint])
                }
            }
        }
        selectedLanguageCode = languageKeys[0]
        setNeedsLayout()
        setNeedsDisplay()
    }
}
