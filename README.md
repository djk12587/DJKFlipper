DJKFlipper
===============

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CocoaPods compatible](https://img.shields.io/cocoapods/v/DJKFlipper.svg)](https://cocoapods.org/pods/DJKFlipper)

Flipboard like animation built with swift. 

![Flipboard playing multiple GIFs](https://raw.githubusercontent.com/djk12587/DJKSwiftFlipper/master/example.gif)

## Installation
### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

To integrate DJKFlipper into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'DJKFlipper'
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

To integrate DJKFlipper into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "DJK12587/DJKFlipper"
```
Then, run the following command:

```bash
$ carthage update
```
Then add the built framework anyway you want to your project.

## Usage
```swift
import DJKFlipper
```
 - Conform to the DJKFlipperDatasource protocol in your viewController

### DataSource Methods
```swift
func numberOfPages(flipper:DJKFlipperView) -> NSInteger
```
 - Give DJKFlipper the number of pages you want to flip through
```swift
func viewForPage(page:NSInteger, flipper:DJKFlipperView) -> UIView
```
 - Everytime a page will flip you will need to pass the view of the viewcontroller you want to display.
```swift
func viewForPage(page: NSInteger, flipper: DJKFlipperView) -> UIView {
    return yourViewControllerArray[page].view
}
```

## How It Works
http://stackoverflow.com/a/26266025

I attempted to solve this problem by using CALayers and Core Animation. I have two main layers to accomplish this animation, a static layer and an animation layer.

The static layer is the size of the entire view. This layer does not animate it simply holds two images, the left and right side (left and right side images are screen shots of the pages you want to flip too). The animation layer is half the size of the entire view, and this layer animates to perform the flip animation. The animation layers front and back side are also screen shots of the current page and next page.

For example lets say we want to flip to the next page.

The static layer's left side will contain a screen shot of the left side of the current page. The Right side will contain a screen shot of the right side of the next page. The animation layer will sit on top of the static view and its front side will contain an screen shot of the right side of the current page. The back of the animation layer will contain a screen shot of the left side of the next page.

As you pan your finger you will perform a CATransform3DRotate on the y axis of the animation layer. So, as your finger moves from the right side of the screen to the left, the animation layer will flip over and reveal the right side of the static view and back side of itself.

Here is the basic code to perform a flip animation on a layer (animationLayer CALayer).
```swift
    var t = CATransform3DIdentity
    t.m34 = 1.0/850 //Adds depth to the animation
    t = CATransform3DRotate(t, newRadianAngleValue, 0, 1, 0)

    CATransaction.begin()
    CATransaction.setAnimationDuration(0)
    yourAnimationCALayer.transform = t
    CATransaction.commit()
```

## TODO
- Add some error handling :)
- Add ability to change flip from left/right to top/bottom
- Add unit tests
- Add documentation ;)
