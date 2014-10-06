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
        self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}