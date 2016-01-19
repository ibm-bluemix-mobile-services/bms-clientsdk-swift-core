IBM Bluemix Mobile Services - Client SDK Swift Core
===================================================

This is the core component of the Swift SDK for IBM Bluemix Mobile Services. 

https://console.ng.bluemix.net/solutions/mobilefirst


## Contents
This package contains the core components of the Swift SDK.
* HTTP Infrastructure
* Security and Authentication
* Logger
* Analytics


## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7


## Installation
The Bluemix Mobile Services Swift SDK is available via [Cocoapods](http://cocoapods.org/). 
To install, add the `BMSCore` pod to your `Podfile`.

##### iOS
```ruby
use_frameworks!

target 'My iOS App' do
    platform :ios, '8.0'
    pod 'BMSCore'
end
```

##### watchOS
```ruby
use_frameworks!

target 'My watchOS App WatchKit App' do
    platform :ios, '8.0'
    pod 'BMSCore'
end

target 'My watchOS App WatchKit Extension' do
    platform :watchos, '2.0'
    pod 'BMSCore'
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
