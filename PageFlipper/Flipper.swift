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
                
                self.backgroundView = data.viewForPage(currentPage, flipper: self)
                self.addSubview(self.backgroundView)
            }
        }
    }
    
    var flipperStatus = FlipperStatus.FlipperStatusInactive
    
    var animationArray:NSMutableArray!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        self.addGestureRecognizer(panGesture)
        
        animationArray = NSMutableArray()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
            
            var animationLayer = animationArray.lastObject as AnimationLayer
            if animationLayer.flipAnimationStatus == FlipAnimationStatus.FlipAnimationStatusBeginning {
                
                if translation > 0 {
                    animationLayer.updateFlipDirection(FlipDirection.FlipDirectionRight)
                    
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

                } else {
                    animationLayer.updateFlipDirection(FlipDirection.FlipDirectionLeft)
                    
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
                }
                
                self.layer.addSublayer(animationLayer)
                
                animationLayer.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusActive
            }
            
            if animationLayer.flipDirection == FlipDirection.FlipDirectionLeft {
                progress = min(progress, 0)
                
                if animationLayer.isFirstOrLastPage == true {
                    staticView.setLeftSide(dataSource!.imageForPage(currentPage, fipper: self))
                    staticView.setRightSide(dataSource!.imageForPage(currentPage, fipper: self))
                } else {
                    staticView.setLeftSide(dataSource!.imageForPage(currentPage - 1, fipper: self))
                    staticView.setRightSide(dataSource!.imageForPage(currentPage, fipper: self))
                }
                
            } else {
                progress = max(progress, 0)
                
                if animationLayer.isFirstOrLastPage == true {
                    staticView.setLeftSide(dataSource!.imageForPage(currentPage, fipper: self))
                    staticView.setRightSide(dataSource!.imageForPage(currentPage, fipper: self))
                } else {
                    staticView.setRightSide(dataSource!.imageForPage(currentPage + 1, fipper: self))
                    staticView.setLeftSide(dataSource!.imageForPage(currentPage, fipper: self))
                }
            }
            
            if flipperStatus == FlipperStatus.FlipperStatusBeginning {
                self.layer.addSublayer(staticView)
                backgroundView.removeFromSuperview()                
                flipperStatus = FlipperStatus.FlipperStatusActive
            }
            
            progress = fabs(progress)
            
            flipPage(animationLayer, progress: progress, animated: false, clearFlip: false)
            
            //println("changed")
        case UIGestureRecognizerState.Ended,UIGestureRecognizerState.Cancelled:
            
            var animationLayer = animationArray.lastObject as AnimationLayer
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
            
            println("Ended or Canceled")
        case UIGestureRecognizerState.Failed:
            println("failed")
        case UIGestureRecognizerState.Possible:
            println("Possible")
        }
    }
    
    func flipPage(page:AnimationLayer,progress:CGFloat,animated:Bool,clearFlip:Bool) {
        
        var newAngle:CGFloat = page.flipProperties.startAngle + progress * (page.flipProperties.endFlipAngle - page.flipProperties.startAngle)
        
        var duration:CGFloat
        
        if animated {
            duration = 0.95 * fabs((newAngle - page.flipProperties.currentAngle) / (page.flipProperties.endFlipAngle - page.flipProperties.startAngle))
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
        
        CATransaction.setCompletionBlock { () -> Void in
            if clearFlip {
                page.flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusNone
                self.animationArray.removeObject(page)
                page.removeFromSuperlayer()
                println(self.animationArray.count)
                if self.animationArray.count == 0 {
                    
                    self.backgroundView = self.dataSource!.viewForPage(self.currentPage, flipper: self)
                    self.addSubview(self.backgroundView)

                    self.flipperStatus = FlipperStatus.FlipperStatusInactive
                    self.staticView.removeFromSuperlayer()
                    self.staticView.leftSide.contents = nil
                    self.staticView.rightSide.contents = nil
                }
            }
        }
        
        page.transform = t
        CATransaction.commit()
    }
}
