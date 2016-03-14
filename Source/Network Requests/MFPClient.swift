/*
*     Copyright 2016 IBM Corp.
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


/**
    A singleton that serves as an entry point to MobileFirst Platform Foundation client-server communication.
*/
public class MFPClient: BaseClient {
    
    
    // MARK: Properties (public)
    
    /// This singleton should be used for all `MFPClient` activity
    public static let sharedInstance = MFPClient()
    
    /// Specifies the protocol for connecting with the MFP server
    public private(set) var mfpProtocol: String?
    
    /// Specifies the host name of the MFP server
    public private(set) var mfpHost: String?
    
    /// Specifies the port for connecting with the MFP server
    public private(set) var mfpPort: String?
    
    /// Specifies the default timeout (in seconds) for all MFP network requests.
    public var defaultRequestTimeout: Double = 20.0
    
    // Device metadata to be sent with every BMSCore network request
    // This should only be set by the MFP Foundation SDK
    public var deviceMetadata: String?
    
    
    
    // MARK: Initializers
    
    /**
        The required intializer for the `MFPClient` class.
        
        Sets the base URL for the MFP server.
        
        - parameter mfpProtocol:    The protocol for connecting with the MFP server.
        - parameter mfpHost:        The host name of the MFP server.
        - parameter mfpPort:        The port for the MPF server.
    */
    public func initializeWithUrlComponents(mfpProtocol mfpProtocol: String, mfpHost: String, mfpPort: String) {
        
        self.mfpHost = mfpHost
        self.mfpProtocol = mfpProtocol.stringByReplacingOccurrencesOfString("://", withString: "")
        self.mfpPort = mfpPort.stringByReplacingOccurrencesOfString(":", withString: "")
    }
    
    private init() {} // Prevent users from using MFPClient() initializer - They must use MFPClient.sharedInstance
    
}
