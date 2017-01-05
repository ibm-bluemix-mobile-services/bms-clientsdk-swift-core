/*
*     Copyright 2017 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/


import SystemConfiguration
import CoreTelephony



// MARK: - Swift 3

#if swift(>=3.0)
    
    

public enum NetworkConnection {
    
    case noConnection
    case WiFi
    case WWAN
    
    public var description: String {
        
        switch self {
            
        case .noConnection:
            return "No Connection"
        case .WiFi:
            return "WiFi"
        case .WWAN:
            return "WWAN"
        }
    }
}



public class NetworkDetection {
    
    
    // MARK: API
    
    /// When using the `startMonitoringNetworkChanges()` method, register an observer with `NotificationCenter` using this `Notification.Name`.
    public static let networkChangedNotificationName = Notification.Name("NetworkChangedNotification")
    
    
    /// The type of cellular data network available to the iOS device.
    /// The possible values are `4G`, `3G`, `2G`, and `unknown`.
    public var cellularNetworkType: String? {
        
        guard let radioAccessTechnology = CTTelephonyNetworkInfo().currentRadioAccessTechnology else {
            return nil
        }
        
        switch radioAccessTechnology {
            
        case CTRadioAccessTechnologyLTE:
            return "4G"
        case CTRadioAccessTechnologyeHRPD,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB:
            return "3G"
        case CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyCDMA1x:
            return "2G"
        default:
            return "unknown"
        }
    }
    
    
    /// Detects whether the iOS device is currently connected to the internet via WiFi or WWAN.
    public var currentNetworkConnection: NetworkConnection {
        
        if !reachabilityFlags.contains(.reachable) {
            return .noConnection
        }
        else if reachabilityFlags.contains(.isWWAN) {
            return .WWAN
        }
        else if !reachabilityFlags.contains(.connectionRequired) {
            // If the target host is reachable and no connection is required then it's assumed that the device is has WiFi access
            return .WiFi
        }
        else if (reachabilityFlags.contains(.connectionOnDemand) || reachabilityFlags.contains(.connectionOnTraffic)) && !reachabilityFlags.contains(.interventionRequired) {
            // If the connection is on-demand or on-traffic and no user intervention is needed, then WiFi must be available
            return .WiFi
        } 
        else {
            return .noConnection
        }
    }
    
    
    /// Creates a new instance of `NetworkDetection` only if the current device's network can be accessed.
    public init?() {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        networkReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        })
        
        if networkReachability == nil {
            return nil
        }
    }
    
    
    /**
        Begins monitoring changes in the `currentNetworkConnection`.
        
        If the device's connection to the internet changes (WiFi, WWAN, or no connection), a notification will be posted to `NotificationCenter.default` with `NetworkDetection.networkChangedNotificationName`. 
     
        To intercept network changes, add an observer to `NotificationCenter.default` with `NetworkDetection.networkChangedNotificationName` as the `Notification.Name`.
    */
    public func startMonitoringNetworkChanges() -> Bool {
        
        guard !isMonitoringNetworkChanges else {
            return false
        }
        
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let reachability = networkReachability, SCNetworkReachabilitySetCallback(reachability, { (target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
    
            if let currentInfo = info {
                let infoObject = Unmanaged<AnyObject>.fromOpaque(currentInfo).takeUnretainedValue()
                if infoObject is NetworkDetection {
                    let networkReachability = infoObject as! NetworkDetection
                    NotificationCenter.default.post(name: NetworkDetection.networkChangedNotificationName, object: networkReachability)
                }
            }
        }, &context) == true else {
            
            return false
        }
        
        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) == true else {
            return false
        }
        
        isMonitoringNetworkChanges = true
        return isMonitoringNetworkChanges
    }
    
    
    /**
        Stops monitoring changes in the `currentNetworkConnection` that were started by `startMonitoringNetworkChanges()`.
     */
    public func stopMonitoringNetworkChanges() {
        if let reachability = networkReachability, isMonitoringNetworkChanges == true {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            isMonitoringNetworkChanges = false
        }
    }
    
    
    
    // MARK: Internal
    
    internal var isMonitoringNetworkChanges: Bool = false
    
    
    // This is used in `reachabilityFlags` to determine details about the current internet connection.
    private var networkReachability: SCNetworkReachability?
    
    
    // Contains information about the reachability of a certain network node.
    private var reachabilityFlags: SCNetworkReachabilityFlags {
        
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        
        if let reachability = networkReachability, withUnsafeMutablePointer(to: &flags, { SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0)) }) == true {
            
            return flags
        }
        else {
            return []
        }
    }
    
    
    deinit {
        
        stopMonitoringNetworkChanges()
    }
    
}





/**************************************************************************************************/





// MARK: - Swift 2

#else



public enum NetworkConnection {
    
    case noConnection
    case WiFi
    case WWAN
    
    public var description: String {
        
        switch self {
            
        case .noConnection:
            return "No Connection"
        case .WiFi:
            return "WiFi"
        case .WWAN:
            return "WWAN"
        }
    }
}



public class NetworkDetection {
    
    
    // MARK: API
    
    /// When using the `startMonitoringNetworkChanges()` method, register an observer with `NSNotificationCenter` using this //// TODO
    public static let networkChangedNotificationName = "NetworkChangedNotification"
    
    
    /// The type of cellular data network available to the iOS device.
    /// The possible values are `4G`, `3G`, `2G`, and `unknown`.
    public var cellularNetworkType: String? {
        
        guard let radioAccessTechnology = CTTelephonyNetworkInfo().currentRadioAccessTechnology else {
            return nil
        }
        
        switch radioAccessTechnology {
            
        case CTRadioAccessTechnologyLTE:
            return "4G"
        case CTRadioAccessTechnologyeHRPD,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB:
            return "3G"
        case CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyCDMA1x:
            return "2G"
        default:
            return "unknown"
        }
    }
    
    
    /// Detects whether the iOS device is currently connected to the internet via WiFi or WWAN.
    public var currentNetworkConnection: NetworkConnection {
        
        if !reachabilityFlags.contains(.Reachable) {
            return .noConnection
        }
        else if reachabilityFlags.contains(.IsWWAN) {
            return .WWAN
        }
        else if !reachabilityFlags.contains(.ConnectionRequired) {
            // If the target host is reachable and no connection is required then it's assumed that the device is has WiFi access
            return .WiFi
        }
        else if (reachabilityFlags.contains(.ConnectionOnDemand) || reachabilityFlags.contains(.ConnectionOnTraffic)) && !reachabilityFlags.contains(.InterventionRequired) {
            // If the connection is on-demand or on-traffic and no user intervention is needed, then WiFi must be available
            return .WiFi
        }
        else {
            return .noConnection
        }
    }
    
    
    /// Creates a new instance of `NetworkDetection` only if the current device's network can be accessed.
    public init?() {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        networkReachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        })
        
        if networkReachability == nil {
            return nil
        }
    }
    
    
    /**
        Begins monitoring changes in the `currentNetworkConnection`.

        If the device's connection to the internet changes (WiFi, WWAN, or no connection), a notification will be posted to `NotificationCenter.default` with `NetworkDetection.networkChangedNotificationName`.

        To intercept network changes, add an observer to `NotificationCenter.default` with `NetworkDetection.networkChangedNotificationName` as the `Notification.Name`.
     */
    public func startMonitoringNetworkChanges() -> Bool {
        
        guard !isMonitoringNetworkChanges else {
            return false
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let reachability = networkReachability
            where SCNetworkReachabilitySetCallback(reachability, { (target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>) in
        
            let infoObject = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()
            if infoObject is NetworkDetection {
                let networkReachability = infoObject as! NetworkDetection
                NSNotificationCenter.defaultCenter().postNotificationName(NetworkDetection.networkChangedNotificationName, object: networkReachability)
            }
        }, &context) == true else {
        
            return false
        }
    
        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode) == true else {
            return false
        }
        
        isMonitoringNetworkChanges = true
        return isMonitoringNetworkChanges
    }
    
    
    /**
        Stops monitoring changes in the `currentNetworkConnection` that were started by `startMonitoringNetworkChanges()`.
     */
    public func stopMonitoringNetworkChanges() {
        if let reachability = networkReachability where isMonitoringNetworkChanges == true {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
            isMonitoringNetworkChanges = false
        }
    }
    
    
    
    // MARK: Internal
    
    internal var isMonitoringNetworkChanges: Bool = false
    
    
    // This is used in `reachabilityFlags` to determine details about the current internet connection.
    private var networkReachability: SCNetworkReachability?
    
    
    // Contains information about the reachability of a certain network node.
    private var reachabilityFlags: SCNetworkReachabilityFlags {
        
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        
        if let reachability = networkReachability where withUnsafeMutablePointer(&flags, { SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0)) }) == true {
            
            return flags
        }
        else {
            return []
        }
    }
    
    
    deinit {
        
        stopMonitoringNetworkChanges()
    }
    
}



#endif
