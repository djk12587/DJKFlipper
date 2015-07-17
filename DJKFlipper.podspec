#
# Be sure to run `pod lib lint DJKCocoaTest.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DJKFlipper"
  s.version          = "0.1.0"
  s.summary          = "Flipboard like flipper library"
  s.description      = <<-DESC
			Built with swift, this library allows you to incorporate flipboard like animations to your application.
                       DESC
  s.homepage         = "https://github.com/djk12587/DJKSwiftFlipper"
  s.license          = 'MIT'
  s.author           = { "Dan Koza" => "djk12587@gmail.com" }
  s.source           = { :git => "https://github.com/djk12587/DJKSwiftFlipper.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'DJKFlipper/**/*'

  # s.public_header_files = 'DJKFlipper**/*.h'
  # s.frameworks = 'UIKit'
end
