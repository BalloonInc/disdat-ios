//
//  MainPVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 31/08/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class MainPVC: UIPageViewController, UIPageViewControllerDataSource {

    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.newVC("QuizVC"),
                self.newVC("DiscoverVC"),
                self.newVC("AchievementsNavigationVC")]
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        
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
