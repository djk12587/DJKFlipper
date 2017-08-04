Pod::Spec.new do |s|
  s.name             = "DJKFlipper"
  s.version          = "0.1.8"
  s.summary          = "Flipboard like flipper library"
  s.description      = <<-DESC
			Built with swift, this library allows you to incorporate flipboard like animations to your application.
                       DESC
  s.homepage         = "https://github.com/djk12587/DJKFlipper"
  s.license          = 'MIT'
  s.author           = { "Dan Koza" => "djk12587@gmail.com" }
  s.source           = { :git => "https://github.com/djk12587/DJKFlipper.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'DJKFlipper/**/*'

  # s.public_header_files = 'DJKFlipper**/*.h'
  # s.frameworks = 'UIKit'
end
