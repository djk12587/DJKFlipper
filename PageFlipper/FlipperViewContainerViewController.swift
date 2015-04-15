//
//  ViewController.swift
//  PageFlipper
//
//  Created by Daniel Koza on 10/2/14.
//  Copyright (c) 2014 Daniel Koza. All rights reserved.
//

import UIKit

class FlipperViewContainerViewController: UIViewController, FlipperDataSource {
    
    @IBOutlet weak var flipView: Flipper!
    
    //instantiate flipper protocol properties
    var flipperViewArray:[UIViewController] = []
    lazy var flipperSnapshotArray:[UIImage]? = []
    var containerViewController:UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        var page1 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page1.view.frame = self.view.bounds
        page1.backgroundImage.image = UIImage(named: "page1")
        page1.view.backgroundColor = UIColor.purpleColor()
        page1.view.layoutSubviews()
                
        var page2 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page2.view.frame = self.view.bounds
        page2.backgroundImage.image = UIImage(named: "page2")
        page2.view.backgroundColor = UIColor.purpleColor()
        page2.view.layoutSubviews()
        
        var page3 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page3.view.frame = self.view.bounds
        page3.backgroundImage.image = UIImage(named: "page3")
        page3.view.backgroundColor = UIColor.purpleColor()
        page3.view.layoutSubviews()
        
        var page4 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page4.view.frame = self.view.bounds
        page4.backgroundImage.image = UIImage(named: "page4")
        page4.view.backgroundColor = UIColor.purpleColor()
        page4.view.layoutSubviews()
        
        var page5 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page5.view.frame = self.view.bounds
        page5.backgroundImage.image = UIImage(named: "page5")
        page5.view.backgroundColor = UIColor.purpleColor()
        page5.view.layoutSubviews()
        
        var page6 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page6.view.frame = self.view.bounds
        page6.backgroundImage.image = UIImage(named: "page6")
        page6.view.backgroundColor = UIColor.purpleColor()
        page6.view.layoutSubviews()
        
        //add the view controllers to the flipperViewArray
        flipperViewArray += [page1,page2,page3,page4,page5,page6]
//        flipperViewArray.addObjectsFromArray([page1,page2,page3,page4,page5,page6])
        
        
        //take an initial screenShot of all of the flippable view controllers
        for viewController in flipperViewArray {
            let flipView = viewController as! PageTestViewController
            flipperSnapshotArray?.append(flipView.view.takeSnapshot())
        }
        
        //set the delegate and containerViewController
        //The containerViewController will allow the flippable viewControllers to go through the viewcontroller life cycle, viewDidAppear, viewDidDisappear, etc
        flipView?.dataSource = self
        containerViewController = self
        
        //tell the flipView to update the home page
        flipView.setHomePage()
    }
    
    //MARK: - FlipperDataSource Methods
    
    func numberOfPages(flipper: Flipper) -> NSInteger {
        return flipperViewArray.count
    }
    
    func imageForPage(page: NSInteger, fipper: Flipper) -> UIImage? {
        if var snapShot = flipperSnapshotArray?[page] {
            return snapShot
        } else {
            return nil
        }
    }
    
    func viewForPage(page: NSInteger, flipper: Flipper) -> UIView {
        var viewController = flipperViewArray[page] as! PageTestViewController
        return viewController.view
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func shouldAutorotate() -> Bool {
        if flipView.flipperStatus == FlipperStatus.FlipperStatusInactive {
            return true
        } else {
            return false
        }
    }
}

