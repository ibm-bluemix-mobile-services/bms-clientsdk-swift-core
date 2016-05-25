Pod::Spec.new do |s|

  s.name         = 'BMSCore'
  s.version      = '1.0.2'
  s.summary      = 'The core component of the Swift client SDK for IBM Bluemix Mobile Services'
  s.homepage     = 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core'
  s.license      = 'Apache License, Version 2.0'
  s.authors      = { 'IBM Bluemix Services Mobile SDK' => 'mobilsdk@us.ibm.com' }
  s.source       = { :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :tag => s.version }

  s.source_files = 'Source/**/*'

  s.exclude_files = 'Source/Resources/*.plist'
  s.ios.exclude_files = 'Source/**/*watchOS*.swift'
  s.watchos.exclude_files = 'Source/**/*iOS*.swift'

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'

  s.module_map = 'Source/Resources/module.modulemap'

  s.dependency 'BMSAnalyticsAPI', '~> 1.0'

  s.requires_arc = true

end
