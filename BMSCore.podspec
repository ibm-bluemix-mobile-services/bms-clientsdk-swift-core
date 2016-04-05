Pod::Spec.new do |s|

  s.name         = 'BMSCore'
  s.version      = '0.0.43'
  s.summary      = 'The core component of the Swift client SDK for IBM Bluemix Mobile Services'
  s.homepage     = 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core'
  s.license      = 'Apache License, Version 2.0'
  s.authors      = { 'IBM Bluemix Services Mobile SDK' => 'mobilsdk@us.ibm.com' }
  s.source       = { :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :tag => s.version }

  s.source_files = 'Source/**/*.swift'
  s.ios.source_files = 'Source/Resources/iOS.modulemap', 'Source/Resources/BMSCore.h'
  s.watchos.source_files = 'Source/Resources/watchOS.modulemap', 'Source/Resources/BMSCoreWatchOS.h'

  s.ios.exclude_files = 'Source/**/*watchOS*.swift'
  s.watchos.exclude_files = 'Source/**/*iOS*.swift'

  s.ios.module_map = 'Source/Resources/iOS.modulemap'
  s.watchos.module_map = 'Source/Resources/watchOS.modulemap'

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'

  s.dependency 'BMSAnalyticsAPI', '0.0.20'

  s.requires_arc = true

end
