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


public protocol Response {
    
    /**
     *  HTTP status of the response. Returns "0" for no response.
     */
    var statusCode: Int? { get }
    
    /**
    *  HTTP headers from the response.
    */
    var headers: [NSObject: AnyObject]? { get }
    
    /**
     *  The body of the response as a String. Returns nil if there is no body or exception occurred when building the response string.
     */
    var responseText: String? { get }
    
    /**
     *  The body of the response as NSData. Returns nil if there is no body or if it is not valid NSData.
     */
    var responseData: NSData? { get }
    
}
