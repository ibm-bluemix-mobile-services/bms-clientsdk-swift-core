/*
*     Copyright 2015 IBM Corp.
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

import Foundation


internal protocol MFPClient {

    
    /**
     *  Specifies default request timeout.
     */
    var defaultRequestTimeout: Double { get set }
    
    /**
     *  Registers a delegate that will handle authentication for the specified realm
     *
     *  @param delegate The delegate that will handle authentication challenges
     *  @param forRealm The realm name
     */
    func registerAuthenticationDelegate(delegate: Any, realm: String)
    
    /**
     *  Unregisters an authentication delegate for the specified realm
     *
     *  @param realm Realm name
     */
    func unregisterAuthenticationDelegate(realm: String)
    
}


internal extension MFPClient {
    
    func registerAuthenticationDelegate(delegate: Any, realm: String) {
        // Default implementation goes here!
    }
    
    func unregisterAuthenticationDelegate(realm: String) {
        // Default implementation goes here!
    }
    
}
