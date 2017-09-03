//
//  MainPVCContainer.swift
//  DisDat
//
//  Created by Wouter Devriendt on 31/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class MainPVCContainer: UIViewController {
    
    static var instance: MainPVCContainer?
    
    var activeButtonTag = -1
    
    @IBOutlet weak var barView: UIView!
    @IBOutlet weak var achievementButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var quizButton: UIButton!
    @IBOutlet weak var discoverButton: UIButton!
    
    var buttons: [UIButton]!
    var containerVC: MainPVC?
    
    @IBOutlet weak var containerToBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var t1: NSLayoutConstraint!
    @IBOutlet weak var t2: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttons = [quizButton, discoverButton, achievementButton]
        resize(button: achievementButton, size: .small, withDuration: 0.0)
        resize(button: quizButton, size: .small, withDuration: 0.0)
        resize(button: discoverButton, size: .big, withDuration: 0.0)
        
        MainPVCContainer.instance = self
        toggle(toIndex: 1)
    }
    
    // TODO: remove
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        discoverButton.imageView?.alpha = 0
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
        if toIndex == 1 {
            discoverButton.imageView?.alpha = 0
        }
        else {
            discoverButton.imageView?.alpha = 1
        }

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
    
    func resize(button: UIButton?, size: Size, withDuration: Float){
        if button == nil { return }
        
        UIView.animate(withDuration: TimeInterval(withDuration), animations: {
            let scale = CGFloat(size == .big ? 1 : 0.6)
            button!.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            self.view.setNeedsLayout()
        })
    }
    
    func findButton(withTag: Int) -> UIButton? {
        return buttons.first(where: {$0.tag == withTag})
    }
}


enum Size: CGFloat {
    case big = 60.0
    case small = 40.0
}
