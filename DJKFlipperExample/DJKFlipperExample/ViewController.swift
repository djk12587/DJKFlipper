//
//  ViewController.swift
//  DJKFlipperExample
//
//  Created by Koza, Daniel on 7/17/15.
//  Copyright (c) 2015 Koza, Daniel. All rights reserved.
//

import UIKit
import DJKFlipper

class ViewController: UIViewController, DJKFlipperDataSource {
    
    @IBOutlet weak var flipView: DJKFlipperView!
    
    var flipperViewArray: [UIViewController] = []
    {
        didSet
        {
            flipView.reload()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        flipView.dataSource = self
        
        let page1 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page1.view.frame = self.view.bounds
        page1.backgroundImage.image = UIImage(named: "page1")
        page1.view.layoutSubviews()
        
        let page2 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page2.view.frame = self.view.bounds
        page2.backgroundImage.image = UIImage(named: "page2")
        page2.view.layoutSubviews()
        
        let page3 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page3.view.frame = self.view.bounds
        page3.backgroundImage.image = UIImage(named: "page3")
        page3.view.layoutSubviews()
        
        let page4 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page4.view.frame = self.view.bounds
        page4.backgroundImage.image = UIImage(named: "page4")
        page4.view.layoutSubviews()
        
        let page5 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page5.view.frame = self.view.bounds
        page5.backgroundImage.image = UIImage(named: "page5")
        page5.view.layoutSubviews()
        
        let page6 = PageTestViewController(nibName: "PageTestViewController", bundle: nil)
        page6.view.frame = self.view.bounds
        page6.backgroundImage.image = UIImage(named: "page6")
        page6.view.layoutSubviews()
        
        //add the view controllers to the flipperViewArray
        flipperViewArray += [page1,page2,page3,page4,page5,page6]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - FlipperDataSource Methods
    
    func numberOfPages(_ flipper: DJKFlipperView) -> NSInteger {
        return flipperViewArray.count
    }
    
    func viewForPage(_ page: NSInteger, flipper: DJKFlipperView) -> UIView {
        return flipperViewArray[page].view
    }
}

