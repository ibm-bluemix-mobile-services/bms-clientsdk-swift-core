IBM Bluemix Mobile Services - Client SDK Swift Core (BMSCore)
===================================================

[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)
[![Platform](https://img.shields.io/cocoapods/p/BMSCore.svg?style=flat)](http://cocoadocs.org/docsets/BMSCore)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BMSCore.svg)](https://img.shields.io/cocoapods/v/BMSCore.svg)
[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.svg?branch=master)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core)

This is the core component of the Swift SDKs for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/mobile/index.html).



## Table of Contents
* [Summary](#summary)
* [Requirements](#requirements)
* [Installation](#installation)
* [Example Usage](#example-usage)
* [License](#license)


## Summary

BMSCore provides the HTTP infrastructure that the other Bluemix Mobile Services (BMS) client SDKs use to communicate with their respective Bluemix services. These other SDKs include [BMSAnalytics](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics), [BMSPush](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-push), [BMSSecurity](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-security), and [BluemixObjectStorage](https://github.com/ibm-bluemix-mobile-services/bluemix-objectstorage-clientsdk-swift). 

You can also use this SDK to make network requests to any resource using `BMSURLSession`. This API is a wrapper around the native Swift [URLSession](https://developer.apple.com/reference/foundation/urlsession) and currently supports data tasks and upload tasks. `BMSURLSession` becomes more powerful if you have other BMS SDKs installed in your app. With [BMSSecurity](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-security), you can make network requests to backends protected by Mobile Client Access. With [BMSAnalytics](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics), analytics data will automatically be gathered (if you opt in) for all requests made with `BMSURLSession`.



## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7.3, 8.0
* Swift 2.2 - 3.0



## Installation
The Bluemix Mobile Services Swift SDKs are available via [Cocoapods](http://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage).


### Cocoapods

To install BMSCore using Cocoapods, add it to your Podfile. If your project does not have a Podfile yet, use the `pod init` command.

```ruby
use_frameworks!

target 'MyApp' do
    pod 'BMSCore'
end
```

Then run the `pod install` command. To update to a newer release of BMSCore, use `pod update BMSCore`.

#### Xcode 8

Before running the `pod install` command, make sure you have installed Cocoapods [1.1.0](https://github.com/CocoaPods/CocoaPods/releases) or later. You can get the latest version of Cocoapods using the command `sudo gem install cocoapods`.

If you receive a prompt saying "Convert to Current Swift Syntax?" when opening your project in Xcode 8 (following the installation of BMSCore), **do not** convert BMSCore or BMSAnalyticsAPI.


### Carthage

To install BMSCore with Carthage, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).

Add this line to your Cartfile: 

```ogdl
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-core"
```

Then run the `carthage update` command. Once the build is finished, add `BMSCore.framework` and `BMSAnalyticsAPI.framework` to your project. 


#### Xcode 8

For apps built with Swift 2.3, use the command `carthage update --toolchain com.apple.dt.toolchain.Swift_2_3`. Otherwise, use `carthage update`.



## Example Usage

### Swift 3.0

```Swift
// Initialize BMSClient
BMSClient.sharedInstance.initialize(bluemixRegion: BMSClient.Region.usSouth)
                                
let logger = Logger.logger(name: "My Logger")

// Make a network request
let urlSession = BMSURLSession(configuration: .default, delegate: nil, delegateQueue: nil)
var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
request.httpMethod = "GET"
request.allHTTPHeaderFields = ["foo":"bar"]

urlSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
    if let httpResponse = response as? HTTPURLResponse {
        logger.info(message: "Status code: \(httpResponse.statusCode)")
    }
    if data != nil, let responseString = String(data: data!, encoding: .utf8) {
        logger.info(message: "Response data: \(responseString)")
    }
    if let error = error {
        logger.error(message: "Error: \(error)")
    }
}.resume()
```


### Swift 2.2

```Swift
// Initialize BMSClient
BMSClient.sharedInstance.initialize(bluemixRegion: BMSClient.Region.usSouth)
                                   
let logger = Logger.logger(name: "My Logger")

// Make a network request
let urlSession = BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)
let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/get")!)
request.HTTPMethod = "GET"
request.allHTTPHeaderFields = ["foo":"bar"]

urlSession.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
    if let httpResponse = response as? NSHTTPURLResponse {
        logger.info(message: "Status code: \(httpResponse.statusCode)")
    }
    if data != nil, let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
        logger.info(message: "Response data: \(responseString)")
    }
    if let error = error {
        logger.error(message: "Error: \(error)")
    }
}.resume()
```


> By default the Bluemix Mobile Service SDK internal debug logging will not be printed to Xcode console. If you want to enable SDK debug logging output set the `Logger.isInternalDebugLoggingEnabled` property to `true`.



### Disabling Logging output for production applications

By default the Logger class will print its logs to Xcode console. If is advised to disable Logger output for applications built in release mode. In order to do so add a debug flag named `RELEASE_BUILD` to your release build configuration. One of the way of doing so is adding `-D RELEASE_BUILD` to `Other Swift Flags` section of the project build configuration.



## License
Copyright 2016 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
