//
//  ScreenShotExtension.swift
//  PageFlipper
//
//  Created by Daniel Koza on 10/6/14.
//  Copyright (c) 2014 Daniel Koza. All rights reserved.
//

import Foundation
import UIKit


extension UIView {
    func takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
        self.layer.renderInContext(UIGraphicsGetCurrentContext())
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func takeSnapShotWithoutScreenUpdate() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
        var image:UIImage? = nil
        
        if self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates: false) {
            image = UIGraphicsGetImageFromCurrentImageContext()
        }

        UIGraphicsEndImageContext()
        
        return image
    }
}