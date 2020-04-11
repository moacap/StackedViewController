//
//  ViewController.swift
//  StackedViewController
//
//  Created by 狩宿恵介 on 2015/04/23.
//  Copyright (c) 2015年 KeisukeKarijuku. All rights reserved.
//

import UIKit

class ViewController: UIViewController, StackedViewControllerDataSource, StackedViewControllerDelegate {
    
    var stackedViewController: StackedViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        let initialViewController = UIViewController()
        initialViewController.view.backgroundColor = randomColor()
        
        stackedViewController = StackedViewController(viewController: initialViewController)
        if let stackedViewController = stackedViewController {
            stackedViewController.dataSource = self
            stackedViewController.delegate = self
            stackedViewController.view.frame = view.frame
            view.addSubview(stackedViewController.view)
        }
    }
    
    // MARK: StackedViewControllerDataSource
    func viewControllerAfterViewController(stackedViewController: StackedViewController, viewController: UIViewController) -> UIViewController? {
        let viewController = UIViewController()
        viewController.view.backgroundColor = randomColor()
        return viewController
    }
    
    func viewControllerBeforeViewController(stackedViewController: StackedViewController, viewController: UIViewController) -> UIViewController? {
        let viewController = UIViewController()
        viewController.view.backgroundColor = randomColor()
        return viewController
    }
    
    
    // MARK: StackedViewControllerDelegate
    func willTransitionToViewControllers(stackedViewController: StackedViewController, fromViewController: UIViewController) {
        
    }
    
    func didFinishAnimating(stackedViewController: StackedViewController, toViewController: UIViewController?, fromViewController: UIViewController?, direction: StackedViewControllerAnimationDirection) {
        
    }
    
    
    
    // MARK: Color
    func randomColor() -> UIColor {
        return color(red: Int(arc4random_uniform(160))+80, green: Int(arc4random_uniform(160))+80, blue: Int(arc4random_uniform(160))+80)
    }
    
    func color(red: Int, green: Int, blue: Int) -> UIColor {
        return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1)
    }
    
}

