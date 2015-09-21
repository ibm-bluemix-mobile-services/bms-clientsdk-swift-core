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


/**
 * ResponseListener is the interface that will be called after the ResourceRequest has completed or failed.
 */

internal protocol ResponseDelegate {
    
    /**
     *  This method will be called only when a response from the server has been received with an http status
     *  in the 200 range.
     *
     *  @param response The server response
     */
    func onSuccess (response: Response)
    
    /**
     *  This method will be called either when there is no response from the server or when the status
     *  from the server response is in the 400 or 500 ranges. The FailResponse contains an error code
     *  distinguishing between the different cases.
     *
     *  @param response Contains detail regarding why the request failed
     *  @param error Error that could have caused the request to fail. Null if no error is thrown.
     */
    func onFailure (response: Response, error: ErrorType)
    
}
