//
//  Flipper.swift
//  PageFlipper
//
//  Created by Daniel Koza on 10/2/14.
//  Copyright (c) 2014 Daniel Koza. All rights reserved.
//

import UIKit

enum FlipperStatus {
    case FlipperStatusBeginning
    case FlipperStatusActive
    case FlipperStatusInactive
}

@objc protocol FlipperDataSource {
    func numberOfPages(flipper:Flipper) -> NSInteger
    func imageForPage(page:NSInteger, fipper:Flipper) -> UIImage?
    func viewForPage(page:NSInteger, flipper:Flipper) -> UIView
    
    var flipperViewArray:[UIViewController] { get set }
    var flipperSnapshotArray:[UIImage]? { get set }
    var containerViewController:UIViewController? { get set }
        
}

class Flipper: UIView {
    
    //MARK: - Class properties
    
    var backgroundView:UIView!
    
    lazy var staticView:StaticView = {
        let view = StaticView(frame: self.frame)
        return view
    }()
    
    var numberOfPages:NSInteger = 0
    
    private var _currentPage:NSInteger = 0
    var currentPage:NSInteger {
        get {
            return self._currentPage
        }
        set {
            var oldPage = self._currentPage
            self._currentPage = newValue
        }
    }
    
    private var _dataSource:FlipperDataSource? = nil
    var dataSource:FlipperDataSource? {
        get {
            return self._dataSource
        }
        set {
            self._dataSource = newValue
            if let data = newValue {
                numberOfPages = data.numberOfPages(self)
                currentPage = 0
                if numberOfPages > 0 {
                    getAndAddNewBackground()
                }
            }
        }
    }
    
    var flipperStatus = FlipperStatus.FlipperStatusInactive
    
    var animationArray:NSMutableArray = NSMutableArray()
    
    //MARK: - Class Methods
    
    func enablePanGesture() {
        
        if let var gestures = self.gestureRecognizers {
            for gesture in gestures {
                var tempGesture = gesture as! UIPanGestureRecognizer
                tempGesture.enabled = true
            }
        }
    }
    
    func disablePanGesture() {
        if let var gestures = self.gestureRecognizers {
            for gesture in gestures {
                var tempGesture = gesture as! UIPanGestureRecognizer
                tempGesture.enabled = false
            }
        }
    }
    
    func setHomePage() {
        numberOfPages = dataSource!.numberOfPages(self)
        currentPage = 0
        self.backgroundView.removeFromSuperview()
        getAndAddNewBackground()
    }
    
    //MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        helperInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        helperInit()
    }
    
    func helperInit() {
        var panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        self.addGestureRecognizer(panGesture)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willResignActive", name: UIApplicationWillResignActiveNotification, object: nil)
        
        if let tempDatasource = dataSource {
            numberOfPages = tempDatasource.numberOfPages(self)
            currentPage = 0
            
            getAndAddNewBackground()
        }
        
    }
    
    override func layoutSublayersOfLayer(layer: CALayer!) {
        super.layoutSublayersOfLayer(layer)
        
        if staticView.bounds != self.bounds {
            staticView.updateFrame(self.bounds)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    //MARK: - Handle the Pan Gesture
    
    func pan(gesture:UIPanGestureRecognizer) {

        var translation = gesture.translationInView(gesture.view!).x
        var progress = translation / gesture.view!.bounds.size.width

        switch (gesture.state) {
        case UIGestureRecognizerState.Began:

            if checkIfAnimationsArePassedHalfway() == true {
            
                if flipperStatus == FlipperStatus.FlipperStatusInactive {
                    flipperStatus = FlipperStatus.FlipperStatusBeginning
                }
                
                //check to see if the previous animationlayer was not set
                var createFlipLayer = true
                if animationArray.count > 0 {
                    if var previousAnimationLayer = animationArray.lastObject as? AnimationLayer {
                        if previousAnimationLayer.flipDirection == FlipDirection.FlipDirectionNotSet || previousAnimationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning {
                            animationArray.removeObject(previousAnimationLayer)
                            previousAnimationLayer.removeFromSuperlayer()
                            CATransaction.flush()
                            
                            gesture.enabled = false
                            createFlipLayer = false
                        }
                    }
                }
                
                if createFlipLayer == true {
                    var animationLayer = AnimationLayer(frame: staticView.rightSide.bounds, isFirstOrLast:false)
                    animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusBeginning
                    
                    if let hiAnimLayer = getHighestAnimationLayer() {
                        animationLayer.zPosition = hiAnimLayer.zPosition + animationLayer.bounds.size.height
                    } else {
                        animationLayer.zPosition = 0
                    }

                    animationArray.addObject(animationLayer)
                }
            } else {
                gesture.enabled = false
            }
            
        case UIGestureRecognizerState.Changed:
            
            //println("changed")
            
            if var animationLayer = animationArray.lastObject as? AnimationLayer {
                if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning {
                    
                    if translation > 0 {
                        animationLayer.updateFlipDirection(FlipDirection.FlipDirectionRight)
                    } else {
                        animationLayer.updateFlipDirection(FlipDirection.FlipDirectionLeft)
                    }
                    
                    //check if there is an animation layer before that is still animating at the opposite swipe direction
                    //If there is then we need to remove the newly added layer and grab that previous layer and animate it in the opposite direction
                    if animationArray.count > 1 {
                        var flipsDirectionQueue = animationLayer.flipDirection
                        
                        if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                            flipsDirectionQueue = FlipDirection.FlipDirectionRight
                        } else {
                            flipsDirectionQueue = FlipDirection.FlipDirectionLeft
                        }
                        
                        if var highestAnimationLayer = getAnimationLayersFromDirection(flipsDirectionQueue).firstObject as? AnimationLayer {
                            if highestAnimationLayer.flipDirection != animationLayer.flipDirection && highestAnimationLayer.isFirstOrLastPage == false {
                                animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusFail
                                
                                var zPos = animationLayer.bounds.size.height
                                
                                if let highestZPosAnimLayer = getHighestAnimationLayer() {
                                    zPos = zPos + highestZPosAnimLayer.zPosition
                                } else {
                                    zPos = 0
                                }
                                
                                animationArray.removeObject(animationLayer)
                                animationLayer = highestAnimationLayer
                                
                                CATransaction.begin()
                                CATransaction.setAnimationDuration(0)
                                animationLayer.zPosition = zPos
                                CATransaction.commit()
                                
                                animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusInterrupt
                                
                                if highestAnimationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                                    currentPage = currentPage - 1
                                    animationLayer.updateFlipDirection(FlipDirection.FlipDirectionRight)
                                    flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
                                } else if highestAnimationLayer.flipDirection == FlipDirection.FlipDirectionRight {
                                    currentPage = currentPage + 1
                                    animationLayer.updateFlipDirection(FlipDirection.FlipDirectionLeft)
                                    flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
                                }
                            }
                        }
                    }
                    
                    //if there is no conflict we create the set the front and back layer sides for the animation layer
                    //we also need to create the static layer that sites below the animation layer
                    if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning {
                        
//                        dataSource?.willUpdateBackgroundWithNewView(currentPage, flipper: self)
                        dataSource?.flipperViewArray[currentPage].willMoveToParentViewController(nil)
                        
                        var currentPageScreenShot = dataSource?.viewForPage(currentPage, flipper: self).takeSnapShotWithoutScreenUpdate()
                        
                        if var currentScreenShot = currentPageScreenShot {
                            dataSource?.flipperSnapshotArray?.removeAtIndex(currentPage)
                            dataSource?.flipperSnapshotArray?.insert(currentScreenShot, atIndex: currentPage)
                        }

                        switch animationLayer.flipDirection {
                        case FlipDirection.FlipDirectionNotSet:
                            println("not set")
                        case FlipDirection.FlipDirectionLeft:
                            if currentPage + 1 > numberOfPages - 1 {
                                //we are at the end
                                animationLayer.flipProperties.endFlipAngle = -1.5
                                animationLayer.isFirstOrLastPage = true
                                animationLayer.frontLayer(dataSource!.imageForPage(currentPage, fipper: self)!)
                            } else {
                                //next page flip
                                if var currentScreenShot = currentPageScreenShot {
                                    animationLayer.frontLayer(currentScreenShot)
                                } else {
                                    animationLayer.frontLayer(dataSource!.imageForPage(currentPage, fipper: self)!)
                                }
                                currentPage = currentPage + 1
                                animationLayer.backLayer(dataSource!.imageForPage(currentPage, fipper: self)!)
                            }
                        case FlipDirection.FlipDirectionRight:
                            if currentPage - 1 < 0 {
                                animationLayer.flipProperties.endFlipAngle = CGFloat(-M_PI) + 1.5
                                animationLayer.isFirstOrLastPage = true
                                
                                if var currentScreenShot = currentPageScreenShot {
                                    animationLayer.backLayer(currentScreenShot)
                                } else {
                                    animationLayer.backLayer(dataSource!.imageForPage(currentPage, fipper: self)!)
                                }

                            } else {
                                //previous page flip
                                
                                if var currentScreenShot = currentPageScreenShot {
                                    animationLayer.backLayer(currentPageScreenShot!)
                                } else {
                                    animationLayer.backLayer(dataSource!.imageForPage(currentPage, fipper: self)!)
                                }
                                currentPage = currentPage - 1
                                animationLayer.backLayer(dataSource!.imageForPage(currentPage, fipper: self)!)
                            }
                        }
                        
                        //set up the static layer
                        
                        if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                            
                            if animationLayer.isFirstOrLastPage == true && animationArray.count <= 1 {
                                staticView.leftSide(dataSource!.imageForPage(currentPage, fipper: self)!)
                            } else {
                                if flipperStatus == FlipperStatus.FlipperStatusBeginning {
                                    
                                    if var currentScreenShot = currentPageScreenShot {
                                        staticView.leftSide(currentScreenShot)
                                    } else {
                                        staticView.leftSide(dataSource!.imageForPage(currentPage - 1, fipper: self)!)
                                    }
                                }
                                staticView.rightSide(dataSource!.imageForPage(currentPage, fipper: self)!)
                            }
                            
                        } else {
                            if animationLayer.isFirstOrLastPage == true && animationArray.count <= 1 {
                                
                                if var currentScreenShot = currentPageScreenShot {
                                    staticView.rightSide(currentScreenShot)
                                } else {
                                    staticView.rightSide(dataSource!.imageForPage(currentPage, fipper: self)!)
                                }

                            } else {
                                if flipperStatus == FlipperStatus.FlipperStatusBeginning {
                                    
                                    if var currentScreenShot = currentPageScreenShot {
                                        staticView.rightSide(currentScreenShot)
                                    } else {
                                        staticView.rightSide(dataSource!.imageForPage(currentPage + 1, fipper: self)!)
                                    }
                                }
                                staticView.leftSide(dataSource!.imageForPage(currentPage, fipper: self)!)
                            }
                        }
                        
                        self.layer.addSublayer(animationLayer)
                        CATransaction.flush()
                        //if the user is swiping the screen with a lot of velocity just perform the entire animation at once
                        //you need to perform a flush otherwise the animation duration is not honored.
                        //more information can be found here http://stackoverflow.com/questions/8661355/implicit-animation-fade-in-is-not-working#comment10764056_8661741
                        if fabs(gesture.velocityInView(self).x) > 500 {
                            if animationLayer.isFirstOrLastPage == true {
                                animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusActive
                            }
                        } else {
                            animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusActive
                        }
                    }
                }
                
                if flipperStatus == FlipperStatus.FlipperStatusBeginning {
                    
                    self.layer.addSublayer(staticView)
                    CATransaction.flush()
                    backgroundView.removeFromSuperview()
                    flipperStatus = FlipperStatus.FlipperStatusActive
                    
                }
                
                if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusActive {
                    
                    if translation > 0 {
                        progress = max(progress, 0)
                    } else {
                        progress = min(progress, 0)
                    }
                    
                    progress = fabs(progress)
                    flipPage(animationLayer, progress: progress, animated: false, clearFlip: false)
                    
                } else if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning {
                    animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusCompleting
                    flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
                }
            }
            
        case UIGestureRecognizerState.Ended:
//            println("ended")
            if var animationLayer = animationArray.lastObject as? AnimationLayer {
                if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusActive {
                    animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusCompleting
                    
                    var releaseSpeed:CGFloat = (translation + gesture.velocityInView(self).x/4) / self.bounds.size.width
                    var speedThreshold:CGFloat = 0.5
                                        
                    var flipToNewPage = false
                    if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft && fabs(releaseSpeed) > speedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed < 0 {
                        flipToNewPage = true
                    } else if animationLayer.flipDirection == FlipDirection.FlipDirectionRight && fabs(releaseSpeed) > speedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed > 0{
                        flipToNewPage = true
                    }
                    
                    if flipToNewPage == true {
                        flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
                    } else {
                        if !animationLayer.isFirstOrLastPage {
                            if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                                animationLayer.flipDirection = FlipDirection.FlipDirectionRight
                                currentPage = currentPage - 1
                            } else {
                                animationLayer.flipDirection = FlipDirection.FlipDirectionLeft
                                currentPage = currentPage + 1
                            }
                        }
                        
                        flipPage(animationLayer, progress: 0.0, animated: true, clearFlip: true)
                    }

                } else if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning || animationLayer.flipDirection == FlipDirection.FlipDirectionNotSet {
                    //precautionary if pan gesture never goes to the changed state
                    animationArray.removeObject(animationLayer)
                    animationLayer.removeFromSuperlayer()
                    CATransaction.flush()
                }
            }
            
        case UIGestureRecognizerState.Cancelled:
            gesture.enabled = true
            println("canceled")
        case UIGestureRecognizerState.Failed:
            println("failed")
        case UIGestureRecognizerState.Possible:
            println("Possible")
        }
    }
    
    //MARK: - Flip Animation Method
    
    func flipPage(page:AnimationLayer,progress:CGFloat,animated:Bool,clearFlip:Bool) {
        
        var newAngle:CGFloat = page.flipProperties.startAngle + progress * (page.flipProperties.endFlipAngle - page.flipProperties.startAngle)
        var duration:CGFloat
        var durationConstant:CGFloat = 0.75
        
        if page.isFirstOrLastPage == true {
            durationConstant = 0.5
        }
        
        if animated {
            duration = durationConstant * fabs((newAngle - page.flipProperties.currentAngle) / (page.flipProperties.endFlipAngle - page.flipProperties.startAngle))
        } else {
            duration = 0.0
        }

        page.flipProperties.currentAngle = newAngle
        
        if page.isFirstOrLastPage == true {
            if page.flipDirection == FlipDirection.FlipDirectionRight {
                if newAngle < -1.4 {
                    page.flipProperties.currentAngle = -1.4
                }
            } else {
                if newAngle > -1.8 {
                    page.flipProperties.currentAngle = -1.8
                }
            }
        }
        
        var t = CATransform3DIdentity
        t.m34 = 1.0/850
        t = CATransform3DRotate(t, page.flipProperties.currentAngle, 0, 1, 0)

        CATransaction.begin()
        CATransaction.setAnimationDuration(CFTimeInterval(duration))
        
        if clearFlip {
            weak var weakSelf = self
            CATransaction.setCompletionBlock { () -> Void in
                
                if page.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusInterrupt {

                    page.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusCompleting
                    
                } else if page.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusCompleting {
                    page.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusNone
                    
                    if page.isFirstOrLastPage == false {
                        CATransaction.begin()
                        CATransaction.setAnimationDuration(0)
                        if page.flipDirection == FlipDirection.FlipDirectionLeft {
                            weakSelf?.staticView.leftSide.contents = page.backLayer.contents
                        } else {
                            weakSelf?.staticView.rightSide.contents = page.frontLayer.contents
                        }
                        CATransaction.commit()
                    }
                    
                    weakSelf?.animationArray.removeObject(page)
                    page.removeFromSuperlayer()
                    
                    if weakSelf?.animationArray.count == 0 {

                        weakSelf?.flipperStatus = FlipperStatus.FlipperStatusInactive

                        weakSelf?.getAndAddNewBackground()

                        weakSelf?.staticView.removeFromSuperlayer()
                        CATransaction.flush()
                        weakSelf?.staticView.leftSide.contents = nil
                        weakSelf?.staticView.rightSide.contents = nil
                    } else {
                        CATransaction.flush()
                    }
                }
            }
        }

        page.transform = t
        CATransaction.commit()
    }
}


//MARK: - Flipper Helper Methods
extension Flipper {
    
    func willResignActive() {
        if flipperStatus != FlipperStatus.FlipperStatusInactive {
            //remove all animation layers and remove the static view
            getAndAddNewBackground()
            
            var pendingAnimations = NSMutableArray(array: animationArray)
            for animation in animationArray {
                var animationLayer = animation as! AnimationLayer
                animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusFail
                animationLayer.removeFromSuperlayer()
            }
            animationArray.removeAllObjects()
            
            self.staticView.removeFromSuperlayer()
            CATransaction.flush()
            self.staticView.leftSide.contents = nil
            self.staticView.rightSide.contents = nil
            
            flipperStatus = FlipperStatus.FlipperStatusInactive
        }
    }
    
    func checkIfAnimationsArePassedHalfway() -> Bool{
        var passedHalfWay = false
        
        if flipperStatus == FlipperStatus.FlipperStatusInactive {
            passedHalfWay = true
        } else if animationArray.count > 0 {
            //LOOP through this and check the new animation layer with current animations to make sure we dont allow the same animation to happen on a flip up
            for animLayer in animationArray {
                var animationLayer = animLayer as! AnimationLayer
                var layerIsPassedHalfway = false
                
                var rotationX = animationLayer.presentationLayer().valueForKeyPath("transform.rotation.x") as! CGFloat
                
                if animationLayer.flipDirection == FlipDirection.FlipDirectionRight && rotationX > 0 {
                    layerIsPassedHalfway = true
                } else if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft && rotationX == 0 {
                    layerIsPassedHalfway = true
                }
                
                if layerIsPassedHalfway == false {
                    passedHalfWay = false
                    break
                } else {
                    passedHalfWay = true
                }
            }
        } else {
            passedHalfWay = true
        }
        
        return passedHalfWay
    }
    
    func getAndAddNewBackground() {

        self.backgroundView = self.dataSource!.viewForPage(self.currentPage, flipper: self)
        self.addSubview(self.backgroundView)
        
        //set up the constraints
        self.backgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        var viewDictionary = ["backgroundView":self.backgroundView]
        var constraintTop = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[backgroundView]-0-|", options: NSLayoutFormatOptions.AlignAllTop, metrics: nil, views: viewDictionary)
        var constraintLeft = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[backgroundView]-0-|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: viewDictionary)
        
        self.addConstraints(constraintTop)
        self.addConstraints(constraintLeft)
        
        if var theDataSource = dataSource {
            if theDataSource.flipperViewArray[currentPage].childViewControllers.count > 0 {
                (theDataSource.flipperViewArray[currentPage] as UIViewController).removeFromParentViewController()
            }
            
            if var containerViewController = theDataSource.containerViewController {
                containerViewController.addChildViewController(theDataSource.flipperViewArray[currentPage] as UIViewController)
                (theDataSource.flipperViewArray[currentPage] as UIViewController).didMoveToParentViewController(containerViewController)
            }
            
        }
        
    }
    
    func getHighestAnimationLayer() -> AnimationLayer? {
        let descriptors = NSArray(array: [NSSortDescriptor(key: "zPosition", ascending: false)])
        let sortedArray = animationArray.sortedArrayUsingDescriptors(descriptors as [AnyObject])
        
        if sortedArray.count > 0 {
            let animationLayer = sortedArray.first as! AnimationLayer
            return animationLayer
        } else {
            return nil
        }
    }
    
    func getAnimationLayersFromDirection(flipDirection:FlipDirection) -> NSMutableArray {
        
        var array = NSMutableArray()
        
        for animLayer in animationArray {
            var animationLayer = animLayer as! AnimationLayer
            if animationLayer.flipDirection == flipDirection {
                array.addObject(animationLayer)
            }
        }
        
        let descriptors = NSArray(array: [NSSortDescriptor(key: "zPosition", ascending: false)])
        let sortedArray = array.sortedArrayUsingDescriptors(descriptors as [AnyObject])
        
        return NSMutableArray(array: sortedArray)
    }
    
}
