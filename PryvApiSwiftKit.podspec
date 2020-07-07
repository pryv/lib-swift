#
# Be sure to run `pod lib lint PryvApiSwiftKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PryvApiSwiftKit'
  s.version          = '2.1.0'
  s.summary          = 'Pryv Swift library for iOS'

  s.description      = <<-DESC
  An SDK to connect and interact with Pryv API from any iOS application.
                       DESC

  s.homepage         = 'https://github.com/pryv/lib-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'alemannosara' => 'sara.alemanno@epfl.ch' }
  s.source           = { :git => 'https://github.com/pryv/lib-swift.git', :branch => "master" }

  s.ios.deployment_target = '10.0'

  s.source_files = 'PryvApiSwiftKit/Classes/**/*'
  
  s.dependency 'Mocker'
  s.dependency 'Alamofire'
  s.dependency 'Socket.IO-Client-Swift'
  s.dependency 'PromisesSwift'
end
