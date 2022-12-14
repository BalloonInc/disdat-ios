//
//  AchievementsNavigationVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 07/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class GeneralNavigationVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.barTintColor = #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1)

        navigationBar.isTranslucent = false
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()

        navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                                                  NSAttributedStringKey.backgroundColor: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1)]

        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                                             NSAttributedStringKey.backgroundColor: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1)]
        
    
        navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        UIBarButtonItem.appearance().tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        navigationBar.setNeedsDisplay()
        setNeedsStatusBarAppearanceUpdate()

    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}
