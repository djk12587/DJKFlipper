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
    case left
    case right
    case notSet
}

enum FlipAnimationStatus {
    case none
    case beginning
    case active
    case completing
    case complete
    case interrupt
    case fail
}

class DJKAnimationLayer: CATransformLayer {
    
    var flipDirection:FlipDirection = .notSet
    var flipAnimationStatus = FlipAnimationStatus.none
    var flipProperties = AnimationProperties(currentAngle: 0, startAngle: 0, endFlipAngle: -CGFloat.pi)
    var isFirstOrLastPage:Bool = false
    
    lazy var frontLayer:CALayer = {
        var fLayer = CALayer(layer: self)
        fLayer.frame = self.bounds
        fLayer.isDoubleSided = false
        fLayer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 1.0, 0);
        fLayer.backgroundColor = UIColor.black.cgColor
        
        self.addSublayer(fLayer)
        return fLayer
    }()
    
   lazy var backLayer:CALayer = {
        
        var bLayer = CALayer(layer: self)
        bLayer.frame = self.bounds
        bLayer.isDoubleSided = false
        bLayer.transform = CATransform3DMakeRotation(0, 0, 1.0, 0);
        bLayer.backgroundColor = UIColor.green.cgColor
        
        self.addSublayer(bLayer)
        return bLayer
    }()

    convenience init(frame:CGRect, isFirstOrLast:Bool) {
        self.init()
        self.flipAnimationStatus = FlipAnimationStatus.beginning
        self.anchorPoint = CGPoint(x: 1.0, y: 0.5)
        self.frame = frame
        
        isFirstOrLastPage = isFirstOrLast
    }
    
    func updateFlipDirection(_ direction:FlipDirection) {
        flipDirection = direction
        if flipDirection == .left {
            flipProperties.currentAngle = -CGFloat.pi
            flipProperties.startAngle = -CGFloat.pi
            flipProperties.endFlipAngle = 0
            self.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 1, 0);
        } else {
            flipProperties.currentAngle = 0
            flipProperties.startAngle = 0
            flipProperties.endFlipAngle = -CGFloat.pi
            self.transform = CATransform3DMakeRotation(CGFloat(0), 0, 1, 0);
        }
    }
    
    func setTheFrontLayer(_ image:UIImage) {
        let tmpImageRef = image.cgImage
        let rightImgRef = tmpImageRef?.cropping(to: CGRect(x: image.size.width/2 * UIScreen.main.scale, y: 0, width: image.size.width/2 * UIScreen.main.scale, height: image.size.height * UIScreen.main.scale))

        frontLayer.contents = rightImgRef
    }
    
    func setTheBackLayer(_ image:UIImage) {
        let tmpImageRef = image.cgImage
        let rightImgRef = tmpImageRef?.cropping(to: CGRect(x: 0, y: 0, width: image.size.width/2 * UIScreen.main.scale, height: image.size.height * UIScreen.main.scale))
        
        backLayer.contents = rightImgRef
    }
}
