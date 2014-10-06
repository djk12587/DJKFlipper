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
}

enum FlipAnimationStatus {
    case FlipAnimationStatusNone
    case FlipAnimationStatusBeginning
    case FlipAnimationStatusActive
    case FlipAnimationStatusCompleting
    case FlipAnimationStatusFail
}

class AnimationLayer: CATransformLayer {
    
    var frontLayer:CALayer!
    var backLayer:CALayer!
    
    var flipDirection:FlipDirection!
    var flipAnimationStatus = FlipAnimationStatus.FlipAnimationStatusNone
    
    var flipProperties = AnimationProperties(currentAngle: 0, startAngle: 0, endFlipAngle: CGFloat(-M_PI))
    
    var isFirstOrLastPage:Bool!
    
    convenience init(frame:CGRect, isFirstOrLast:Bool) {
        self.init()
        self.anchorPoint = CGPoint(x: 1.0, y: 0.5)
        self.frame = frame
        
        isFirstOrLastPage = isFirstOrLast

        backLayer = CALayer(layer: self)
        backLayer.frame = self.bounds
        backLayer.doubleSided = false
        backLayer.transform = CATransform3DMakeRotation(0, 0, 1.0, 0);
//        backLayer.contentsScale = UIScreen.mainScreen().scale
        backLayer.backgroundColor = UIColor.greenColor().CGColor
        
        self.addSublayer(backLayer)
        
        frontLayer = CALayer(layer: self)
        frontLayer.frame = self.bounds
        frontLayer.doubleSided = false
        frontLayer.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0, 1.0, 0);
//        frontLayer.contentsScale = UIScreen.mainScreen().scale
        frontLayer.backgroundColor = UIColor.cyanColor().CGColor
        
        self.addSublayer(frontLayer)
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
    
    override init(layer: AnyObject!) {
        super.init(layer: layer)
    }
    
    
    override init() {
        super.init()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
}
