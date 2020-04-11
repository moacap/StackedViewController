//
//  StackedViewController.swift
//  Roadshow
//
//  Created by Keisuke Karijuku on 2014/12/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

import UIKit


enum StackedViewControllerAnimationDirection: Int {
    case Visible = 0
    case After
    case Before
}

protocol StackedViewControllerDataSource {
    func viewControllerBeforeViewController(stackedViewController: StackedViewController, viewController: UIViewController) -> UIViewController?
    func viewControllerAfterViewController(stackedViewController: StackedViewController, viewController: UIViewController) -> UIViewController?
}


protocol StackedViewControllerDelegate {
    func willTransitionToViewControllers(stackedViewController: StackedViewController, fromViewController: UIViewController)
    func didFinishAnimating(stackedViewController: StackedViewController, toViewController: UIViewController?, fromViewController: UIViewController?, direction: StackedViewControllerAnimationDirection)
}


class StackedViewController: UIViewController {
    
    var dataSource : StackedViewControllerDataSource?
    var delegate : StackedViewControllerDelegate?
    
    private var initialViewController: UIViewController?
    
    var visibleViewController: UIViewController?
    var beforeViewController: UIViewController?
    var afterViewController: UIViewController?
    
    private var overrayView: UIView?
    
    var panGestureRecognizer: UIPanGestureRecognizer?
    
    private var animationSizeDiff: CGFloat = 0.15
    private var animationAlphaDiff: CGFloat = 0.775
    private var animationDuration: CGFloat = 0.4
    private var animationBounceSize: CGFloat = 0.2
    
    private var isTransitioningVisibleViewController: Bool = false
    private var isTransitioningAfterViewController: Bool = false
    private var isTransitioningBeforeViewController: Bool = false
    
    convenience init(viewController: UIViewController) {
        self.init()
        initialViewController = viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        view.isMultipleTouchEnabled = false
        view.isExclusiveTouch = true
        
        if let initialViewController = initialViewController {
            addChild(initialViewController)
            
            initialViewController.view.frame = view.bounds
            view.addSubview(initialViewController.view)
            
            initialViewController.didMove(toParent: self)
            
            visibleViewController = initialViewController
            self.initialViewController = nil
            
            loadBeforeViewController()
            loadAfterViewController()
        }
        else {
            if let visibleViewController = visibleViewController {
                visibleViewController.view.frame = view.bounds
                view.addSubview(visibleViewController.view)
            }
        }
        
        overrayView = UIView()
        if let overrayView = overrayView {
            overrayView.alpha = 0
            overrayView.backgroundColor = UIColor.black
            overrayView.frame = view.bounds
            view.addSubview(overrayView)
        }
        
        panGestureRecognizer = UIPanGestureRecognizer()
        if let panGestureRecognizer = panGestureRecognizer {
            panGestureRecognizer.addTarget(self, action: Selector("handlePanGestureRecognizer:"))
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    
    // MARK: ChildViewController
    func loadAfterViewController() {
        if afterViewController == nil {
            if let visibleViewController = visibleViewController {
                if let viewController = dataSource?.viewControllerAfterViewController(stackedViewController: self, viewController: visibleViewController) {
                    addChild(viewController)
                    viewController.didMove(toParent: self)
                    afterViewController = viewController
                }
            }
        }
    }
    
    func loadBeforeViewController() {
        if beforeViewController == nil {
            if let visibleViewController = visibleViewController {
                if let viewController = dataSource?.viewControllerBeforeViewController(stackedViewController: self, viewController: visibleViewController) {
                    addChild(viewController)
                    viewController.didMove(toParent: self)
                    beforeViewController = viewController
                }
            }
        }
    }
    
    // MARK: UIPanGestureRecognizer
    func handlePanGestureRecognizer(panGestureRecognizer: UIPanGestureRecognizer) {
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        let translation = panGestureRecognizer.translation(in: view)
        var horizontalDiff = -translation.x
        var progress = horizontalDiff / screenWidth
        let velocity = panGestureRecognizer.velocity(in: view).x
        
        switch panGestureRecognizer.state {
        case UIGestureRecognizerState.began:
            
            prepareForAnimation()
            
            loadAfterViewController()
            loadBeforeViewController()
            
        case UIGestureRecognizerState.changed:
            if horizontalDiff >= 0 {
                progress = pow(abs(progress), 2)
                
                prepareForAnimateToAfterViewController()
                
                if let afterViewController = self.afterViewController {
                    visibleViewController?.view.frame = CGRect(x: -horizontalDiff, y: 0, width: screenWidth, height: screenHeight)
                    
                    let width = screenWidth * ((1 - animationSizeDiff) + progress * animationSizeDiff)
                    let height = screenHeight * ((1 - animationSizeDiff) + progress * animationSizeDiff)
                    let x = (screenWidth - width)/2
                    let y = (screenHeight - height)/2
                    afterViewController.view.frame = CGRect(x: x, y: y, width: width, height: height)
                    afterViewController.view.alpha = (1 - animationAlphaDiff) + progress * animationAlphaDiff
                }
                else {
                    visibleViewController?.view.frame = CGRect(x: -(horizontalDiff * animationBounceSize), y: 0, width: screenWidth, height: screenHeight)
                }
                
                if let visibleViewController = visibleViewController {
                    overrayView?.frame = visibleViewController.view.frame
                    overrayView?.alpha = progress * animationAlphaDiff
                }
                
                visibleViewController?.view.alpha = 1
                beforeViewController?.view.alpha = 0
            }
            else {
                
                prepareForAnimateToBeforeViewController()
                
                if let beforeViewController = self.beforeViewController {
                    progress = pow(abs(progress), 0.5)
                    
                    let width = screenWidth * (1 - progress * animationSizeDiff)
                    let height = screenHeight * (1 - progress * animationSizeDiff)
                    let x = (screenWidth - width)/2
                    let y = (screenHeight - height)/2
                    visibleViewController?.view.frame = CGRect(x: x, y: y, width: width, height: height)
                    visibleViewController?.view.alpha = 1 - progress * animationAlphaDiff
                    
                    beforeViewController.view.frame = CGRect(x: -(screenWidth + horizontalDiff), y: 0, width: screenWidth, height: screenHeight)
                    beforeViewController.view.alpha = 1
                }
                else {
                    progress = abs(progress) * (1 - animationBounceSize)
                    
                    let width = screenWidth * (1 - progress * animationSizeDiff)
                    let height = screenHeight * (1 - progress * animationSizeDiff)
                    let x = (screenWidth - width)/2
                    let y = (screenHeight - height)/2
                    visibleViewController?.view.frame = CGRect(x: x, y: y, width: width, height: height)
                    visibleViewController?.view.alpha = 1 - progress * animationAlphaDiff
                }
                
                afterViewController?.view.alpha = 0
            }
            
        case UIGestureRecognizerState.cancelled:
            fallthrough
            
        case UIGestureRecognizerState.failed:
            fallthrough
            
        case UIGestureRecognizerState.ended:
            if horizontalDiff >= 0 {
                if afterViewController == nil || (horizontalDiff < screenWidth / 3 && velocity > -500) {
                    self.animateToVisibleViewController(progress: progress)
                }
                else {
                    self.animateToAfterViewcontroller(progress: progress)
                }
            }
            else {
                if beforeViewController == nil || (-horizontalDiff < screenWidth / 3 && velocity < 500) {
                    self.animateToVisibleViewController(progress: progress)
                }
                else {
                    self.animateToBeforeViewController(progress: progress)
                }
            }
            
        default:
            break
        }
    }
    
    
    // MARK: Animation
    private func prepareForAnimation() {
        
        if let visibleViewController = visibleViewController {
            delegate?.willTransitionToViewControllers(stackedViewController: self, fromViewController: visibleViewController)
        }
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        if isTransitioningVisibleViewController == false {
            isTransitioningVisibleViewController = true
            visibleViewController?.beginAppearanceTransition(false, animated: true)
        }
        
        beforeViewController?.view.frame = CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight)
        beforeViewController?.view.alpha = 1
        
        if let visibleViewController = visibleViewController {
            overrayView?.frame = visibleViewController.view.frame
        }
        overrayView?.alpha = 0
        if let overrayView = overrayView {
            view.bringSubviewToFront(overrayView)
        }
        
        let width = screenWidth * (1 - animationSizeDiff)
        let height = screenHeight * (1 - animationSizeDiff)
        let x = (screenWidth - width)/2
        let y = (screenHeight - height)/2
        afterViewController?.view.frame = CGRect(x: x, y: y, width: width, height: height)
        afterViewController?.view.alpha = 1 - animationAlphaDiff
    }
    
    private func animateToAfterViewcontroller(progress: CGFloat) {
        view.isUserInteractionEnabled = false
        
        prepareForAnimateToAfterViewController()
        
        let duration = TimeInterval(animationDuration * (1 - progress * 0.5))
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {
            self.afterViewController?.view.alpha = 1
            self.afterViewController?.view.frame = self.view.bounds
            
            let screenWidth = self.view.bounds.width
            let screenHeight = self.view.bounds.height
            let frame = CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight)
            self.visibleViewController?.view.frame = frame
            
            self.overrayView?.frame = frame
            self.overrayView?.alpha = self.animationAlphaDiff
            
            }, completion:{ (finished: Bool) in
                self.visibleViewController?.willMove(toParent: nil)
                self.visibleViewController?.view.removeFromSuperview()
                self.endViewControllerTransition()
                self.visibleViewController?.removeFromParent()
                
                if let beforeViewController = self.beforeViewController {
                    beforeViewController.willMove(toParent: nil)
                    beforeViewController.view.removeFromSuperview()
                    beforeViewController.removeFromParent()
                }
                self.beforeViewController = self.visibleViewController
                self.visibleViewController = self.afterViewController
                self.afterViewController = nil
                self.loadAfterViewController()
                
                self.view.isUserInteractionEnabled = true
                
                if let toViewController = self.visibleViewController {
                    if let fromViewController = self.beforeViewController {
                        self.delegate?.didFinishAnimating(stackedViewController: self, toViewController: toViewController, fromViewController: fromViewController, direction: .After)
                    }
                }
        })
    }
    
    private func animateToBeforeViewController(progress: CGFloat) {
        view.isUserInteractionEnabled = false
        
        prepareForAnimateToBeforeViewController()
        
        let duration = TimeInterval(animationDuration * (1 - progress * 0.5))
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
            self.beforeViewController?.view.frame = self.view.bounds
            self.beforeViewController?.view.alpha = 1
            
            let screenWidth = self.view.bounds.width
            let screenHeight = self.view.bounds.height
            let width = screenWidth * (1 - self.animationSizeDiff)
            let height = screenHeight * (1 - self.animationSizeDiff)
            let frame = CGRect(x: (screenWidth - width)/2, y: (screenHeight - height)/2, width: width, height: height)
            self.visibleViewController?.view.frame = frame
            self.visibleViewController?.view.alpha = 1 - self.animationAlphaDiff
            
            }, completion:{ (finished: Bool) in
                self.visibleViewController?.willMove(toParent: nil)
                self.visibleViewController?.view.removeFromSuperview()
                self.endViewControllerTransition()
                self.visibleViewController?.removeFromParent()
                
                if let afterViewController = self.afterViewController {
                    afterViewController.willMove(toParent: nil)
                    afterViewController.view.removeFromSuperview()
                    afterViewController.removeFromParent()
                }
                self.afterViewController = self.visibleViewController
                self.visibleViewController = self.beforeViewController
                self.beforeViewController = nil
                self.loadBeforeViewController()
                
                self.view.isUserInteractionEnabled = true
                
                if let toViewController = self.visibleViewController {
                    if let fromViewController = self.afterViewController {
                        self.delegate?.didFinishAnimating(stackedViewController: self, toViewController: toViewController, fromViewController: fromViewController, direction: .Before)
                    }
                }
        })
    }
    
    private func animateToVisibleViewController(progress: CGFloat) {
        view.isUserInteractionEnabled = false
        
        if isTransitioningAfterViewController == true {
            isTransitioningAfterViewController = false
            afterViewController?.beginAppearanceTransition(false, animated: true)
        }
        if isTransitioningBeforeViewController == true {
            isTransitioningBeforeViewController = false
            beforeViewController?.beginAppearanceTransition(false, animated: true)
        }
        visibleViewController?.beginAppearanceTransition(true, animated: true)
        
        let duration = TimeInterval(animationDuration * (0.5 + abs(progress) * 0.5))
        UIView.animate(withDuration: duration ,delay: 0, options: .curveEaseOut, animations: {
            let frame = self.view.bounds
            self.visibleViewController?.view.frame = self.view.bounds
            self.visibleViewController?.view.alpha = 1.0
            
            self.overrayView?.frame = self.view.bounds
            self.overrayView?.alpha = 0
            
            let screenWidth = self.view.bounds.width
            let screenHeight = self.view.bounds.height
            let width = screenWidth * (1 - self.animationSizeDiff)
            let height = screenHeight * (1 - self.animationSizeDiff)
            let x = ceil(screenWidth - width)/2;
            let y = ceil(screenHeight - height)/2
            self.afterViewController?.view.frame = CGRect(x: x, y: y, width: width, height: height)
            self.afterViewController?.view.alpha = 1 - self.animationAlphaDiff
            
            self.beforeViewController?.view.frame = CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight)
            self.beforeViewController?.view.alpha = 1
            
            }, completion:{ (finished: Bool) in
                self.endViewControllerTransition()
                
                self.view.isUserInteractionEnabled = true
                
                self.delegate?.didFinishAnimating(stackedViewController: self, toViewController: self.visibleViewController, fromViewController: nil, direction: .Visible)
        })
    }
    
    private func endViewControllerTransition() {
        if isTransitioningVisibleViewController == true {
            isTransitioningVisibleViewController = false
            visibleViewController?.endAppearanceTransition()
        }
        if isTransitioningAfterViewController == true {
            isTransitioningAfterViewController = false
            afterViewController?.endAppearanceTransition()
        }
        if let beforeViewController = self.beforeViewController {
            if isTransitioningBeforeViewController == true {
                isTransitioningBeforeViewController = false
                beforeViewController.endAppearanceTransition()
            }
        }
    }
    
    private func prepareForAnimateToAfterViewController() {
        if isTransitioningAfterViewController == false {
            if let afterViewController = self.afterViewController {
                isTransitioningAfterViewController = true
                afterViewController.beginAppearanceTransition(true, animated: true)
            }
        }
        if isTransitioningBeforeViewController == true {
            if let beforeViewController = self.beforeViewController {
                isTransitioningBeforeViewController = false
                beforeViewController.beginAppearanceTransition(false, animated: true)
                beforeViewController.endAppearanceTransition()
            }
        }
        if let afterViewController = self.afterViewController {
            if afterViewController.view.superview == nil {
                view.insertSubview(afterViewController.view, at: 0)
            }
        }
    }
    
    private func prepareForAnimateToBeforeViewController() {
        if isTransitioningBeforeViewController == false {
            if let beforeViewController = self.beforeViewController {
                isTransitioningBeforeViewController = true
                beforeViewController.beginAppearanceTransition(true, animated: true)
            }
        }
        if isTransitioningAfterViewController == true {
            if let afterViewController = self.afterViewController {
                isTransitioningAfterViewController = false
                afterViewController.beginAppearanceTransition(false, animated: true)
                afterViewController.endAppearanceTransition()
            }
        }
        if let beforeViewController = self.beforeViewController {
            if beforeViewController.view.superview == nil {
                view.addSubview(beforeViewController.view)
            }
        }
    }
    
    
    // MARK: Control
    
    func moveAfterViewController(animated: Bool) {
        if afterViewController != nil {
            prepareForAnimation()
            prepareForAnimateToAfterViewController()
            animateToAfterViewcontroller(progress: 0)
        }
    }
    
    func moveBeforeViewController(animated: Bool) {
        if beforeViewController != nil {
            prepareForAnimation()
            prepareForAnimateToBeforeViewController()
            animateToBeforeViewController(progress: 0)
        }
    }
    
    func setVisibleViewController(viewController: UIViewController) {
        
        if let visibleViewController = visibleViewController {
            visibleViewController.willMove(toParent: nil)
            visibleViewController.view.removeFromSuperview()
            visibleViewController.removeFromParent()
        }
        visibleViewController = nil
        
        addChild(viewController)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        
        visibleViewController = viewController
    }
    
    func refreshAfterViewController() {
        if let afterViewController = afterViewController {
            afterViewController.willMove(toParent: nil)
            afterViewController.view.removeFromSuperview()
            afterViewController.removeFromParent()
        }
        afterViewController = nil
        loadAfterViewController()
    }
    
    func refreshBeforeViewController() {
        if let beforeViewController = beforeViewController {
            beforeViewController.willMove(toParent: nil)
            beforeViewController.view.removeFromSuperview()
            beforeViewController.removeFromParent()
        }
        beforeViewController = nil
        loadBeforeViewController()
    }
    
}
