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



// MARK: - Swift 3

#if swift(>=3.0)
    


/**
    Sends HTTP network requests. It is recommended to use this class instead of `BaseRequest`.

    For more information on `Request`, see the documentation for `BaseRequest`.
*/
open class Request: BaseRequest {
    
    // TODO: Deprecate BaseRequest in favor of Request 
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
/**
    Sends HTTP network requests. It is recommended to use this class instead of `BaseRequest`.

    When building a Request object, all components of the HTTP request must be provided in the initializer, except for the `requestBody`, which can be supplied as Data when sending the request via `send(requestBody:completionHandler:)`.

    For more information on `Request`, see the documentation for `BaseRequest`.
*/
public class Request: BaseRequest {
    
    // TODO: Deprecate BaseRequest in favor of Request
}



#endif
