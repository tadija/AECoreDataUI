Pod::Spec.new do |s|

s.name = 'AECoreDataUI'
s.version = '4.1.1'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'Super awesome Core Data driven UI for iOS written in Swift'

s.source = { :git => 'https://github.com/tadija/AECoreDataUI.git', :tag => s.version }
s.source_files = 'Sources/AECoreDataUI/*.swift'

s.swift_version = '4.2'

s.ios.deployment_target = '8.0'

s.homepage = 'https://github.com/tadija/AECoreDataUI'
s.author = { 'tadija' => 'tadija@me.com' }
s.social_media_url = 'http://twitter.com/tadija'

end
