Pod::Spec.new do |s|
  s.name             = "DJKFlipper-iOS"
  s.version          = "0.1.0"
  s.summary          = "Flipboard like animation built with swift."
  s.description      = <<-DESC
                      An attempt to copy flipboard like flip animations in swift.
                       DESC
  s.homepage         = "https://github.com/djk12587/DJKSwiftFlipper"
  s.license          = 'MIT'
  s.author           = { "Dan Koza" => "djk12587@gmail.com"}
  s.source           = { :git => "git@github.com:djk12587/DJKSwiftFlipper.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'DJKFlipper/**/*'
  # s.public_header_files = 'DJKFlipper/**/*.h'
  # s.frameworks = 'UIKit'
end
