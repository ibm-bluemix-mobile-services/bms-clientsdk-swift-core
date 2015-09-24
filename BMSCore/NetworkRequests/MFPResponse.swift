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


public struct MFPResponse: Response {
    
    
    
    // MARK: Properties (public)
    
    public let statusCode: Int?
    
    public let headers: [NSObject: AnyObject]?
    
    public let responseText: String?
    
    public let responseData: NSData?
    
    public let responseJSON: AnyObject?
    
    
    
    // MARK: Properties (internal/private)
    
    let httpResponse: NSHTTPURLResponse?
    
    let isSuccessful: Bool?
    
    let isRedirect: Bool
    
    
    
    // MARK: Initializer
    
    init(responseData: NSData?, httpResponse: NSHTTPURLResponse?, isRedirect: Bool) {
        
        self.isRedirect = isRedirect
        self.httpResponse = httpResponse
        self.headers = httpResponse?.allHeaderFields
        self.statusCode = httpResponse?.statusCode
        
        if let responseData = responseData {
            self.responseData = responseData
            self.responseText = String(NSString(data: responseData, encoding: NSUTF8StringEncoding))
            
            do {
                self.responseJSON = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers)
            }
            catch {
                self.responseJSON = nil
                // Log a warning/error
            }
        }
        else {
            self.responseData = nil
            self.responseText = nil
            self.responseJSON = nil
        }
        
        if let status = statusCode {
            isSuccessful = (200..<300 ~= status)
        }
        else {
            isSuccessful = false
        }
    }
    
}
