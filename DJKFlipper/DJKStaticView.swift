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
        lSide.contentsScale = UIScreen.main.scale
        lSide.backgroundColor = UIColor.black.cgColor
        
        return lSide
    }()
    
    lazy var rightSide:CALayer = {
        var rSide = CALayer(layer: self)
        var frame = self.bounds
        frame.size.width = frame.size.width / 2
        frame.origin.x = frame.size.width
        rSide.frame = frame
        rSide.contentsScale = UIScreen.main.scale
        rSide.backgroundColor = UIColor.black.cgColor
        return rSide
        }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSublayer(leftSide)
        self.addSublayer(rightSide)
    }

    override init(layer: Any) {
        super.init(layer: layer)
        self.addSublayer(leftSide)
        self.addSublayer(rightSide)
    }
    
    func updateFrame(_ newFrame:CGRect) {
        self.frame = newFrame
        updatePageLayerFrames(newFrame)
    }
    
    fileprivate func updatePageLayerFrames(_ newFrame:CGRect) {
        var frame = newFrame
        
        frame.size.width = frame.size.width / 2
        leftSide.frame = frame
        
        frame.origin.x = frame.size.width
        rightSide.frame = frame
    }
    
    func setTheRightSide(_ image:UIImage) {
        
        let tmpImageRef = image.cgImage
        let rightImgRef = tmpImageRef?.cropping(to: CGRect(x: image.size.width/2 * UIScreen.main.scale, y: 0, width: image.size.width/2 * UIScreen.main.scale, height: image.size.height * UIScreen.main.scale))
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        rightSide.contents = rightImgRef
        CATransaction.commit()
    }
    
    func setTheLeftSide(_ image:UIImage) {
        let tmpImageRef = image.cgImage
        
        let leftImgRef = tmpImageRef?.cropping(to: CGRect(x: 0, y: 0, width: image.size.width/2 * UIScreen.main.scale, height: image.size.height * UIScreen.main.scale))
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        leftSide.contents = leftImgRef
        CATransaction.commit()
    }
    
}
