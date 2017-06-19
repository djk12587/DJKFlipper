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
        addGestureRecognizer(panGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        staticView.updateFrame(frame)
    }
    
    func updateTheActiveView() {
        guard let datasource = dataSource, datasource.numberOfPages(self) > 0 else { return }
        
        if let activeView = self.activeView, activeView.isDescendant(of: self) {
            activeView.removeFromSuperview()
        }
        
        let activeView = datasource.viewForPage(currentPage, flipper: self)
        self.activeView = activeView

        addSubview(activeView)
        
        //set up the constraints
        self.activeView?.translatesAutoresizingMaskIntoConstraints = false
        let viewDictionary = ["activeView" : activeView]
        let constraintTop = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.alignAllTop, metrics: nil, views: viewDictionary)
        let constraintLeft = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: viewDictionary)
        
        addConstraints(constraintTop)
        addConstraints(constraintLeft)
    }
    
    //MARK: - Pan Gesture States
    
    @objc func pan(_ gesture:UIPanGestureRecognizer) {
        guard let gesturesView = gesture.view else { return }
        let translation = gesture.translation(in: gesturesView).x
        let progress = translation / gesturesView.bounds.size.width
        
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
            
            let animationLayer = DJKAnimationLayer(frame: staticView.rightSide.bounds, isFirstOrLast:false)
            
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
    
    func checkIfAnimationsArePassedHalfway() -> Bool {
        var passedHalfWay = false
        
        if flipperState == FlipperState.inactive {
            passedHalfWay = true
        } else if !animatingLayers.isEmpty {
            //LOOP through this and check the new animation layer with current animations to make sure we dont allow the same animation to happen on a flip up
            for animLayer in animatingLayers {
                let animationLayer = animLayer as DJKAnimationLayer
                var layerIsPassedHalfway = false
                
                if let rotationX = animationLayer.presentation()?.value(forKeyPath: "transform.rotation.x") as? CGFloat
                {
                    if animationLayer.flipDirection == .right && rotationX > 0 {
                        layerIsPassedHalfway = true
                    } else if animationLayer.flipDirection == .left && rotationX == 0 {
                        layerIsPassedHalfway = true
                    }
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
        guard let currentDJKAnimationLayer = animatingLayers.last else { return }
        
        if currentDJKAnimationLayer.flipAnimationStatus == .beginning {
            animationStatusBeginning(currentDJKAnimationLayer, translation: translation, progress: progress, gesture: gesture)
        } else if currentDJKAnimationLayer.flipAnimationStatus == .active {
            animationStatusActive(currentDJKAnimationLayer, translation: translation, progress: progress)
        } else if currentDJKAnimationLayer.flipAnimationStatus == .completing {
            enableGesture(gesture, enable: false)
            animationStatusCompleting(currentDJKAnimationLayer)
        }
    }
    
    //MARK: Pan Gesture State Ended
    
    func panEnded(_ gesture:UIPanGestureRecognizer, translation:CGFloat) {
        guard let currentDJKAnimationLayer = animatingLayers.last else { return }
        
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
    
    //MARK: Pan Ended Helpers
    
    func didFlipToNewPage(_ animationLayer:DJKAnimationLayer, gesture:UIPanGestureRecognizer, translation:CGFloat) -> Bool {
        
        let releaseSpeed = getReleaseSpeed(translation, gesture: gesture)
        
        return animationLayer.flipDirection == .left &&
            fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed < 0 ||
            animationLayer.flipDirection == .right &&
            fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed > 0
    }
    
    private func getReleaseSpeed(_ translation:CGFloat, gesture:UIPanGestureRecognizer) -> CGFloat {
        return (translation + gesture.velocity(in: self).x/4) / bounds.size.width
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
        guard currentDJKAnimationLayer.flipAnimationStatus == .beginning else { return }
        
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
            
            updateViewControllerSnapShotsWithCurrentPage(currentPage)
            setUpDJKAnimationLayerFrontAndBack(currentDJKAnimationLayer)
            setUpStaticLayerForTheDJKAnimationLayer(currentDJKAnimationLayer)
            
            layer.addSublayer(currentDJKAnimationLayer)
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
    
    //MARK: DJKAnimationLayer State Begin Helpers
    
    func getFlipDirection(_ translation:CGFloat) -> FlipDirection {
        if translation > 0 {
            return .right
        } else {
            return .left
        }
    }
    
    func isIncrementalSwipe(_ gesture:UIPanGestureRecognizer, animationLayer:DJKAnimationLayer) -> Bool {
        return fabs(gesture.velocity(in: self).x) < 500 || animationLayer.isFirstOrLastPage
    }
    
    func updateViewControllerSnapShotsWithCurrentPage(_ currentPage:Int) {
        guard let numberOfPages = dataSource?.numberOfPages(self), currentPage <= numberOfPages - 1 else { return }
        //set the current page snapshot
        viewControllerSnapShots[currentPage] = dataSource?.viewForPage(currentPage, flipper: self).takeSnapshot()
        
        if currentPage + 1 <= numberOfPages - 1 && viewControllerSnapShots[currentPage + 1] == nil {
            //set the right page snapshot, if there already is a screen shot then dont update it
            viewControllerSnapShots[currentPage + 1] = dataSource?.viewForPage(currentPage + 1, flipper: self).takeSnapshot()
        }
        
        if currentPage - 1 >= 0 && viewControllerSnapShots[currentPage - 1] == nil {
            //set the left page snapshot, if there already is a screen shot then dont update it
            viewControllerSnapShots[currentPage - 1] = dataSource?.viewForPage(currentPage - 1, flipper: self).takeSnapshot()
        }
    }
    
    func setUpDJKAnimationLayerFrontAndBack(_ animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
            if let datasource = dataSource, currentPage + 1 > datasource.numberOfPages(self) - 1 {
                //we are at the end
                animationLayer.flipProperties.endFlipAngle = -1.5
                animationLayer.isFirstOrLastPage = true
                animationLayer.setTheFrontLayer(viewControllerSnapShots[currentPage] ?? UIImage())
            } else {
                //next page flip
                animationLayer.setTheFrontLayer(viewControllerSnapShots[currentPage] ?? UIImage())
                currentPage = currentPage + 1
                animationLayer.setTheBackLayer(viewControllerSnapShots[currentPage] ?? UIImage())
            }
        } else {
            if currentPage - 1 < 0 {
                //we are at the end
                animationLayer.flipProperties.endFlipAngle = -CGFloat.pi + 1.5
                animationLayer.isFirstOrLastPage = true
                animationLayer.setTheBackLayer(viewControllerSnapShots[currentPage] ?? UIImage())
            } else {
                //previous page flip
                animationLayer.setTheBackLayer(viewControllerSnapShots[currentPage] ?? UIImage())
                currentPage = currentPage - 1
                animationLayer.setTheFrontLayer(viewControllerSnapShots[currentPage] ?? UIImage())
            }
        }
    }
    
    func setUpStaticLayerForTheDJKAnimationLayer(_ animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
            if animationLayer.isFirstOrLastPage && animatingLayers.count <= 1 {
                staticView.setTheLeftSide(viewControllerSnapShots[currentPage] ?? UIImage())
            } else {
                staticView.setTheLeftSide(viewControllerSnapShots[currentPage - 1] ?? UIImage())
                staticView.setTheRightSide(viewControllerSnapShots[currentPage] ?? UIImage())
            }
        } else if animationLayer.isFirstOrLastPage && animatingLayers.count <= 1 {
            staticView.setTheRightSide(viewControllerSnapShots[currentPage] ?? UIImage())
        } else {
            staticView.setTheRightSide(viewControllerSnapShots[currentPage + 1] ?? UIImage())
            staticView.setTheLeftSide(viewControllerSnapShots[currentPage] ?? UIImage())
        }
    }
    
    func addDJKAnimationLayer() {
        layer.addSublayer(staticView)
        CATransaction.flush()
        activeView?.removeFromSuperview()
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
        
        if let oppositeDJKAnimationLayer =  getHighestDJKAnimationLayerFromDirection(getOppositeAnimationDirectionFromLayer(animationLayer)),
            animatingLayers.count > 1,
            !oppositeDJKAnimationLayer.isFirstOrLastPage
        {
            animationConflict = true
            //we now need to remove the newly added layer
            removeDJKAnimationLayer(animationLayer)
            reverseAnimationForLayer(oppositeDJKAnimationLayer)
        }
        
        return animationConflict
    }
    
    func getHighestDJKAnimationLayerFromDirection(_ flipDirection:FlipDirection) -> DJKAnimationLayer? {
        let animationsInSameDirection = animatingLayers.filter { $0.flipDirection == flipDirection }
        return animationsInSameDirection.sorted(by: {$0.zPosition > $1.zPosition}).first
    }
    
    func getOppositeAnimationDirectionFromLayer(_ animationLayer:DJKAnimationLayer) -> FlipDirection {
        return animationLayer.flipDirection == .left ? .right : .left
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
        let duration: CGFloat = animated ? getAnimationDurationFromDJKAnimationLayer(animationLayer, newAngle: newAngle) : 0
        
        animationLayer.flipProperties.currentAngle = newAngle
        
        if animationLayer.isFirstOrLastPage {
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
                    
                    if !animationLayer.isFirstOrLastPage {
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
                    
                    if weakSelf?.animatingLayers.isEmpty ?? false {
                        
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
        
        if animationLayer.isFirstOrLastPage {
            durationConstant = 0.5
        }
        return durationConstant * fabs((newAngle - animationLayer.flipProperties.currentAngle) / (animationLayer.flipProperties.endFlipAngle - animationLayer.flipProperties.startAngle))
    }
    
    func setMaxAngleIfDJKAnimationLayerIsFirstOrLast(_ animationLayer:DJKAnimationLayer, newAngle:CGFloat) {
        if animationLayer.flipDirection == .right && newAngle < -1.4 {
            animationLayer.flipProperties.currentAngle = -1.4
        } else if newAngle > -1.8 {
            animationLayer.flipProperties.currentAngle = -1.8
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
        guard flipperState != .inactive else { return }
        //remove all animation layers and update the static view
        updateTheActiveView()
        
        for animation in animatingLayers {
            animation.flipAnimationStatus = .fail
            animation.removeFromSuperlayer()
        }
        animatingLayers.removeAll(keepingCapacity: false)
        
        staticView.removeFromSuperlayer()
        CATransaction.flush()
        staticView.leftSide.contents = nil
        staticView.rightSide.contents = nil
        
        flipperState = .inactive
    }
    
    @objc func deviceOrientationDidChangeNotification() {
        clearAnimations()
    }
    
    //MARK: - Public Methods
    
    open func reload() {
        updateTheActiveView()
        //set an array with capacity for total amount of possible pages
        viewControllerSnapShots.removeAll(keepingCapacity: false)
        
        guard let datasource = dataSource else { return }
        for _ in 1...datasource.numberOfPages(self) {
            viewControllerSnapShots.append(nil)
        }
    }
}
