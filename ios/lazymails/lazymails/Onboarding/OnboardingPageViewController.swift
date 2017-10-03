//
//  OnboardingPageViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 3/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//
//  Website: iOS tutorial: Need to create an onboarding flow for your mobile app? Here's how to do it using UIPageViewController in Swift. - Thorn Technologies
//      https://www.thorntech.com/2015/08/need-to-create-an-onboarding-flow-for-your-mobile-app-heres-how-to-do-it-using-uipageviewcontroller-in-swift/

import UIKit

class OnboardingPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        
        // set colors
        view.backgroundColor = UIColor(red: 246.0/255, green: 246.0/255, blue: 246.0/255, alpha: 1)
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = .white
        pageControl.currentPageIndicatorTintColor = UIColor(red: 122.0/255, green: 195.0/255, blue: 246.0/255, alpha: 1)
        
        setViewControllers([getPageOne()], direction: .forward, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getPageOne() -> OnboardingPageOneViewController {
        return storyboard!.instantiateViewController(withIdentifier: "onboardingPageOne") as! OnboardingPageOneViewController
    }
    
    func getPageTwo() -> OnboardingPageTwoViewController {
        return storyboard!.instantiateViewController(withIdentifier: "onboardingPageTwo") as! OnboardingPageTwoViewController
    }
    
    func getPageThree() -> OnboardingPageThreeViewController {
        return storyboard!.instantiateViewController(withIdentifier: "onboardingPageThree") as! OnboardingPageThreeViewController
    }
    

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController is OnboardingPageThreeViewController {
            return getPageTwo()
        } else if viewController is OnboardingPageTwoViewController {
            return getPageOne()
        } else {
            // return nil to prevent further scrolling
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController is OnboardingPageOneViewController {
            return getPageTwo()
        } else if viewController is OnboardingPageTwoViewController {
            return getPageThree()
        } else {
            // return nil to prevent further scrolling
            return nil
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 3
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }

}
