Pod::Spec.new do |s|
    s.name = 'AECoreDataUI'
    s.version = '3.0.0'
    s.summary = 'Super awesome Core Data driven UI for iOS written in Swift'

    s.homepage = 'https://github.com/tadija/AECoreDataUI'
    s.license = { :type => 'MIT', :file => 'LICENSE' }
    s.author = { 'tadija' => 'tadija@me.com' }
    s.social_media_url = 'http://twitter.com/tadija'

    s.ios.deployment_target = '8.0'

    s.source = { :git => 'https://github.com/tadija/AECoreDataUI.git', :tag => s.version }
    s.source_files = 'Sources/*.swift'
end