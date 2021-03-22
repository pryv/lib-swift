Pod::Spec.new do |s|
  s.name             = 'PryvSwiftKit'
  s.version          = '2.1.0'
  s.summary          = 'Pryv Swift library for iOS'

  s.description      = <<-DESC
  An SDK to connect and interact with Pryv.io from any iOS application.
                       DESC

  s.homepage         = 'https://github.com/pryv/lib-swift'
  s.license      = { :type => 'Revised BSD license', :file => 'LICENSE' }
  s.authors      = { 'Pryv SA (Switzerland)' => 'http://pryv.com' }
  s.source           = { :git => 'https://github.com/pryv/lib-swift.git', :branch => "master" }

  s.ios.deployment_target = '10.0'

  s.source_files = 'PryvSwiftKit/**/*'
  s.exclude_files = "PryvSwiftKit/*.plist"
  
  s.dependency 'Alamofire'
  s.dependency 'Socket.IO-Client-Swift'
  s.dependency 'PromisesSwift'
end
