//
//  MainPVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 31/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class MainPVC: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var orderedViewControllers: [UIViewController]!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        
        self.delegate = self
        self.orderedViewControllers = [newVC("QuizVC"), newVC("DiscoverVC"), newVC("AchievementsNavigationVC")]
        setViewControllers([orderedViewControllers[1]], direction: .forward, animated: true, completion: nil)
    }
    
    private func newVC(_ viewcontrollerID: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewcontrollerID)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            MainPVCContainer.instance?.toggle(toIndex: orderedViewControllers.index(of: viewControllers!.last!)!)
        }
        else {
            MainPVCContainer.instance?.toggle(toIndex: orderedViewControllers.index(of: previousViewControllers.last!)!)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        MainPVCContainer.instance?.toggleTransparentBar(on: false, changeHeight: false)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
}
