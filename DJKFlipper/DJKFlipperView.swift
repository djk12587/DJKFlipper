//
//  FlipperReDo.swift
//  DJKSwiftFlipper
//
//  Created by Koza, Daniel on 7/13/15.
//  Copyright (c) 2015 Daniel Koza. All rights reserved.
//

import UIKit

public enum FlipperState {
    case began
    case active
    case inactive
}

@objc public protocol DJKFlipperDataSource {
    func numberOfPages(_ flipper:DJKFlipperView) -> NSInteger
    func viewForPage(_ page:NSInteger, flipper:DJKFlipperView) -> UIView
}

open class DJKFlipperView: UIView {
    
    //MARK: - Property Declarations
    
    var viewControllerSnapShots:[UIImage?] = []
    open var dataSource:DJKFlipperDataSource? {
        didSet {
            reload()
        }
    }
    
    lazy var staticView:DJKStaticView = {
        let view = DJKStaticView(frame: self.frame)
        return view
        }()
    
    var flipperState = FlipperState.inactive
    var activeView:UIView?
    var currentPage = 0
    var animatingLayers:[DJKAnimationLayer] = []
    
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initHelper()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initHelper()
    }
    
    func initHelper() {
        NotificationCenter.default.addObserver(self, selector: #selector(DJKFlipperView.deviceOrientationDidChangeNotification), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DJKFlipperView.clearAnimations), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(DJKFlipperView.pan(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.staticView.updateFrame(self.frame)
    }
    
    func updateTheActiveView() {
        
        if let dataSource = self.dataSource {
            if dataSource.numberOfPages(self) > 0 {
                
                if let activeView = self.activeView {
                    if activeView.isDescendant(of: self) {
                        activeView.removeFromSuperview()
                    }
                }
                
                self.activeView = dataSource.viewForPage(self.currentPage, flipper: self)
                self.addSubview(self.activeView!)
                
                //set up the constraints
                self.activeView?.translatesAutoresizingMaskIntoConstraints = false
                let viewDictionary = ["activeView":self.activeView!]
                let constraintTop = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.alignAllTop, metrics: nil, views: viewDictionary)
                let constraintLeft = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: viewDictionary)
                
                self.addConstraints(constraintTop)
                self.addConstraints(constraintLeft)
                
            }
        }
    }
    
    //MARK: - Pan Gesture States
    
    @objc func pan(_ gesture:UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: gesture.view!).x
        let progress = translation / gesture.view!.bounds.size.width
        
        switch (gesture.state) {
        case .began:
            panBegan(gesture)
        case .changed:
            panChanged(gesture, translation: translation, progress: progress)
        case .ended:
            panEnded(gesture, translation: translation)
        case .cancelled:
            enableGesture(gesture, enable: true)
        case .failed:
            print("Failed")
        case .possible:
            print("Possible")
        }
    }
    
    //MARK: Pan Gesture State Began
    
    func panBegan(_ gesture:UIPanGestureRecognizer) {
        if checkIfAnimationsArePassedHalfway() != true {
            enableGesture(gesture, enable: false)
        } else {
            
            if flipperState == .inactive {
                flipperState = .began
            }
            
            let animationLayer = DJKAnimationLayer(frame: self.staticView.rightSide.bounds, isFirstOrLast:false)
            
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
        
        if flipperState == FlipperState.inactive {
            passedHalfWay = true
        } else if animatingLayers.count > 0 {
            //LOOP through this and check the new animation layer with current animations to make sure we dont allow the same animation to happen on a flip up
            for animLayer in animatingLayers {
                let animationLayer = animLayer as DJKAnimationLayer
                var layerIsPassedHalfway = false
                
                let rotationX = animationLayer.presentation()?.value(forKeyPath: "transform.rotation.x") as! CGFloat
                
                if animationLayer.flipDirection == .right && rotationX > 0 {
                    layerIsPassedHalfway = true
                } else if animationLayer.flipDirection == .left && rotationX == 0 {
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
    
    func panChanged(_ gesture:UIPanGestureRecognizer, translation:CGFloat, progress:CGFloat) {
        let progress = progress
        
        if let currentDJKAnimationLayer = animatingLayers.last {
            if currentDJKAnimationLayer.flipAnimationStatus == .beginning {
                animationStatusBeginning(currentDJKAnimationLayer, translation: translation, progress: progress, gesture: gesture)
            } else if currentDJKAnimationLayer.flipAnimationStatus == .active {
                animationStatusActive(currentDJKAnimationLayer, translation: translation, progress: progress)
            } else if currentDJKAnimationLayer.flipAnimationStatus == .completing {
                enableGesture(gesture, enable: false)
                animationStatusCompleting(currentDJKAnimationLayer)
            }
        }
    }
    
    //MARK: Pan Gesture State Ended
    
    func panEnded(_ gesture:UIPanGestureRecognizer, translation:CGFloat) {
        
        if let currentDJKAnimationLayer = animatingLayers.last {
            currentDJKAnimationLayer.flipAnimationStatus = .completing
            
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
    
    func didFlipToNewPage(_ animationLayer:DJKAnimationLayer, gesture:UIPanGestureRecognizer, translation:CGFloat) -> Bool {
        
        let releaseSpeed = getReleaseSpeed(translation, gesture: gesture)
        
        var didFlipToNewPage = false
        if animationLayer.flipDirection == .left && fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed < 0 ||
            animationLayer.flipDirection == .right && fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed > 0 {
                didFlipToNewPage = true
        }
        return didFlipToNewPage
    }
    
    func getReleaseSpeed(_ translation:CGFloat, gesture:UIPanGestureRecognizer) -> CGFloat {
        return (translation + gesture.velocity(in: self).x/4) / self.bounds.size.width
    }
    
    func handleDidNotFlipToNewPage(_ animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
            animationLayer.flipDirection = .right
            self.currentPage = self.currentPage - 1
        } else {
            animationLayer.flipDirection = .left
            self.currentPage = self.currentPage + 1
        }
    }
    
    //MARK: - DJKAnimationLayer States
    
    //MARK: DJKAnimationLayer State Began
    
    func animationStatusBeginning(_ currentDJKAnimationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat, gesture:UIPanGestureRecognizer) {
        if currentDJKAnimationLayer.flipAnimationStatus == .beginning {
            
            flipperState = .active
            
            //set currentDJKAnimationLayers direction
            currentDJKAnimationLayer.updateFlipDirection(getFlipDirection(translation))
            
            if handleConflictingAnimationsWithDJKAnimationLayer(currentDJKAnimationLayer) == false {
                //check if swipe is fast enough to be considered a complete page swipe
                if isIncrementalSwipe(gesture, animationLayer: currentDJKAnimationLayer) {
                    currentDJKAnimationLayer.flipAnimationStatus = .active
                } else {
                    currentDJKAnimationLayer.flipAnimationStatus = .completing
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
                
                if currentDJKAnimationLayer.flipAnimationStatus == .active {
                    animationStatusActive(currentDJKAnimationLayer, translation: translation, progress: progress)
                }
            } else {
                enableGesture(gesture, enable: false)
            }
        }
    }
    
    //MARK: DJKAnimationLayer State Begin Helpers
    
    func getFlipDirection(_ translation:CGFloat) -> FlipDirection {
        if translation > 0 {
            return .right
        } else {
            return .left
        }
    }
    
    func isIncrementalSwipe(_ gesture:UIPanGestureRecognizer, animationLayer:DJKAnimationLayer) -> Bool {
        
        var incrementalSwipe = false
        if fabs(gesture.velocity(in: self).x) < 500 || animationLayer.isFirstOrLastPage == true {
            incrementalSwipe = true
        }
        
        return incrementalSwipe
    }
    
    func updateViewControllerSnapShotsWithCurrentPage(_ currentPage:Int) {
        if let numberOfPages = dataSource?.numberOfPages(self) {
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
    
    func setUpDJKAnimationLayerFrontAndBack(_ animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
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
                animationLayer.flipProperties.endFlipAngle = -CGFloat.pi + 1.5
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
    
    func setUpStaticLayerForTheDJKAnimationLayer(_ animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
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
    
    func animationStatusActive(_ currentDJKAnimationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat) {
        performIncrementalAnimationToLayer(currentDJKAnimationLayer, translation: translation, progress: progress)
    }
    
    //MARK: DJKAnimationLayer State Active Helpers
    
    func performIncrementalAnimationToLayer(_ animationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat) {
        var progress = progress
        
        if translation > 0 {
            progress = max(progress, 0)
        } else {
            progress = min(progress, 0)
        }
        
        progress = fabs(progress)
        setUpForFlip(animationLayer, progress: progress, animated: false, clearFlip: false)
    }
    
    //MARK DJKAnimationLayer State Complete
    
    func animationStatusCompleting(_ animationLayer:DJKAnimationLayer) {
        performCompleteAnimationToLayer(animationLayer)
    }
    
    //MARK: Animation State Complete Helpers
    
    func performCompleteAnimationToLayer(_ animationLayer:DJKAnimationLayer) {
        setUpForFlip(animationLayer, progress: 1.0, animated: true, clearFlip: true)
    }
    
    //MARK: - Animation Conflict Detection
    
    func handleConflictingAnimationsWithDJKAnimationLayer(_ animationLayer:DJKAnimationLayer) -> Bool {
        
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
    
    func getHighestDJKAnimationLayerFromDirection(_ flipDirection:FlipDirection) -> DJKAnimationLayer? {
        
        var animationsInSameDirection:[DJKAnimationLayer] = []
        
        for animLayer in animatingLayers {
            if animLayer.flipDirection == flipDirection {
                animationsInSameDirection.append(animLayer)
            }
        }

        return animationsInSameDirection.sorted(by: {$0.zPosition > $1.zPosition}).first
    }
    
    func getOppositeAnimationDirectionFromLayer(_ animationLayer:DJKAnimationLayer) -> FlipDirection {
        var animationLayerOppositeDirection = FlipDirection.left
        if animationLayer.flipDirection == .left {
            animationLayerOppositeDirection = .right
        }
        
        return animationLayerOppositeDirection
    }
    
    func removeDJKAnimationLayer(_ animationLayer:DJKAnimationLayer) {
        animationLayer.flipAnimationStatus = .fail
        
        var zPos = animationLayer.bounds.size.height
        
        if let highestZPosAnimLayer = getHighestZIndexDJKAnimationLayer() {
            zPos = zPos + highestZPosAnimLayer.zPosition
        } else {
            zPos = 0
        }
        
        animatingLayers.remove(object: animationLayer)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        animationLayer.zPosition = zPos
        CATransaction.commit()
    }
    
    func reverseAnimationForLayer(_ animationLayer:DJKAnimationLayer) {
        animationLayer.flipAnimationStatus = .interrupt
        
        if animationLayer.flipDirection == .left {
            currentPage = currentPage - 1
            animationLayer.updateFlipDirection(.right)
            setUpForFlip(animationLayer, progress: 1.0, animated: true, clearFlip: true)
        } else if animationLayer.flipDirection == .right {
            currentPage = currentPage + 1
            animationLayer.updateFlipDirection(.left)
            setUpForFlip(animationLayer, progress: 1.0, animated: true, clearFlip: true)
        }
    }
    
    //MARK: - Flip Animation Methods
    
    func setUpForFlip(_ animationLayer:DJKAnimationLayer, progress:CGFloat, animated:Bool, clearFlip:Bool) {
        
        let newAngle:CGFloat = animationLayer.flipProperties.startAngle + progress * (animationLayer.flipProperties.endFlipAngle - animationLayer.flipProperties.startAngle)
        
        var duration:CGFloat
        
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
    
    func performFlipWithDJKAnimationLayer(_ animationLayer:DJKAnimationLayer, duration:CGFloat, clearFlip:Bool) {
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
    
    func clearFlipAfterCompletion(_ animationLayer:DJKAnimationLayer) {
        weak var weakSelf = self
        CATransaction.setCompletionBlock { () -> Void in
            
            DispatchQueue.main.async(execute: {
                if animationLayer.flipAnimationStatus == .interrupt {
                    animationLayer.flipAnimationStatus = .completing
                    
                } else if animationLayer.flipAnimationStatus == .completing {
                    animationLayer.flipAnimationStatus = .none
                    
                    if animationLayer.isFirstOrLastPage == false {
                        CATransaction.begin()
                        CATransaction.setAnimationDuration(0)
                        if animationLayer.flipDirection == .left {
                            weakSelf?.staticView.leftSide.contents = animationLayer.backLayer.contents
                        } else {
                            weakSelf?.staticView.rightSide.contents = animationLayer.frontLayer.contents
                        }
                        CATransaction.commit()
                    }
                    
                    weakSelf?.animatingLayers.remove(object: animationLayer)
                    animationLayer.removeFromSuperlayer()
                    
                    if weakSelf?.animatingLayers.count == 0 {
                        
                        weakSelf?.flipperState = .inactive
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
    
    func getAnimationDurationFromDJKAnimationLayer(_ animationLayer:DJKAnimationLayer, newAngle:CGFloat) -> CGFloat {
        var durationConstant = DJKFlipperConstants.DurationConstant
        
        if animationLayer.isFirstOrLastPage == true {
            durationConstant = 0.5
        }
        return durationConstant * fabs((newAngle - animationLayer.flipProperties.currentAngle) / (animationLayer.flipProperties.endFlipAngle - animationLayer.flipProperties.startAngle))
    }
    
    func setMaxAngleIfDJKAnimationLayerIsFirstOrLast(_ animationLayer:DJKAnimationLayer, newAngle:CGFloat) {
        if animationLayer.flipDirection == .right {
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
    
    func enableGesture(_ gesture:UIPanGestureRecognizer, enable:Bool) {
        gesture.isEnabled = enable
    }
    
    func getHighestZIndexDJKAnimationLayer() -> DJKAnimationLayer? {
        return animatingLayers.sorted(by: {$0.zPosition > $1.zPosition}).first
    }
    
    @objc func clearAnimations() {
        if flipperState != .inactive {
            //remove all animation layers and update the static view
            updateTheActiveView()
            
            for animation in animatingLayers {
                animation.flipAnimationStatus = .fail
                animation.removeFromSuperlayer()
            }
            animatingLayers.removeAll(keepingCapacity: false)
            
            self.staticView.removeFromSuperlayer()
            CATransaction.flush()
            self.staticView.leftSide.contents = nil
            self.staticView.rightSide.contents = nil
            
            flipperState = .inactive
        }
    }
    
    @objc func deviceOrientationDidChangeNotification() {
        clearAnimations()
    }
    
    //MARK: - Public Methods
    
    open func reload() {
        updateTheActiveView()
        //set an array with capacity for total amount of possible pages
        viewControllerSnapShots.removeAll(keepingCapacity: false)
        for _ in 1...dataSource!.numberOfPages(self) {
            viewControllerSnapShots.append(nil)
        }
    }
}
