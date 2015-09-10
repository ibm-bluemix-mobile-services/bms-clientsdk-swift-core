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


// TODO: Combine with BMSRequest into class called BMSResourceRequest

public class ResourceRequest: BMSRequest {
    
    
    // MARK: Properties (public)
    
    override public var callBack: AnyObject {
        return ""
    }
    
    
    
    // MARK: Initializers
    
    /**
    *  Constructs a new resource request with the specified URL, using the specified HTTP method.
    *  Additionally this constructor sets a custom timeout.
    *
    *  @param url     The resource URL
    *  @param method  The HTTP method to use.
    *  @param timeout The timeout in milliseconds for this request.
    *  @throws IllegalArgumentException if the method name is not one of the valid HTTP method names.
    *  @throws MalformedURLException    if the URL is not a valid URL
    */
    // TODO: throws
    override init(url: String, method: String, timeout: Int = BMSRequest.DEFAULT_TIMEOUT) {
        super.init(url: url, method: method, timeout: timeout)
    }
    
    
    
    // MARK: Methods (internal/private)
    
    override func sendRequestWithRequestBody(requestBody: String, delegate: ResponseDelegate) {
        
    }
    
}
