//
//  TCConstants.h
//  TCLVBIMDemo
//
//  Created by realingzhou on 16/8/22.
//  Copyright © 2016年 tencent. All rights reserved.
//

#ifndef TCConstants_h
#define TCConstants_h

// Global scheduling server address, domestic
#define kGlobalDispatchServiceHost @""
#define kApaasAppID @""
// Global scheduling server address, international
#define kGlobalDispatchServiceHost_international @""
#define kApaasAppID_international @""
// Global scheduling service
#define kGlobalDispatchServicePath @""

// Development and testing environment
#define kEnvDev @"/dev"
// Production Environment
#define kEnvProd @"/prod"


#define kGetSmsVerfifyCodePath @""

#define kLoginByPhonePath @""
// token
#define kLoginByTokenPath @""

#define kLogoutPath @""

#define kDeleteUserPath @""


// Http
#define kHttpServerAddr @""

//Elk
#define DEFAULT_ELK_HOST @""

//Licence url
#define LicenceURL @""

//Licence key
#define LicenceKey @""

//APNS
#define kAPNSBusiId 0
#define kTIMPushAppGorupKey @"" 

//tpns
#define kTPNSAccessID  0
#define kTPNSAccessKey @""
//tpns domain
#define kTPNSDomain  @""
//**********************************************************************

#define kHttpTimeout                         30

#define kError_InvalidParam                            -10001
#define kError_ConvertJsonFailed                       -10002
#define kError_HttpError                               -10003

#define kError_GroupNotExist                            10010
#define kError_HasBeenGroupMember                       10013


#define  kErrorMsgNetDisconnected  @"No network connection"

#define kVersion  4
#endif /* TCConstants_h */
