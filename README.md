IBM Bluemix Mobile Services - Client SDK Swift Core
===================================================

This is the core component of the Swift SDK for IBM Bluemix Mobile Services. 

https://console.ng.bluemix.net/solutions/mobilefirst


## Contents
This package contains the core components of the Swift SDK.
* HTTP Infrastructure
* Security and Authentication
* Logger


## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7


## Installation
The Bluemix Mobile Services Swift SDK is available via [Cocoapods](http://cocoapods.org/). 
To install, add the `BMSCore` pod to your `Podfile`.

##### iOS
```ruby
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSCore'
end
```

##### watchOS
```ruby
use_frameworks!

target 'MyApp WatchKit Extension' do
    platform :watchos, '2.0'
    pod 'BMSCore'
end
```

To enable Logger to print logs to the Xcode console, add the following post-install hook to your Podfile:

```ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name.include? 'BMSCore'
            target.build_configurations.each do |config|
                if config.name == 'Debug'
                    config.build_settings['OTHER_SWIFT_FLAGS'] = '-DDEBUG'
                else
                    config.build_settings['OTHER_SWIFT_FLAGS'] = ''
                end
            end
        end
    end
end
```


=======================
Copyright 2015 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
