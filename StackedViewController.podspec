#
# Be sure to run `pod lib lint StackedViewController.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "StackedViewController"
  s.version          = "0.2.0"
  s.summary          = "StackedViewController is a Container View Controller likely PageViewController."
  s.description      = <<-DESC
                       StackedViewController is a Container View Controller likely PageViewController.
                       Paging with Animation, PanGesture.
                       DESC
  s.homepage         = "https://github.com/ifapmzadu6/StackedViewController"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "ifapmzadu6" => "ifapmzadu6@gmail.com" }
  s.source           = { :git => "https://github.com/ifapmzadu6/StackedViewController.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'StackedViewController' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
