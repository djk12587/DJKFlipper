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
    
    var dataSource:FlipperDataSource2? {
        didSet {
            updateTheActiveView()
        }
    }
    
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
                
                if var activeView = self.activeView {
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
            println("Began")
            
            panBegan(gesture)
            
        case .Changed:
            
            panChanged(translation)
            println("Changed")
        case .Ended:
            println("Ended")
        case .Cancelled:
            println("Cancelled")
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
            var animationLayer = AnimationLayer(frame: CGRectMake(screenBounds.size.width / 2, screenBounds.origin.y, screenBounds.size.width / 2, screenBounds.size.height), isFirstOrLast:false)
            
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
    
    func panChanged(translation:CGFloat) {

        if let lastAnimationLayer = animatingLayers.last {
            if lastAnimationLayer.flipAnimationStatus == .FlipAnimationStatusBeginning {
                lastAnimationLayer.updateFlipDirection(getFlipDirection(translation))
            }
        }
    }
    
    func getFlipDirection(translation:CGFloat) -> FlipDirection {
        if translation > 0 {
            return FlipDirection.FlipDirectionRight
        } else {
            return FlipDirection.FlipDirectionLeft
        }
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
            
            let highestAnimationLayer = copyOfAnimatingLayers.first
            return highestAnimationLayer
        }
        return nil
    }
}
