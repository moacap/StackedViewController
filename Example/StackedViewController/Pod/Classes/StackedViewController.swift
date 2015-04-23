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
        
        view.backgroundColor = UIColor.clearColor()
        view.clipsToBounds = true
        view.multipleTouchEnabled = false
        view.exclusiveTouch = true
        
        if let initialViewController = initialViewController {
            addChildViewController(initialViewController)
            
            initialViewController.view.frame = view.bounds
            view.addSubview(initialViewController.view)
            
            initialViewController.didMoveToParentViewController(self)
            
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
            overrayView.backgroundColor = UIColor.blackColor()
            overrayView.frame = view.bounds
            view.addSubview(overrayView)
        }
        
        panGestureRecognizer = UIPanGestureRecognizer()
        if let panGestureRecognizer = panGestureRecognizer {
            panGestureRecognizer.addTarget(self, action: "handlePanGestureRecognizer:")
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    
    // MARK: ChildViewController
    func loadAfterViewController() {
        if afterViewController == nil {
            if let visibleViewController = visibleViewController {
                if let viewController = dataSource?.viewControllerAfterViewController(self, viewController: visibleViewController) {
                    addChildViewController(viewController)
                    viewController.didMoveToParentViewController(self)
                    afterViewController = viewController
                }
            }
        }
    }
    
    func loadBeforeViewController() {
        if beforeViewController == nil {
            if let visibleViewController = visibleViewController {
                if let viewController = dataSource?.viewControllerBeforeViewController(self, viewController: visibleViewController) {
                    addChildViewController(viewController)
                    viewController.didMoveToParentViewController(self)
                    beforeViewController = viewController
                }
            }
        }
    }
    
    // MARK: UIPanGestureRecognizer
    func handlePanGestureRecognizer(panGestureRecognizer: UIPanGestureRecognizer) {
        let screenWidth = CGRectGetWidth(view.bounds)
        let screenHeight = CGRectGetHeight(view.bounds)
        let translation = panGestureRecognizer.translationInView(view)
        var horizontalDiff = -translation.x
        var progress = horizontalDiff / screenWidth
        let velocity = panGestureRecognizer.velocityInView(view).x
        
        switch panGestureRecognizer.state {
        case UIGestureRecognizerState.Began:
            
            prepareForAnimation()
            
            loadAfterViewController()
            loadBeforeViewController()
            
        case UIGestureRecognizerState.Changed:
            if horizontalDiff >= 0 {
                progress = pow(abs(progress), 2)
                
                prepareForAnimateToAfterViewController()
                
                if let afterViewController = self.afterViewController {
                    visibleViewController?.view.frame = CGRectMake(-horizontalDiff, 0, screenWidth, screenHeight)
                    
                    let width = screenWidth * ((1 - animationSizeDiff) + progress * animationSizeDiff)
                    let height = screenHeight * ((1 - animationSizeDiff) + progress * animationSizeDiff)
                    let x = (screenWidth - width)/2
                    let y = (screenHeight - height)/2
                    afterViewController.view.frame = CGRectMake(x.toHalfCGFloat(), y.toHalfCGFloat(), width.toHalfCGFloat(), height.toHalfCGFloat())
                    afterViewController.view.alpha = (1 - animationAlphaDiff) + progress * animationAlphaDiff
                }
                else {
                    visibleViewController?.view.frame = CGRectMake(-(horizontalDiff * animationBounceSize).toHalfCGFloat(), 0, screenWidth.toHalfCGFloat(), screenHeight.toHalfCGFloat())
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
                    visibleViewController?.view.frame = CGRectMake(x.toHalfCGFloat(), y.toHalfCGFloat(), width.toHalfCGFloat(), height.toHalfCGFloat())
                    visibleViewController?.view.alpha = 1 - progress * animationAlphaDiff
                    
                    beforeViewController.view.frame = CGRectMake(-(screenWidth + horizontalDiff).toHalfCGFloat(), 0, screenWidth.toHalfCGFloat(), screenHeight.toHalfCGFloat())
                    beforeViewController.view.alpha = 1
                }
                else {
                    progress = abs(progress) * (1 - animationBounceSize)
                    
                    let width = screenWidth * (1 - progress * animationSizeDiff)
                    let height = screenHeight * (1 - progress * animationSizeDiff)
                    let x = (screenWidth - width)/2
                    let y = (screenHeight - height)/2
                    visibleViewController?.view.frame = CGRectMake(x.toHalfCGFloat(), y.toHalfCGFloat(), width.toHalfCGFloat(), height.toHalfCGFloat())
                    visibleViewController?.view.alpha = 1 - progress * animationAlphaDiff
                }
                
                afterViewController?.view.alpha = 0
            }
            
        case UIGestureRecognizerState.Cancelled:
            fallthrough
            
        case UIGestureRecognizerState.Failed:
            fallthrough
            
        case UIGestureRecognizerState.Ended:
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
            delegate?.willTransitionToViewControllers(self, fromViewController: visibleViewController)
        }
    
        let screenWidth = CGRectGetWidth(view.bounds)
        let screenHeight = CGRectGetHeight(view.bounds)
        
        if isTransitioningVisibleViewController == false {
            isTransitioningVisibleViewController = true
            visibleViewController?.beginAppearanceTransition(false, animated: true)
        }
        
        beforeViewController?.view.frame = CGRectMake(-screenWidth, 0, screenWidth, screenHeight)
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
        afterViewController?.view.frame = CGRectMake(x.toHalfCGFloat(), y.toHalfCGFloat(), width.toHalfCGFloat(), height.toHalfCGFloat())
        afterViewController?.view.alpha = 1 - animationAlphaDiff
    }
    
    private func animateToAfterViewcontroller(#progress: CGFloat) {
        view.userInteractionEnabled = false
        
        prepareForAnimateToAfterViewController()
        
        let duration = NSTimeInterval(animationDuration * (1 - progress * 0.5))
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseIn, animations: {
            self.afterViewController?.view.alpha = 1
            self.afterViewController?.view.frame = self.view.bounds
            
            let screenWidth = CGRectGetWidth(self.view.bounds)
            let screenHeight = CGRectGetHeight(self.view.bounds)
            let frame = CGRectMake(-screenWidth, 0, screenWidth, screenHeight)
            self.visibleViewController?.view.frame = frame
            
            self.overrayView?.frame = frame
            self.overrayView?.alpha = self.animationAlphaDiff
            
            }, completion:{ (finished: Bool) in
                self.visibleViewController?.willMoveToParentViewController(nil)
                self.visibleViewController?.view.removeFromSuperview()
                self.endViewControllerTransition()
                self.visibleViewController?.removeFromParentViewController()
                
                if let beforeViewController = self.beforeViewController {
                    beforeViewController.willMoveToParentViewController(nil)
                    beforeViewController.view.removeFromSuperview()
                    beforeViewController.removeFromParentViewController()
                }
                self.beforeViewController = self.visibleViewController
                self.visibleViewController = self.afterViewController
                self.afterViewController = nil
                self.loadAfterViewController()
                
                self.view.userInteractionEnabled = true
                
                if let toViewController = self.visibleViewController {
                    if let fromViewController = self.beforeViewController {
                        self.delegate?.didFinishAnimating(self, toViewController: toViewController, fromViewController: fromViewController, direction: .After)
                    }
                }
        })
    }
    
    private func animateToBeforeViewController(#progress: CGFloat) {
        view.userInteractionEnabled = false
        
        prepareForAnimateToBeforeViewController()
        
        let duration = NSTimeInterval(animationDuration * (1 - progress * 0.5))
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseOut, animations: {
            self.beforeViewController?.view.frame = self.view.bounds
            self.beforeViewController?.view.alpha = 1
            
            let screenWidth = CGRectGetWidth(self.view.bounds)
            let screenHeight = CGRectGetHeight(self.view.bounds)
            let width = screenWidth * (1 - self.animationSizeDiff)
            let height = screenHeight * (1 - self.animationSizeDiff)
            let frame = CGRectMake((screenWidth - width)/2, (screenHeight - height)/2, width, height)
            self.visibleViewController?.view.frame = frame
            self.visibleViewController?.view.alpha = 1 - self.animationAlphaDiff
            
            }, completion:{ (finished: Bool) in
                self.visibleViewController?.willMoveToParentViewController(nil)
                self.visibleViewController?.view.removeFromSuperview()
                self.endViewControllerTransition()
                self.visibleViewController?.removeFromParentViewController()
                
                if let afterViewController = self.afterViewController {
                    afterViewController.willMoveToParentViewController(nil)
                    afterViewController.view.removeFromSuperview()
                    afterViewController.removeFromParentViewController()
                }
                self.afterViewController = self.visibleViewController
                self.visibleViewController = self.beforeViewController
                self.beforeViewController = nil
                self.loadBeforeViewController()
                
                self.view.userInteractionEnabled = true
                
                if let toViewController = self.visibleViewController {
                    if let fromViewController = self.afterViewController {
                        self.delegate?.didFinishAnimating(self, toViewController: toViewController, fromViewController: fromViewController, direction: .Before)
                    }
                }
        })
    }
    
    private func animateToVisibleViewController(#progress: CGFloat) {
        view.userInteractionEnabled = false
        
        if isTransitioningAfterViewController == true {
            isTransitioningAfterViewController = false
            afterViewController?.beginAppearanceTransition(false, animated: true)
        }
        if isTransitioningBeforeViewController == true {
            isTransitioningBeforeViewController = false
            beforeViewController?.beginAppearanceTransition(false, animated: true)
        }
        visibleViewController?.beginAppearanceTransition(true, animated: true)
        
        let duration = NSTimeInterval(animationDuration * (0.5 + abs(progress) * 0.5))
        UIView.animateWithDuration(duration ,delay: 0, options: .CurveEaseOut, animations: {
            let frame = self.view.bounds
            self.visibleViewController?.view.frame = self.view.bounds
            self.visibleViewController?.view.alpha = 1.0
            
            self.overrayView?.frame = self.view.bounds
            self.overrayView?.alpha = 0
            
            let screenWidth = CGRectGetWidth(self.view.bounds)
            let screenHeight = CGRectGetHeight(self.view.bounds)
            let width = screenWidth * (1 - self.animationSizeDiff)
            let height = screenHeight * (1 - self.animationSizeDiff)
            let x = ceil(screenWidth - width)/2;
            let y = ceil(screenHeight - height)/2
            self.afterViewController?.view.frame = CGRectMake(x, y, width, height)
            self.afterViewController?.view.alpha = 1 - self.animationAlphaDiff
            
            self.beforeViewController?.view.frame = CGRectMake(-screenWidth, 0, screenWidth, screenHeight)
            self.beforeViewController?.view.alpha = 1
            
            }, completion:{ (finished: Bool) in
                self.endViewControllerTransition()
                
                self.view.userInteractionEnabled = true
                
                self.delegate?.didFinishAnimating(self, toViewController: self.visibleViewController, fromViewController: nil, direction: .Visible)
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
                view.insertSubview(afterViewController.view, atIndex: 0)
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
    
    func moveAfterViewController(#animated: Bool) {
        if afterViewController != nil {
            prepareForAnimation()
            prepareForAnimateToAfterViewController()
            animateToAfterViewcontroller(progress: 0)
        }
    }
    
    func moveBeforeViewController(#animated: Bool) {
        if beforeViewController != nil {
            prepareForAnimation()
            prepareForAnimateToBeforeViewController()
            animateToBeforeViewController(progress: 0)
        }
    }
    
    func setVisibleViewController(#viewController: UIViewController) {
        
        if let visibleViewController = visibleViewController {
            visibleViewController.willMoveToParentViewController(nil)
            visibleViewController.view.removeFromSuperview()
            visibleViewController.removeFromParentViewController()
        }
        visibleViewController = nil
        
        addChildViewController(viewController)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        viewController.didMoveToParentViewController(self)
        
        visibleViewController = viewController
    }
    
    func refreshAfterViewController() {
        if let afterViewController = afterViewController {
            afterViewController.willMoveToParentViewController(nil)
            afterViewController.view.removeFromSuperview()
            afterViewController.removeFromParentViewController()
        }
        afterViewController = nil
        loadAfterViewController()
    }
    
    func refreshBeforeViewController() {
        if let beforeViewController = beforeViewController {
            beforeViewController.willMoveToParentViewController(nil)
            beforeViewController.view.removeFromSuperview()
            beforeViewController.removeFromParentViewController()
        }
        beforeViewController = nil
        loadBeforeViewController()
    }
    
}

