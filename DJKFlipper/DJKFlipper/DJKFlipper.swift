//
//  FlipperReDo.swift
//  DJKSwiftFlipper
//
//  Created by Koza, Daniel on 7/13/15.
//  Copyright (c) 2015 Daniel Koza. All rights reserved.
//

import UIKit

public enum FlipperState {
    case Began
    case Active
    case Inactive
}

@objc public protocol DJKFlipperDataSource {
    func numberOfPages(flipper:DJKFlipper) -> NSInteger
    func viewForPage(page:NSInteger, flipper:DJKFlipper) -> UIView
}

public class DJKFlipper: UIView {
    
    //MARK: - Property Declarations
    
    var viewControllerSnapShots:[UIImage?] = []
    public var dataSource:DJKFlipperDataSource? {
        didSet {
            updateTheActiveView()
            //set an array with capacity for total amount of possible pages
            viewControllerSnapShots.removeAll(keepCapacity: false)
            for index in 1...dataSource!.numberOfPages(self) {
                viewControllerSnapShots.append(nil)
            }
        }
    }
    
    lazy var staticView:DJKStaticView = {
        let view = DJKStaticView(frame: self.frame)
        return view
    }()
    
    var flipperState = FlipperState.Inactive
    var activeView:UIView?
    var currentPage = 0
    var animatingLayers:[DJKAnimationLayer] = []
    
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initHelper()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initHelper()
    }
    
    func initHelper() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceOrientationDidChangeNotification", name: UIDeviceOrientationDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearAnimations", name: UIApplicationWillResignActiveNotification, object: nil)
        
        var panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        self.addGestureRecognizer(panGesture)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.staticView.updateFrame(self.frame)
    }
    
    func updateTheActiveView() {
        
        if let dataSource = self.dataSource {
            if dataSource.numberOfPages(self) > 0 {
                
                if let activeView = self.activeView {
                    if activeView.isDescendantOfView(self) {
                        activeView.removeFromSuperview()
                    }
                }
                
                self.activeView = dataSource.viewForPage(self.currentPage, flipper: self)
                self.addSubview(self.activeView!)
                
                //set up the constraints
                self.activeView!.setTranslatesAutoresizingMaskIntoConstraints(false)
                var viewDictionary = ["activeView":self.activeView!]
                var constraintTop = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.AlignAllTop, metrics: nil, views: viewDictionary)
                var constraintLeft = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: viewDictionary)
                
                self.addConstraints(constraintTop)
                self.addConstraints(constraintLeft)
                
            }
        }
    }
    
    //MARK: - Pan Gesture States
    
    func pan(gesture:UIPanGestureRecognizer) {
        
        var translation = gesture.translationInView(gesture.view!).x
        var progress = translation / gesture.view!.bounds.size.width
        
        switch (gesture.state) {
        case .Began:
            panBegan(gesture)
        case .Changed:
            panChanged(gesture, translation: translation, progress: progress)
        case .Ended:
            panEnded(gesture, translation: translation)
        case .Cancelled:
            enableGesture(gesture, enable: true)
        case .Failed:
            println("Failed")
        case .Possible:
            println("Possible")
        }
    }
    
    //MARK: Pan Gesture State Began
    
    func panBegan(gesture:UIPanGestureRecognizer) {
        if checkIfAnimationsArePassedHalfway() != true {
            enableGesture(gesture, enable: false)
        } else {
            
            if flipperState == .Inactive {
                flipperState = .Began
            }
            
            var screenBounds = UIScreen.mainScreen().bounds
            var animationLayer = DJKAnimationLayer(frame: self.staticView.rightSide.bounds, isFirstOrLast:false)
            
            //if an animation has a lower zPosition then it will not be visible throughout the entire animation cycle
            if let hiZAnimLayer = getHighestZIndexDJKAnimationLayer() {
                animationLayer.zPosition = hiZAnimLayer.zPosition + animationLayer.bounds.size.height
            } else {
                animationLayer.zPosition = 0
            }
            
            animatingLayers.append(animationLayer)
        }
    }
    
    //MARK: Pan Began Helpers
    
    func checkIfAnimationsArePassedHalfway() -> Bool{
        var passedHalfWay = false
        
        if flipperState == FlipperState.Inactive {
            passedHalfWay = true
        } else if animatingLayers.count > 0 {
            //LOOP through this and check the new animation layer with current animations to make sure we dont allow the same animation to happen on a flip up
            for animLayer in animatingLayers {
                var animationLayer = animLayer as DJKAnimationLayer
                var layerIsPassedHalfway = false
                
                var rotationX = animationLayer.presentationLayer().valueForKeyPath("transform.rotation.x") as! CGFloat
                
                if animationLayer.flipDirection == .Right && rotationX > 0 {
                    layerIsPassedHalfway = true
                } else if animationLayer.flipDirection == .Left && rotationX == 0 {
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
    
    //MARK:Pan Gesture State Changed
    
    func panChanged(gesture:UIPanGestureRecognizer, translation:CGFloat, var progress:CGFloat) {

        if var currentDJKAnimationLayer = animatingLayers.last {
            if currentDJKAnimationLayer.flipAnimationStatus == .Beginning {
                animationStatusBeginning(currentDJKAnimationLayer, translation: translation, progress: progress, gesture: gesture)
            } else if currentDJKAnimationLayer.flipAnimationStatus == .Active {
                animationStatusActive(currentDJKAnimationLayer, translation: translation, progress: progress)
            } else if currentDJKAnimationLayer.flipAnimationStatus == .Completing {
                enableGesture(gesture, enable: false)
                animationStatusCompleting(currentDJKAnimationLayer)
            }
        }
    }
    
    //MARK: Pan Gesture State Ended
    
    func panEnded(gesture:UIPanGestureRecognizer, translation:CGFloat) {

        if var currentDJKAnimationLayer = animatingLayers.last {
            currentDJKAnimationLayer.flipAnimationStatus = .Completing
            
            if didFlipToNewPage(currentDJKAnimationLayer, gesture: gesture, translation: translation) == true {
                setUpForFlip(currentDJKAnimationLayer, progress: 1.0, animated: true, clearFlip: true)
            } else {
                if currentDJKAnimationLayer.isFirstOrLastPage == false {
                    handleDidNotFlipToNewPage(currentDJKAnimationLayer)
                }
                setUpForFlip(currentDJKAnimationLayer, progress: 0.0, animated: true, clearFlip: true)
            }
        }
    }
    
    //MARK: Pan Ended Helpers
    
    func didFlipToNewPage(animationLayer:DJKAnimationLayer, gesture:UIPanGestureRecognizer, translation:CGFloat) -> Bool {
        
        var releaseSpeed = getReleaseSpeed(translation, gesture: gesture)

        var didFlipToNewPage = false
        if animationLayer.flipDirection == .Left && fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed < 0 ||
           animationLayer.flipDirection == .Right && fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed > 0 {
            didFlipToNewPage = true
        }
        return didFlipToNewPage
    }
    
    func getReleaseSpeed(translation:CGFloat, gesture:UIPanGestureRecognizer) -> CGFloat {
        return (translation + gesture.velocityInView(self).x/4) / self.bounds.size.width
    }
    
    func handleDidNotFlipToNewPage(animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .Left {
            animationLayer.flipDirection = .Right
            self.currentPage = self.currentPage - 1
        } else {
            animationLayer.flipDirection = .Left
            self.currentPage = self.currentPage + 1
        }
    }
    
    //MARK: - DJKAnimationLayer States
    
    //MARK: DJKAnimationLayer State Began
    
    func animationStatusBeginning(currentDJKAnimationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat, gesture:UIPanGestureRecognizer) {
        if currentDJKAnimationLayer.flipAnimationStatus == .Beginning {
            
            flipperState = .Active
            
            //set currentDJKAnimationLayers direction
            currentDJKAnimationLayer.updateFlipDirection(getFlipDirection(translation))
            
            if handleConflictingAnimationsWithDJKAnimationLayer(currentDJKAnimationLayer) == false {
                //check if swipe is fast enough to be considered a complete page swipe
                if isIncrementalSwipe(gesture, animationLayer: currentDJKAnimationLayer) {
                    currentDJKAnimationLayer.flipAnimationStatus = .Active
                } else {
                    currentDJKAnimationLayer.flipAnimationStatus = .Completing
                }
                
                updateViewControllerSnapShotsWithCurrentPage(self.currentPage)
                setUpDJKAnimationLayerFrontAndBack(currentDJKAnimationLayer)
                setUpStaticLayerForTheDJKAnimationLayer(currentDJKAnimationLayer)
                
                self.layer.addSublayer(currentDJKAnimationLayer)
                //you need to perform a flush otherwise the animation duration is not honored.
                //more information can be found here http://stackoverflow.com/questions/8661355/implicit-animation-fade-in-is-not-working#comment10764056_8661741
                CATransaction.flush()
                
                //add the animation layer to the view
                addDJKAnimationLayer()
                
                if currentDJKAnimationLayer.flipAnimationStatus == .Active {
                    animationStatusActive(currentDJKAnimationLayer, translation: translation, progress: progress)
                }
            } else {
                enableGesture(gesture, enable: false)
            }
        }
    }
    
    //MARK: DJKAnimationLayer State Begin Helpers
    
    func getFlipDirection(translation:CGFloat) -> FlipDirection {
        if translation > 0 {
            return .Right
        } else {
            return .Left
        }
    }
    
    func isIncrementalSwipe(gesture:UIPanGestureRecognizer, animationLayer:DJKAnimationLayer) -> Bool {
        
        var incrementalSwipe = false
        if fabs(gesture.velocityInView(self).x) < 500 || animationLayer.isFirstOrLastPage == true {
            incrementalSwipe = true
        }
        
        return incrementalSwipe
    }
    
    func updateViewControllerSnapShotsWithCurrentPage(currentPage:Int) {
        if var numberOfPages = dataSource?.numberOfPages(self) {
            if  currentPage <= numberOfPages - 1 {
                //set the current page snapshot
                viewControllerSnapShots[currentPage] = dataSource?.viewForPage(currentPage, flipper: self).takeSnapshot()
                
                if currentPage + 1 <= numberOfPages - 1  {
                    //set the right page snapshot, if there already is a screen shot then dont update it
                    if viewControllerSnapShots[currentPage + 1] == nil {
                        viewControllerSnapShots[currentPage + 1] = dataSource?.viewForPage(currentPage + 1, flipper: self).takeSnapshot()
                    }
                }
                
                if currentPage - 1 >= 0 {
                    //set the left page snapshot, if there already is a screen shot then dont update it
                    if viewControllerSnapShots[currentPage - 1] == nil {
                        viewControllerSnapShots[currentPage - 1] = dataSource?.viewForPage(currentPage - 1, flipper: self).takeSnapshot()
                    }
                }
            }
        }
    }
    
    func setUpDJKAnimationLayerFrontAndBack(animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .Left {
            if self.currentPage + 1 > dataSource!.numberOfPages(self) - 1 {
                //we are at the end
                animationLayer.flipProperties.endFlipAngle = -1.5
                animationLayer.isFirstOrLastPage = true
                animationLayer.setTheFrontLayer(self.viewControllerSnapShots[currentPage]!)
            } else {
                //next page flip
                animationLayer.setTheFrontLayer(self.viewControllerSnapShots[currentPage]!)
                currentPage = currentPage + 1
                animationLayer.setTheBackLayer(self.viewControllerSnapShots[currentPage]!)
            }
        } else {
            if currentPage - 1 < 0 {
                //we are at the end
                animationLayer.flipProperties.endFlipAngle = CGFloat(-M_PI) + 1.5
                animationLayer.isFirstOrLastPage = true
                animationLayer.setTheBackLayer(viewControllerSnapShots[currentPage]!)
                
            } else {
                //previous page flip
                animationLayer.setTheBackLayer(self.viewControllerSnapShots[currentPage]!)
                currentPage = currentPage - 1
                animationLayer.setTheFrontLayer(self.viewControllerSnapShots[currentPage]!)
            }
        }
    }
    
    func setUpStaticLayerForTheDJKAnimationLayer(animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .Left {
            if animationLayer.isFirstOrLastPage == true && animatingLayers.count <= 1 {
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage]!)
            } else {
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage - 1]!)
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage]!)
            }
        } else {
            if animationLayer.isFirstOrLastPage == true && animatingLayers.count <= 1 {
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage]!)
            } else {
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage + 1]!)
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage]!)
            }
        }
    }
    
    func addDJKAnimationLayer() {
        self.layer.addSublayer(staticView)
        CATransaction.flush()
        
        if let activeView = self.activeView {
            activeView.removeFromSuperview()
        }
    }
    
    //MARK: DJKAnimationLayer State Active
    
    func animationStatusActive(currentDJKAnimationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat) {
        performIncrementalAnimationToLayer(currentDJKAnimationLayer, translation: translation, progress: progress)
    }
    
    //MARK: DJKAnimationLayer State Active Helpers
    
    func performIncrementalAnimationToLayer(animationLayer:DJKAnimationLayer, translation:CGFloat, var progress:CGFloat) {
        
        if translation > 0 {
            progress = max(progress, 0)
        } else {
            progress = min(progress, 0)
        }
        
        progress = fabs(progress)
        setUpForFlip(animationLayer, progress: progress, animated: false, clearFlip: false)
    }
    
    //MARK DJKAnimationLayer State Complete
    
    func animationStatusCompleting(animationLayer:DJKAnimationLayer) {
        performCompleteAnimationToLayer(animationLayer)
    }
    
    //MARK: Animation State Complete Helpers
    
    func performCompleteAnimationToLayer(animationLayer:DJKAnimationLayer) {
        setUpForFlip(animationLayer, progress: 1.0, animated: true, clearFlip: true)
    }
    
    //MARK: - Animation Conflict Detection
    
    func handleConflictingAnimationsWithDJKAnimationLayer(animationLayer:DJKAnimationLayer) -> Bool {
        
        //check if there is an animation layer before that is still animating at the opposite swipe direction
        var animationConflict = false
        if animatingLayers.count > 1 {
            
            if let oppositeDJKAnimationLayer = getHighestDJKAnimationLayerFromDirection(getOppositeAnimationDirectionFromLayer(animationLayer)) {
                if oppositeDJKAnimationLayer.isFirstOrLastPage == false {
                    
                    animationConflict = true
                    //we now need to remove the newly added layer
                    removeDJKAnimationLayer(animationLayer)
                    reverseAnimationForLayer(oppositeDJKAnimationLayer)
                    
                }
            }
        }
        return animationConflict
    }
    
    func getHighestDJKAnimationLayerFromDirection(flipDirection:FlipDirection) -> DJKAnimationLayer? {
        
        var animationsInSameDirection:[DJKAnimationLayer] = []
        
        for animLayer in animatingLayers {
            if animLayer.flipDirection == flipDirection {
                animationsInSameDirection.append(animLayer)
            }
        }
        
        if animationsInSameDirection.count > 0 {
            animationsInSameDirection.sort({$0.zPosition > $1.zPosition})
            return animationsInSameDirection.first
        }
        return nil
    }
    
    func getOppositeAnimationDirectionFromLayer(animationLayer:DJKAnimationLayer) -> FlipDirection {
        var animationLayerOppositeDirection = FlipDirection.Left
        if animationLayer.flipDirection == .Left {
            animationLayerOppositeDirection = .Right
        }
        
        return animationLayerOppositeDirection
    }
    
    func removeDJKAnimationLayer(animationLayer:DJKAnimationLayer) {
        animationLayer.flipAnimationStatus = .Fail
        
        var zPos = animationLayer.bounds.size.height
        
        if let highestZPosAnimLayer = getHighestZIndexDJKAnimationLayer() {
            zPos = zPos + highestZPosAnimLayer.zPosition
        } else {
            zPos = 0
        }
        
        animatingLayers.removeObject(animationLayer)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        animationLayer.zPosition = zPos
        CATransaction.commit()
    }
    
    func reverseAnimationForLayer(animationLayer:DJKAnimationLayer) {
        animationLayer.flipAnimationStatus = .Interrupt
        
        if animationLayer.flipDirection == .Left {
            currentPage = currentPage - 1
            animationLayer.updateFlipDirection(.Right)
            setUpForFlip(animationLayer, progress: 1.0, animated: true, clearFlip: true)
        } else if animationLayer.flipDirection == .Right {
            currentPage = currentPage + 1
            animationLayer.updateFlipDirection(.Left)
            setUpForFlip(animationLayer, progress: 1.0, animated: true, clearFlip: true)
        }
    }
    
    //MARK: - Flip Animation Methods
    
    func setUpForFlip(animationLayer:DJKAnimationLayer, progress:CGFloat, animated:Bool, clearFlip:Bool) {

        var newAngle:CGFloat = animationLayer.flipProperties.startAngle + progress * (animationLayer.flipProperties.endFlipAngle - animationLayer.flipProperties.startAngle)
        
        var duration:CGFloat
        var durationConstant = DJKFlipperConstants.DurationConstant
        
        if animated == true {
            duration = getAnimationDurationFromDJKAnimationLayer(animationLayer, newAngle: newAngle)
        } else {
            duration = 0
        }
        
        animationLayer.flipProperties.currentAngle = newAngle
        
        if animationLayer.isFirstOrLastPage == true {
            setMaxAngleIfDJKAnimationLayerIsFirstOrLast(animationLayer, newAngle: newAngle)
        }
        
        performFlipWithDJKAnimationLayer(animationLayer, duration: duration, clearFlip: clearFlip)
    }
    
    func performFlipWithDJKAnimationLayer(animationLayer:DJKAnimationLayer, duration:CGFloat, clearFlip:Bool) {
        var t = CATransform3DIdentity
        t.m34 = 1.0/850
        t = CATransform3DRotate(t, animationLayer.flipProperties.currentAngle, 0, 1, 0)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(CFTimeInterval(duration))
        
        //if the flip animationLayer should be cleared after its animation is completed
        if clearFlip {
            clearFlipAfterCompletion(animationLayer)
        }
        
        animationLayer.transform = t
        CATransaction.commit()
    }
    
    func clearFlipAfterCompletion(animationLayer:DJKAnimationLayer) {
        weak var weakSelf = self
        CATransaction.setCompletionBlock { () -> Void in
    
            dispatch_async(dispatch_get_main_queue(), {
                if animationLayer.flipAnimationStatus == .Interrupt {
                    animationLayer.flipAnimationStatus = .Completing
                    
                } else if animationLayer.flipAnimationStatus == .Completing {
                    animationLayer.flipAnimationStatus = .None
                    
                    if animationLayer.isFirstOrLastPage == false {
                        CATransaction.begin()
                        CATransaction.setAnimationDuration(0)
                        if animationLayer.flipDirection == .Left {
                            weakSelf?.staticView.leftSide.contents = animationLayer.backLayer.contents
                        } else {
                            weakSelf?.staticView.rightSide.contents = animationLayer.frontLayer.contents
                        }
                        CATransaction.commit()
                    }
                    
                    weakSelf?.animatingLayers.removeObject(animationLayer)
                    animationLayer.removeFromSuperlayer()
                    
                    if weakSelf?.animatingLayers.count == 0 {
                        
                        weakSelf?.flipperState = .Inactive
                        weakSelf?.updateTheActiveView()
                        weakSelf?.staticView.removeFromSuperlayer()
                        CATransaction.flush()
                        weakSelf?.staticView.leftSide.contents = nil
                        weakSelf?.staticView.rightSide.contents = nil
                    } else {
                        CATransaction.flush()
                    }
                }
            })
            
        }
    }
    
    //MARK: Flip Animation Helper Methods
    
    func getAnimationDurationFromDJKAnimationLayer(animationLayer:DJKAnimationLayer, newAngle:CGFloat) -> CGFloat {
        var duration:CGFloat
        var durationConstant = DJKFlipperConstants.DurationConstant
        
        if animationLayer.isFirstOrLastPage == true {
            durationConstant = 0.5
        }
        return durationConstant * fabs((newAngle - animationLayer.flipProperties.currentAngle) / (animationLayer.flipProperties.endFlipAngle - animationLayer.flipProperties.startAngle))
    }
    
    func setMaxAngleIfDJKAnimationLayerIsFirstOrLast(animationLayer:DJKAnimationLayer, newAngle:CGFloat) {
        if animationLayer.flipDirection == .Right {
            if newAngle < -1.4 {
                animationLayer.flipProperties.currentAngle = -1.4
            }
        } else {
            if newAngle > -1.8 {
                animationLayer.flipProperties.currentAngle = -1.8
            }
        }
    }
    
    //MARK: - Helper Methods
    
    func enableGesture(gesture:UIPanGestureRecognizer, enable:Bool) {
        gesture.enabled = enable
    }
    
    func getHighestZIndexDJKAnimationLayer() -> DJKAnimationLayer? {
        
        if animatingLayers.count > 0 {
            var copyOfAnimatingLayers = animatingLayers
            copyOfAnimatingLayers.sort({$0.zPosition > $1.zPosition})
            
            var highestDJKAnimationLayer = copyOfAnimatingLayers.first
            return highestDJKAnimationLayer
        }
        return nil
    }
    
    func clearAnimations() {
        if flipperState != .Inactive {
            //remove all animation layers and update the static view
            updateTheActiveView()
            
            for animation in animatingLayers {
                animation.flipAnimationStatus = .Fail
                animation.removeFromSuperlayer()
            }
            animatingLayers.removeAll(keepCapacity: false)
            
            self.staticView.removeFromSuperlayer()
            CATransaction.flush()
            self.staticView.leftSide.contents = nil
            self.staticView.rightSide.contents = nil
            
            flipperState = .Inactive
        }
    }
    
    func deviceOrientationDidChangeNotification() {
        clearAnimations()
    }
}
