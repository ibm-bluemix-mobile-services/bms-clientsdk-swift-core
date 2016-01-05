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

//  Created by Ilan Klein on 12/24/2015.

public enum PersistencePolicy: String {
    case NEVER = "NEVER"
    case ALWAYS = "ALWAYS"
}

public protocol AuthorizationManager {
    func isAuthorizationRequired(statusCode: Int, responseAuthorizationHeader: String) -> Bool
    func isAuthorizationRequired(httpResponse: NSHTTPURLResponse) -> Bool
    func isOAuthError(response: Response?) -> Bool
    func clearAuthorizationData()
    func addCachedAuthorizationHeader(request: NSMutableURLRequest)
    func getCachedAuthorizationHeader() -> String?
    func obtainAuthorizationHeader(completionHandler: MfpCompletionHandler?)
    func getUserIdentity() -> AnyObject?
    func getDeviceIdentity() -> AnyObject?
    func getAppIdentity() -> AnyObject?
    func getAuthorizationPersistencePolicy() -> PersistencePolicy
    func setAuthorizationPersistensePolicy(policy: PersistencePolicy)
}