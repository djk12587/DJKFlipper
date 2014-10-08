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

protocol FlipperDataSource {
    func numberOfPages(flipper:Flipper) -> NSInteger
    func imageForPage(page:NSInteger, fipper:Flipper) -> UIImage
    func viewForPage(page:NSInteger, flipper:Flipper) -> UIView
}

class Flipper: UIView {
    
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
            
            if oldPage > self._currentPage {
                //page flip right
            } else if oldPage < self._currentPage{
                //page flip left
            } else {
                //no page change
            }
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
                
                getAndAddNewBackground()
            }
        }
    }
    
    var flipperStatus = FlipperStatus.FlipperStatusInactive
    
    var animationArray:NSMutableArray = NSMutableArray()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        self.addGestureRecognizer(panGesture)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        var panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        self.addGestureRecognizer(panGesture)
    }
    
    override func layoutSublayersOfLayer(layer: CALayer!) {
        super.layoutSublayersOfLayer(layer)
        
        if staticView.bounds != self.bounds {
            staticView.updateFrame(self.bounds)
        }
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
    }
    
    func pan(gesture:UIPanGestureRecognizer) {
        
        var translation = gesture.translationInView(gesture.view!).x
        var progress = translation / gesture.view!.bounds.size.width
        
        switch (gesture.state) {
        case UIGestureRecognizerState.Began:
            
            if flipperStatus == FlipperStatus.FlipperStatusInactive {
                flipperStatus = FlipperStatus.FlipperStatusBeginning
            }
            
            var animationLayer = AnimationLayer(frame: staticView.rightSide.bounds, isFirstOrLast:false)
            animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusBeginning
            
            if var lastAnimationLayer = animationArray.lastObject as? AnimationLayer {
                animationLayer.zPosition = lastAnimationLayer.zPosition + animationLayer.bounds.size.height
            } else {
                animationLayer.zPosition = 0;
            }
            
            animationArray.addObject(animationLayer)
            
        case UIGestureRecognizerState.Changed:
            
            if var animationLayer = animationArray.lastObject as? AnimationLayer {
                //check if there is an animation layer before that is still animating at the opposite swipe direction
                //If there is then we need to remove the newly added layer and grab that previous layer and animate it in the opposite direction
                if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning {
                    
                    if translation > 0 {
                        animationLayer.updateFlipDirection(FlipDirection.FlipDirectionRight)
                    } else {
                        animationLayer.updateFlipDirection(FlipDirection.FlipDirectionLeft)
                    }
                    
                    if animationArray.count > 1 {
                        var previousAnimationLayer = animationArray[animationArray.count - 2] as AnimationLayer
                        
                        if previousAnimationLayer.flipDirection != animationLayer.flipDirection && !previousAnimationLayer.isFirstOrLastPage {
                            animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusFail
                            
                            animationArray.removeObject(animationLayer)
                            animationLayer = previousAnimationLayer
                            
                            animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusInterrupt
                            
                            if previousAnimationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                                currentPage = currentPage - 1
                                animationLayer.updateFlipDirection(FlipDirection.FlipDirectionRight)
                                flipPage(animationLayer, progress: 0.0, animated: true, clearFlip: true)
                            } else {
                                currentPage = currentPage + 1
                                animationLayer.updateFlipDirection(FlipDirection.FlipDirectionLeft)
                                flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
                            }
                        }
                    }
                    
                    //if there is no conflict we create the set the front and back layer sides for the animation layer
                    //we also need to create the static layer that sites below the animation layer
                    if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning {
                        switch animationLayer.flipDirection {
                        case FlipDirection.FlipDirectionNotSet:
                            println("not set")
                        case FlipDirection.FlipDirectionLeft:
                            if currentPage + 1 > numberOfPages - 1 {
                                //we are at the end
                                animationLayer.flipProperties.endFlipAngle = -1.5
                                animationLayer.isFirstOrLastPage = true
                                animationLayer.setFrontLayer(dataSource!.imageForPage(currentPage, fipper: self))
                            } else {
                                //next page flip
                                animationLayer.setFrontLayer(dataSource!.imageForPage(currentPage, fipper: self))
                                currentPage = currentPage + 1
                                animationLayer.setBackLayer(dataSource!.imageForPage(currentPage, fipper: self))
                            }
                        case FlipDirection.FlipDirectionRight:
                            if currentPage - 1 < 0 {
                                animationLayer.flipProperties.endFlipAngle = CGFloat(-M_PI) + 1.5
                                animationLayer.isFirstOrLastPage = true
                                animationLayer.setBackLayer(dataSource!.imageForPage(currentPage, fipper: self))
                            } else {
                                //previous page flip
                                animationLayer.setBackLayer(dataSource!.imageForPage(currentPage, fipper: self))
                                currentPage = currentPage - 1
                                animationLayer.setFrontLayer(dataSource!.imageForPage(currentPage, fipper: self))
                            }
                        }
                        
                        //set up the static layer
                        if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                            
                            if animationLayer.isFirstOrLastPage == true {
                                staticView.setLeftSide(dataSource!.imageForPage(currentPage, fipper: self))
                                staticView.setRightSide(dataSource!.imageForPage(currentPage, fipper: self))
                            } else {
                                staticView.setLeftSide(dataSource!.imageForPage(currentPage - 1, fipper: self))
                                staticView.setRightSide(dataSource!.imageForPage(currentPage, fipper: self))
                            }
                            
                        } else {
                            if animationLayer.isFirstOrLastPage == true {
                                staticView.setLeftSide(dataSource!.imageForPage(currentPage, fipper: self))
                                staticView.setRightSide(dataSource!.imageForPage(currentPage, fipper: self))
                            } else {
                                staticView.setRightSide(dataSource!.imageForPage(currentPage + 1, fipper: self))
                                staticView.setLeftSide(dataSource!.imageForPage(currentPage, fipper: self))
                            }
                        }
                        
                        self.layer.addSublayer(animationLayer)
                        
                        //if the user is swiping the screen with a lot of velocity just perform the entire animation at once
                        //you need to perform a flush otherwise the animation duration is not honored.
                        //more information can be found here http://stackoverflow.com/questions/8661355/implicit-animation-fade-in-is-not-working#comment10764056_8661741
                        if fabs(gesture.velocityInView(self).x) > 500 {
                            if animationLayer.isFirstOrLastPage == true {
                                animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusActive
                            } else {
                                CATransaction.flush()
                            }
                        } else {
                            animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusActive
                        }
                    }
                }
                
                if flipperStatus == FlipperStatus.FlipperStatusBeginning {
                    self.layer.addSublayer(staticView)
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
            
        case UIGestureRecognizerState.Ended,UIGestureRecognizerState.Cancelled:
            
            if var animationLayer = animationArray.lastObject as? AnimationLayer {
                if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusActive {
                    animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusCompleting
                    
                    var releaseSpeed:CGFloat = (translation + gesture.velocityInView(self).x/4) / self.bounds.size.width
                    var speedThreshold:CGFloat = 0.5
                    
                    if fabs(releaseSpeed) > speedThreshold && !animationLayer.isFirstOrLastPage {
                        flipPage(animationLayer, progress: 1.0, animated: true, clearFlip: true)
                    } else {
                        
                        if !animationLayer.isFirstOrLastPage {
                            if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                                currentPage = currentPage - 1
                            } else {
                                currentPage = currentPage + 1
                            }
                        }
                        
                        flipPage(animationLayer, progress: 0.0, animated: true, clearFlip: true)
                    }
                }
            }
            
        case UIGestureRecognizerState.Failed:
            println("failed")
        case UIGestureRecognizerState.Possible:
            println("Possible")
        }
    }
    
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
            CATransaction.setCompletionBlock { () -> Void in
                
                if page.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusInterrupt {

                    page.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusCompleting
                    
                } else if page.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusCompleting {
                    page.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusNone
                    self.animationArray.removeObject(page)
                    page.removeFromSuperlayer()
                    if self.animationArray.count == 0 {
                        
                        self.flipperStatus = FlipperStatus.FlipperStatusInactive

                        self.getAndAddNewBackground()

                        self.staticView.removeFromSuperlayer()
                        self.staticView.leftSide.contents = nil
                        self.staticView.rightSide.contents = nil
                    }
                }
            }
        }
        
        page.transform = t
        CATransaction.commit()
    }
}
