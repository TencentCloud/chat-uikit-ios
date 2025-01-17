//
//  TCommonPendencyCellData.h
//  TXIMSDK_TUIKit_iOS
//
//  Created by annidyfeng on 2019/5/7.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import <TIMCommon/TIMCommonModel.h>
@class V2TIMFriendApplication;

NS_ASSUME_NONNULL_BEGIN

@interface TUICommonPendencyCellData : TUICommonCellData
@property V2TIMFriendApplication *application;
@property NSString *identifier;
@property NSURL *avatarUrl;
@property NSString *title;
@property NSString *addSource;
@property NSString *addWording;
@property BOOL isAccepted;
@property BOOL isRejected;
@property SEL cbuttonSelector;
@property SEL cRejectButtonSelector;

@property BOOL hideSource;

- (instancetype)initWithPendency:(V2TIMFriendApplication *)application;

typedef void (^TUICommonPendencyCellDataSuccessCallback)(void);
typedef void (^TUICommonPendencyCellDataFailureCallback)(int code, NSString *msg);

- (void)agreeWithSuccess:(TUICommonPendencyCellDataSuccessCallback)success
                 failure:(TUICommonPendencyCellDataFailureCallback)failure;

- (void)rejectWithSuccess:(TUICommonPendencyCellDataSuccessCallback)success
                  failure:(TUICommonPendencyCellDataFailureCallback)failure;


- (void)agree;
- (void)reject;

@end

NS_ASSUME_NONNULL_END
