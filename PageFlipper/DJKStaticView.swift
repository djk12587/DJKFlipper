//
//  StaticView.swift
//  PageFlipper
//
//  Created by Daniel Koza on 10/2/14.
//  Copyright (c) 2014 Daniel Koza. All rights reserved.
//

import UIKit

class DJKStaticView: CATransformLayer {
    
    convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
        self.addSublayer(leftSide)
        self.addSublayer(rightSide)
        
        self.zPosition = -1_000_000
    }
    
    override init() {
        super.init()
    }

    lazy var leftSide:CALayer = {
        var lSide = CALayer(layer: self)
        
        var frame = self.bounds
        frame.size.width = frame.size.width / 2
        frame.origin.x = 0
        lSide.frame = frame
        lSide.contentsScale = UIScreen.mainScreen().scale
        lSide.backgroundColor = UIColor.blackColor().CGColor
        
        return lSide
    }()
    
    lazy var rightSide:CALayer = {
        var rSide = CALayer(layer: self)
        var frame = self.bounds
        frame.size.width = frame.size.width / 2
        frame.origin.x = frame.size.width
        rSide.frame = frame
        rSide.contentsScale = UIScreen.mainScreen().scale
        rSide.backgroundColor = UIColor.blackColor().CGColor
        return rSide
        }()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSublayer(leftSide)
        self.addSublayer(rightSide)
    }

    override init(layer: AnyObject!) {
        super.init(layer: layer)
        self.addSublayer(leftSide)
        self.addSublayer(rightSide)
    }
    
    func updateFrame(newFrame:CGRect) {
        self.frame = newFrame
        updatePageLayerFrames(newFrame)
    }
    
    private func updatePageLayerFrames(newFrame:CGRect) {
        var frame = newFrame
        
        frame.size.width = frame.size.width / 2
        leftSide.frame = frame
        
        frame.origin.x = frame.size.width
        rightSide.frame = frame
    }
    
    func setTheRightSide(image:UIImage) {
        
        var tmpImageRef = image.CGImage
        var rightImgRef = CGImageCreateWithImageInRect(tmpImageRef, CGRectMake(image.size.width/2 * UIScreen.mainScreen().scale, 0, image.size.width/2 * UIScreen.mainScreen().scale, image.size.height * UIScreen.mainScreen().scale))
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        rightSide.contents = rightImgRef
        CATransaction.commit()
    }
    
    func setTheLeftSide(image:UIImage) {
        var tmpImageRef = image.CGImage
        
        var leftImgRef = CGImageCreateWithImageInRect(tmpImageRef, CGRectMake(0, 0, image.size.width/2 * UIScreen.mainScreen().scale, image.size.height * UIScreen.mainScreen().scale))
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        leftSide.contents = leftImgRef
        CATransaction.commit()
    }
    
}
