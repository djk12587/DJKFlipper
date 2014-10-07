//
//  AnimationLayer.swift
//  PageFlipper
//
//  Created by Daniel Koza on 10/2/14.
//  Copyright (c) 2014 Daniel Koza. All rights reserved.
//

import UIKit
import Darwin

struct AnimationProperties {
    var currentAngle:CGFloat
    var startAngle:CGFloat
    var endFlipAngle:CGFloat
}

enum FlipDirection {
    case FlipDirectionLeft
    case FlipDirectionRight
    case FlipDirectionNotSet
}

enum FlipAnimationStatus {
    case FlipAnimationStatusNone
    case FlipAnimationStatusBeginning
    case FlipAnimationStatusActive
    case FlipAnimationStatusCompleting
    case FlipAnimationStatusInterrupt
    case FlipAnimationStatusFail
}

class AnimationLayer: CATransformLayer {
    
    var flipDirection:FlipDirection = FlipDirection.FlipDirectionNotSet
    var flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusNone
    var flipProperties = AnimationProperties(currentAngle: 0, startAngle: 0, endFlipAngle: CGFloat(-M_PI))
    var isFirstOrLastPage:Bool = false
    
    lazy var frontLayer:CALayer = {
        var fLayer = CALayer(layer: self)
        fLayer.frame = self.bounds
        fLayer.doubleSided = false
        fLayer.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0, 1.0, 0);
        fLayer.backgroundColor = UIColor.cyanColor().CGColor
        
        self.addSublayer(fLayer)
        return fLayer
    }()
    
   lazy var backLayer:CALayer = {
        
        var bLayer = CALayer(layer: self)
        bLayer.frame = self.bounds
        bLayer.doubleSided = false
        bLayer.transform = CATransform3DMakeRotation(0, 0, 1.0, 0);
        bLayer.backgroundColor = UIColor.greenColor().CGColor
        
        self.addSublayer(bLayer)
        return bLayer
    }()

    convenience init(frame:CGRect, isFirstOrLast:Bool) {
        self.init()
        self.anchorPoint = CGPoint(x: 1.0, y: 0.5)
        self.frame = frame
        
        isFirstOrLastPage = isFirstOrLast
    }
    
    func test() {
        backLayer = CALayer(layer: self)
        backLayer.frame = self.bounds
        backLayer.doubleSided = false
        backLayer.transform = CATransform3DMakeRotation(0, 0, 1.0, 0);
        //        backLayer.contentsScale = UIScreen.mainScreen().scale
        backLayer.backgroundColor = UIColor.greenColor().CGColor
        
        self.addSublayer(backLayer)
    }
    
    func updateFlipDirection(direction:FlipDirection) {
        flipDirection = direction
        if flipDirection == FlipDirection.FlipDirectionLeft {
            flipProperties.currentAngle = CGFloat(-M_PI)
            flipProperties.startAngle = CGFloat(-M_PI)
            flipProperties.endFlipAngle = 0
            self.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0, 1, 0);
        } else {
            self.transform = CATransform3DMakeRotation(CGFloat(0), 0, 1, 0);
        }
    }
    
    func setFrontLayer(image:UIImage) {
        var tmpImageRef = image.CGImage
        var rightImgRef = CGImageCreateWithImageInRect(tmpImageRef, CGRectMake(image.size.width/2 * UIScreen.mainScreen().scale, 0, image.size.width/2 * UIScreen.mainScreen().scale, image.size.height * UIScreen.mainScreen().scale))
        
        frontLayer.contents = rightImgRef
    }
    
    func setBackLayer(image:UIImage) {
        var tmpImageRef = image.CGImage
        var rightImgRef = CGImageCreateWithImageInRect(tmpImageRef, CGRectMake(0, 0, image.size.width/2 * UIScreen.mainScreen().scale, image.size.height * UIScreen.mainScreen().scale))
        
        backLayer.contents = rightImgRef
    }
    
    override init() {
        super.init()
    }
    
    override init(layer: AnyObject!) {
        super.init(layer: layer)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
}
