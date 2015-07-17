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
func numberOfPages(flipper:DJKFlipper) -> NSInteger
```
 - Give DJKFlipper the number of pages you want to flip through
```swift
func viewForPage(page:NSInteger, flipper:DJKFlipper) -> UIView
```
 - Everytime a page will flip you will need to pass the view of the viewcontroller you want to display.
```swift
func viewForPage(page: NSInteger, flipper: DJKFlipper) -> UIView {
        var viewController = yourViewControllerArray[page] as! YourViewController
        return viewController.view
}
```
## TODO
- Add a reload method when datasource changes.
- Add some error handling :)
- Add ability to change flip from left/right to top/bottom
