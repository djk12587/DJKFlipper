//
//  StaticView.swift
//  PageFlipper
//
//  Created by Daniel Koza on 10/2/14.
//  Copyright (c) 2014 Daniel Koza. All rights reserved.
//

import UIKit

class StaticView: CATransformLayer {
    
    convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
        self.addSublayer(leftSide)
        self.addSublayer(rightSide)
        self.zPosition = -3000
    }
    
    override init() {
        super.init()
    }

    lazy var leftSide:CALayer = {
        var lSide = CALayer(layer: self)
        
        var frame = self.bounds
        lSide.frame = frame
        lSide.contentsScale = UIScreen.mainScreen().scale
        lSide.backgroundColor = UIColor.purpleColor().CGColor
        
        return lSide
    }()
    
    lazy var rightSide:CALayer = {
        var rSide = CALayer(layer: self)
        var frame = self.bounds
        frame.size.width = frame.size.width / 2
        frame.origin.x = frame.size.width
        rSide.frame = frame
        rSide.contentsScale = UIScreen.mainScreen().scale
        rSide.backgroundColor = UIColor.cyanColor().CGColor
        return rSide
        }()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSublayer(leftSide)
        self.addSublayer(rightSide)
    }
    
    func setRightSide(image:UIImage) {
        
        var tmpImageRef = image.CGImage
        var rightImgRef = CGImageCreateWithImageInRect(tmpImageRef, CGRectMake(image.size.width/2 * UIScreen.mainScreen().scale, 0, image.size.width/2 * UIScreen.mainScreen().scale, image.size.height * UIScreen.mainScreen().scale))
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        rightSide.contents = rightImgRef
        CATransaction.commit()
    }
    
    func setLeftSide(image:UIImage) {
        var tmpImageRef = image.CGImage
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        leftSide.contents = image.CGImage
        CATransaction.commit()
    }
    
}
