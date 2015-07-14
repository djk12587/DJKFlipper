//
//  FlipperReDo.swift
//  DJKSwiftFlipper
//
//  Created by Koza, Daniel on 7/13/15.
//  Copyright (c) 2015 Daniel Koza. All rights reserved.
//

import UIKit

enum FlipperState {
    case Began
    case Active
    case Inactive
}

@objc protocol FlipperDataSource2 {
    func numberOfPages(flipper:FlipperReDo) -> NSInteger
    func viewForPage(page:NSInteger, flipper:FlipperReDo) -> UIView
}

class FlipperReDo: UIView {
    
    //MARK: - Property Declarations
    
    var viewControllerSnapShots:[UIImage?] = []
    var dataSource:FlipperDataSource2? {
        didSet {
            updateTheActiveView()
            //set an array with capacity for total amount of possible pages
            viewControllerSnapShots.removeAll(keepCapacity: false)
            for index in 1...dataSource!.numberOfPages(self) {
                viewControllerSnapShots.append(nil)
            }
        }
    }
    
    lazy var staticView:StaticView = {
        let view = StaticView(frame: self.frame)
        return view
    }()
    
    var flipperState = FlipperState.Inactive
    var activeView:UIView?
    var currentPage = 0
    var animatingLayers:[AnimationLayer] = []
    
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initHelper()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initHelper()
    }
    
    func initHelper() {
        var panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        self.addGestureRecognizer(panGesture)
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
    
    //MARK: - Pan gesture states
    
    func pan(gesture:UIPanGestureRecognizer) {
        
        var translation = gesture.translationInView(gesture.view!).x
        var progress = translation / gesture.view!.bounds.size.width
        
        switch (gesture.state) {
        case .Began:
            panBegan(gesture)
        case .Changed:
            panChangedWithGesture(gesture, translation: translation, progress: progress)
        case .Ended:
            println("Ended")
        case .Cancelled:
            gesture.enabled = true
        case .Failed:
            println("Failed")
        case .Possible:
            println("Possible")
        }
    }
    
    func panBegan(gesture:UIPanGestureRecognizer) {
        if checkIfAnimationsArePassedHalfway() != true {
            gesture.enabled = false
        } else if flipperState == .Inactive {
            
            flipperState = .Began
            
            var screenBounds = UIScreen.mainScreen().bounds
            var animationLayer = AnimationLayer(frame: self.staticView.rightSide.bounds, isFirstOrLast:false)
            
            if let hiZAnimLayer = getHighestZIndexAnimationLayer() {
                animationLayer.zPosition = hiZAnimLayer.zPosition + animationLayer.bounds.size.height
            } else {
                animationLayer.zPosition = 0
            }
            
            animatingLayers.append(animationLayer)
        } else {
            //TODO: - check to see if this ever occurs during use
            println("something is wrong")
        }
    }
    
    func panChangedWithGesture(gesture:UIPanGestureRecognizer, translation:CGFloat, var progress:CGFloat) {

        if var currentAnimationLayer = animatingLayers.last {
            
            switch (currentAnimationLayer.flipAnimationStatus) {
            case .FlipAnimationStatusBeginning:
                println("layer beginning")
                animationStatusBeginning(currentAnimationLayer, translation: translation, progress: progress, gesture: gesture)
            case .FlipAnimationStatusActive:
                animationStatusActive(currentAnimationLayer, translation: translation, progress: progress)
                println("layer active")
            case .FlipAnimationStatusCompleting:
                println("layer completing")
            case .FlipAnimationStatusComplete:
                println("layer complete")
            case .FlipAnimationStatusInterrupt:
                println("layer interrupt")
            case .FlipAnimationStatusFail:
                println("layer fail")
            case .FlipAnimationStatusNone:
                println("layer none")
            }
        }
    }
    
    func animationStatusBeginning(currentAnimationLayer:AnimationLayer, translation:CGFloat, progress:CGFloat, gesture:UIPanGestureRecognizer) {
        if currentAnimationLayer.flipAnimationStatus == .FlipAnimationStatusBeginning && flipperState == .Began {
            
            flipperState = .Active
            
            //set currentAnimationLayers direction
            currentAnimationLayer.updateFlipDirection(getFlipDirection(translation))
            
            //gesture speed is slow
            if isIncrementalSwipe(gesture, animationLayer: currentAnimationLayer) {
                currentAnimationLayer.flipAnimationStatus = .FlipAnimationStatusActive
            } else {
                currentAnimationLayer.flipAnimationStatus = .FlipAnimationStatusCompleting
            }
            
            updateViewControllerSnapShotsWithCurrentPage(self.currentPage)
            setUpAnimationLayerFrontAndBack(currentAnimationLayer)
            setUpStaticLayerForTheAnimationLayer(currentAnimationLayer)
            
            self.layer.addSublayer(currentAnimationLayer)
            //you need to perform a flush otherwise the animation duration is not honored.
            //more information can be found here http://stackoverflow.com/questions/8661355/implicit-animation-fade-in-is-not-working#comment10764056_8661741
            CATransaction.flush()
            
            //add the animation layer to the view
            addAnimationLayer()
            
            if currentAnimationLayer.flipAnimationStatus == .FlipAnimationStatusActive {
                animationStatusActive(currentAnimationLayer, translation: translation, progress: progress)
            } else if currentAnimationLayer.flipAnimationStatus == .FlipAnimationStatusCompleting {
                animationStatusCompleting(currentAnimationLayer)
            }
        }
    }
    
    func animationStatusCompleting(animationLayer:AnimationLayer) {
        performCompleteAnimationToLayer(animationLayer)
    }
    
    func animationStatusActive(currentAnimationLayer:AnimationLayer, translation:CGFloat, progress:CGFloat) {
        performIncrementalAnimationToLayer(currentAnimationLayer, translation: translation, progress: progress)
    }
    
    func performCompleteAnimationToLayer(animationLayer:AnimationLayer) {
        flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
    }
    
    func performIncrementalAnimationToLayer(animationLayer:AnimationLayer, translation:CGFloat, var progress:CGFloat) {
        
        if translation > 0 {
            progress = max(progress, 0)
        } else {
            progress = min(progress, 0)
        }
        
        progress = fabs(progress)
        flipPage(animationLayer, progress: progress, animated: false, clearFlip: false)
    }
    
    func addAnimationLayer() {
        self.layer.addSublayer(staticView)
        CATransaction.flush()
        
        if let activeView = self.activeView {
            activeView.removeFromSuperview()
        }
    }
    
    func isIncrementalSwipe(gesture:UIPanGestureRecognizer, animationLayer:AnimationLayer) -> Bool {
        
        var incrementalSwipe = false
        if fabs(gesture.velocityInView(self).x) < 500 || animationLayer.isFirstOrLastPage == true {
            incrementalSwipe = true
        }
        
        return incrementalSwipe
    }
    
    func setUpStaticLayerForTheAnimationLayer(animationLayer:AnimationLayer) {
        if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
            if animationLayer.isFirstOrLastPage == true && animatingLayers.count <= 1 {
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage]!)
            } else {
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage - 1]!)
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage]!)
            }
        } else {
            if animationLayer.isFirstOrLastPage == true && animatingLayers.count <= 1 {
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage + 1]!)
            } else {
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage + 1]!)
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage]!)
            }
        }
    }
    
    func setUpAnimationLayerFrontAndBack(animationLayer:AnimationLayer) {
        if animationLayer.flipDirection == .FlipDirectionLeft {
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
    
    func updateViewControllerSnapShotsWithCurrentPage(currentPage:Int) {
        if var numberOfPages = dataSource?.numberOfPages(self) {
            if  currentPage <= numberOfPages - 1 {
                //set the current page snapshot
                viewControllerSnapShots[currentPage] = dataSource?.viewForPage(currentPage, flipper: self).takeSnapShotWithoutScreenUpdate()
                
                if currentPage + 1 <= numberOfPages - 1  {
                    //set the right page snapshot
                    if viewControllerSnapShots[currentPage + 1] == nil {
                        viewControllerSnapShots[currentPage + 1] = dataSource?.viewForPage(currentPage + 1, flipper: self).takeSnapshot()
                    }
                }
                
                if currentPage - 1 >= 0 {
                    //set the left page snapshot
                    if viewControllerSnapShots[currentPage - 1] == nil {
                        viewControllerSnapShots[currentPage - 1] = dataSource?.viewForPage(currentPage - 1, flipper: self).takeSnapshot()
                    }
                }
            }
        }
    }
    
    func handleConflictingAnimationsWithAnAnimationLayer(animationLayer:AnimationLayer) -> Bool {
        
        //check if there is an animation layer before that is still animating at the opposite swipe direction
        var animationConflict = false
        if animatingLayers.count > 1 {
            
            if let oppositeAnimationLayer = getHighestAnimationLayerFromDirection(getOppositeAnimationDirectionFromLayer(animationLayer)) {
                if oppositeAnimationLayer.isFirstOrLastPage == false {
                    
                    animationConflict = true
                    //we now need to remove the newly added layer
                    removeAnimationLayer(animationLayer)
                    reverseAnimationForLayer(oppositeAnimationLayer)
                    
                }
            }
        }
        
        return animationConflict
    }
    
    func reverseAnimationForLayer(animationLayer:AnimationLayer) {
        animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusInterrupt
        
        if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
            currentPage = currentPage - 1
            animationLayer.updateFlipDirection(FlipDirection.FlipDirectionRight)
            flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
        } else if animationLayer.flipDirection == FlipDirection.FlipDirectionRight {
            currentPage = currentPage + 1
            animationLayer.updateFlipDirection(FlipDirection.FlipDirectionLeft)
            flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
        }
    }
    
    func removeAnimationLayer(animationLayer:AnimationLayer) {
        animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusFail
        
        var zPos = animationLayer.bounds.size.height
        
        if let highestZPosAnimLayer = getHighestZIndexAnimationLayer() {
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
    
    func getOppositeAnimationDirectionFromLayer(animationLayer:AnimationLayer) -> FlipDirection {
        var animationLayerOppositeDirection = FlipDirection.FlipDirectionLeft
        if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
            animationLayerOppositeDirection = FlipDirection.FlipDirectionRight
        }
        
        return animationLayerOppositeDirection
    }
    
    func getFlipDirection(translation:CGFloat) -> FlipDirection {
        if translation > 0 {
            return FlipDirection.FlipDirectionRight
        } else {
            return FlipDirection.FlipDirectionLeft
        }
    }
    
    //MARK: - Flip Animation Method
    
    func flipPage(page:AnimationLayer,progress:CGFloat,animated:Bool,clearFlip:Bool) {

        var newAngle:CGFloat = page.flipProperties.startAngle + progress * (page.flipProperties.endFlipAngle - page.flipProperties.startAngle)
        var duration:CGFloat
        var durationConstant:CGFloat = 0.75
        
        println(newAngle)
        
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
                    
                    weakSelf?.animatingLayers.removeObject(page)
                    page.removeFromSuperlayer()
                    
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
            }
        }
        
        page.transform = t
        CATransaction.commit()
    }
    
    //MARK: - Helper Methods
    
    func checkIfAnimationsArePassedHalfway() -> Bool{
        var passedHalfWay = false
        
        if flipperState == FlipperState.Inactive {
            passedHalfWay = true
        } else if animatingLayers.count > 0 {
            //LOOP through this and check the new animation layer with current animations to make sure we dont allow the same animation to happen on a flip up
            for animLayer in animatingLayers {
                var animationLayer = animLayer as AnimationLayer
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
    
    func getHighestZIndexAnimationLayer() -> AnimationLayer? {
        
        if animatingLayers.count > 0 {
            var copyOfAnimatingLayers = animatingLayers
            copyOfAnimatingLayers.sort({$0.zPosition > $1.zPosition})
            
            var highestAnimationLayer = copyOfAnimatingLayers.first
            return highestAnimationLayer
        }
        return nil
    }
    
    func getHighestAnimationLayerFromDirection(flipDirection:FlipDirection) -> AnimationLayer? {
        
        var animationsInSameDirection:[AnimationLayer] = []
        
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
}
