//
//  AchievementCardPVC.swift
//  DisDat
//
//  Created by Wouter Devriendt on 07/09/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit

class AchievementCardPVC: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var categoryIndex: Int?
    var orderedViewControllers: [UIViewController] = []
    
    var pageControl:UIPageControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        configurePageControl()
        
        let englishCategoryWords = DiscoveredWordCollection.getInstance()!.englishLanguageJson[categoryIndex!]["words"] as! [String]
        
        var undiscovered = 0
        for englishWord in englishCategoryWords {
            if DiscoveredWordCollection.getInstance()!.isDiscovered(englishWord: englishWord){
                let achievementCardVC = newVC("AchievementCard") as! AchievementCardVC
                achievementCardVC.englishWord = englishWord
                orderedViewControllers.append(achievementCardVC)
            }
            else {
                undiscovered += 1
            }
        }
        if undiscovered > 0 {
            let undiscoveredVC = newVC("UndiscoveredCard") as! UndiscoveredCardVC
            undiscoveredVC.unknownCount = undiscovered
            orderedViewControllers.append(undiscoveredVC)
        }
        
        
        setViewControllers([orderedViewControllers[0]], direction: .forward, animated: true, completion: nil)
        
    }
    
    private func newVC(_ viewcontrollerID: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewcontrollerID)
    }
    
    
    
    func configurePageControl() {
        pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 50,width: UIScreen.main.bounds.width,height: 50))
        pageControl!.numberOfPages = orderedViewControllers.count
        pageControl!.currentPage = 0
        pageControl!.tintColor = UIColor.black
        pageControl!.pageIndicatorTintColor = UIColor.white
        pageControl!.currentPageIndicatorTintColor = UIColor.black
        view.addSubview(pageControl!)
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
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        pageControl?.currentPage = orderedViewControllers.index(of: pageContentViewController)!
    }
    
}
