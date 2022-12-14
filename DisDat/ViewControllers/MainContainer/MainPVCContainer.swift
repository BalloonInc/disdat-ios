//
//  MainPVCContainer.swift
//  DisDat
//
//  Created by Wouter Devriendt on 31/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import KDCircularProgress

class MainPVCContainer: UIViewController {
    
    static var instance: MainPVCContainer?
    
    var activeButtonTag = -1
    
    @IBOutlet weak var barView: UIView!
    @IBOutlet weak var achievementButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var quizButton: UIButton!
    @IBOutlet weak var discoverButton: KDCircularProgress!
    
    var buttons: [UIView]!
    var containerVC: MainPVC?
    
    @IBOutlet weak var containerToBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var t1: NSLayoutConstraint!
    @IBOutlet weak var t2: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()

        buttons = [quizButton, discoverButton, achievementButton]
        resize(button: achievementButton, size: .small, withDuration: 0.0)
        resize(button: quizButton, size: .small, withDuration: 0.0)
        resize(button: discoverButton, size: .big, withDuration: 0.0)
        
        MainPVCContainer.instance = self
        toggle(toIndex: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mainPVCContentSegue" {
            containerVC = segue.destination as? MainPVC
        }
    }
    
    @IBAction func activateAchievements(_ sender: Any) {
        switchPage(toIndex: 2)
    }
    
    @IBAction func activateDiscover(_ sender: Any) {
        switchPage(toIndex: 1)
    }
    
    @IBAction func activateQuiz(_ sender: Any) {
        switchPage(toIndex: 0)
    }
    
    func switchPage(toIndex: Int){
        let direction: UIPageViewControllerNavigationDirection = activeButtonTag < toIndex ? .forward : .reverse
        containerVC!.setViewControllers([containerVC!.orderedViewControllers[toIndex]], direction: direction, animated: true, completion: nil)
        toggle(toIndex: toIndex)
    }
    
    func toggleTransparentBar(on: Bool, changeHeight: Bool) {
        let height = self.barView.frame.height
        UIView.animate(withDuration: TimeInterval(0.25), animations: {
            if changeHeight {
                self.containerToBottomConstraint.constant = on ? 0 : height
            }
            self.barView.alpha = on ? 0 : 1
            
            self.view.setNeedsLayout()
        })
    }
    
    func toggle(toIndex: Int){
        let button = buttons[toIndex]
        
        let transparent = toIndex == 1
        toggleTransparentBar(on: transparent, changeHeight: false)

        if activeButtonTag == button.tag {
            return
        }
        
        let activeButton = findButton(withTag: activeButtonTag)

        resize(button: activeButton, size: .small, withDuration: 0.25)
        resize(button: button, size: .big, withDuration: 0.25)
        activeButtonTag = button.tag
    }
    
    func resize(button: UIView?, size: Size, withDuration: Float){
        if button == nil { return }
        
        UIView.animate(withDuration: TimeInterval(withDuration), animations: {
            let scale = CGFloat(size == .big ? 1 : 0.6)
            button!.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            self.view.setNeedsLayout()
        })
    }
    
    func findButton(withTag: Int) -> UIView? {
        return buttons.first(where: {$0.tag == withTag})
    }
}


enum Size: CGFloat {
    case big = 45.0
    case small = 30.0
}
