//
//  DummyNavigationVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 29/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class DummyNavigationVC: UIViewController {
    
    var didAppearAlready = false
    override func viewDidLoad() {
        performSegue(withIdentifier: "GoToAchievementsSegue", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !didAppearAlready{
            didAppearAlready = true
            return
        }
        
        guard let window = UIApplication.shared.keyWindow else { return }
        guard let rootViewController = window.rootViewController else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "DiscoverVC")
        
        navigationVC.view.frame = rootViewController.view.frame
        navigationVC.view.layoutIfNeeded()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = navigationVC
        })
    }
}
