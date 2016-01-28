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


// TODO: Put these constants in their relevant files and remove this file

internal let MFP_PACKAGE_PREFIX = "mfpsdk."
internal let MFP_LOGGER_PACKAGE = MFP_PACKAGE_PREFIX + "logger"
internal let MFP_ANALYTICS_PACKAGE = MFP_PACKAGE_PREFIX + "analytics"
internal let MFP_REQUEST_PACKAGE = MFP_PACKAGE_PREFIX + "request"

internal let MFP_CORE_ERROR_DOMAIN = "com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore"

internal let FILE_LOGGER_LOGS = MFP_LOGGER_PACKAGE + ".log"
internal let FILE_LOGGER_SEND = MFP_LOGGER_PACKAGE + ".log.send"
internal let FILE_LOGGER_OVERFLOW = MFP_LOGGER_PACKAGE + ".log.overflow"

internal let FILE_ANALYTICS_LOGS = MFP_ANALYTICS_PACKAGE + ".log"
internal let FILE_ANALYTICS_SEND = MFP_ANALYTICS_PACKAGE + ".log.send"
internal let FILE_ANALYTICS_OVERFLOW = MFP_ANALYTICS_PACKAGE + ".log.overflow"

internal let KEY_METADATA_CATEGORY = "$category"
internal let KEY_METADATA_DURATION = "$duration"
internal let KEY_METADATA_CLOSEDBY = "$closedBy"
internal let KEY_METADATA_SESSIONID = "$appSessionID"

internal let TAG_CATEGORY_APP_SESSION = "appSession"
internal let TAG_MSG = "msg"
internal let TAG_PKG = "pkg"
internal let TAG_TIMESTAMP = "timestamp"
internal let TAG_LEVEL = "level"
internal let TAG_META_DATA = "metadata"
internal let TAG_UNCAUGHT_EXCEPTION = "loggerUncaughtExceptionDetected"
internal let TAG_LOG_LEVEL = "loggerLevel"
internal let TAG_MAX_STORE_SIZE = "loggerMaxFileSize"

internal let DEFAULT_MAX_STORE_SIZE: UInt64 = 100000
internal let DEFAULT_LOW_BOUND_FILE_SIZE = 10000

internal let HOST_NAME = "mobile-analytics-dashboard"
internal let UPLOAD_PATH = "/analytics-service/data/events/clientlogs/"

internal let CONTENT_TYPE = "Content-Type"
internal let TEXT_PLAIN_TYPE = "text/plain"

internal let API_ID_HEADER = "x-mfp-analytics-api-key"

public let REGION_US_SOUTH = ".ng.bluemix.net"
public let REGION_UK = ".eu-gb.bluemix.net"
public let REGION_SYDNEY = ".au-syd.bluemix.net"




