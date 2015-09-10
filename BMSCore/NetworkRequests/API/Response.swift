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


public class Response: CustomStringConvertible {
    
    
    // MARK: Properties (public)
    
    public var description: String {
        return ""
    }
    
    /**
     *  HTTP status of the response. Returns "0" for no response.
     */
    public var status: String {
        return ""
    }
    
    /**
     *  Dictionary with all the headers and the corresponding values for each one.
     */
    public var responseHeaders: [String: String] {
        return [:]
    }
    
    /**
     *  The body of the response as a String. Returns nil if there is no body or exception occurred when building the response string.
     */
    public var responseText: String {
        return ""
    }
    
    /**
     *  The body of the response as a JSONObject. Returns nil if there is no body or if it is not a valid JSONObject.
     */
    public var responseJSON: [String: AnyObject] {
        return [:]
    }
    
    /**
     *  The body of the response as a byte array. Returns nil if there is no body.
     */
    public var responseBytes: [UInt8] {
        return [UInt8]()
    }
    
    /** 
     *  True if this response redirects to another resource.
     */
    public var isRedirect: Bool {
        return false
    }
    
    /**
     *  True if the code is in [200..300), which means the request was
     *  successfully received, understood, and accepted.
     */
    public var isSuccessful: Bool {
        return false
    }
    
    /**
     *  The error code for the cause of the failure.
     */
    public var errorCode: ErrorCode?
    
    
    
    // MARK: Properties (internal/private)
    
    private var alamoFireResponse: NSHTTPURLResponse
    private var headers: [String: String]


    
    // MARK: Initializer
    
    // TODO: Add AlamoFire response parameter
    init(response: NSHTTPURLResponse, error: ErrorCode?) {
        alamoFireResponse = response
        headers = [:]
        
        errorCode = error
    }
    
}



/**
 *  Error codes explaining why the request failed.
 */

// TODO: Add more errors as needed
public enum ErrorCode {
    
    /**
     *  The client failed to connect to the server. Possible reasons include connection timeout,
     *  DNS failures, secure connection problems, etc.
     */
    case UNABLE_TO_CONNECT
    
    /**
     *  The server responded with a failure code.
     */
    case SERVER_ERROR
    
}
