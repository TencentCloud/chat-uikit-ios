
//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#import <TUICore/TUILogin.h>
#import <TIMCommon/TUISystemMessageCellData.h>
#import "TUIChatCallingDataProvider.h"
#import "TUICloudCustomDataTypeCenter.h"
#import "TUIFaceMessageCellData.h"
#import "TUIFileMessageCellData.h"
#import "TUIImageMessageCellData.h"
#import "TUIJoinGroupMessageCellData.h"
#import "TUIMergeMessageCellData.h"
#import "TUIMessageDataProvider+MessageDeal.h"
#import "TUIMessageDataProvider.h"
#import "TUIMessageProgressManager.h"
#import "TUIReplyMessageCellData.h"
#import "TUITextMessageCellData.h"
#import "TUIVideoMessageCellData.h"
#import "TUIVoiceMessageCellData.h"

/**
 * 消息撤回后最大可编辑时间 , default is (2 * 60)
 * The maximum editable time after the message is recalled, default is (2 * 60)
 */
#define MaxReEditMessageDelay 2 * 60

#define kIsCustomMessageFromPlugin @"kIsCustomMessageFromPlugin"

static Class<TUIMessageDataProviderDataSource> gDataSourceClass = nil;

@implementation TUIMessageDataProvider

#pragma mark - Life cycle

- (void)dealloc {
    gCallingDataProvider = nil;
}

+ (void)setDataSourceClass:(Class<TUIMessageDataProviderDataSource>)dataSourceClass {
    gDataSourceClass = dataSourceClass;
}

#pragma mark - TUIMessageCellData parser
+ (nullable TUIMessageCellData *)getCellData:(V2TIMMessage *)message {
    // 1 Parse cell data
    TUIMessageCellData *data = [self parseMessageCellDataFromMessageStatus:message];
    if (data == nil) {
        data = [self parseMessageCellDataFromMessageCustomData:message];
    }
    if (data == nil) {
        data = [self parseMessageCellDataFromMessageElement:message];
    }

    // 2 Fill in property if needed
    if (data) {
        [self fillPropertyToCellData:data ofMessage:message];
    } else {
        NSLog(@"current message will be ignored in chat page, msg:%@", message);
    }
    
    return data;
}

+ (nullable TUIMessageCellData *)parseMessageCellDataFromMessageStatus:(V2TIMMessage *)message {
    TUIMessageCellData *data = nil;
    if (message.status == V2TIM_MSG_STATUS_LOCAL_REVOKED) {
        data = [TUIMessageDataProvider getRevokeCellData:message];
    }
    return data;
}

+ (nullable TUIMessageCellData *)parseMessageCellDataFromMessageCustomData:(V2TIMMessage *)message {
    TUIMessageCellData *data = nil;
    if ([message isContainsCloudCustomOfDataType:TUICloudCustomDataType_MessageReply]) {
        /**
         * 判断是否包含「回复消息」
         * Determine whether to include "reply-message"
         */
        data = [TUIReplyMessageCellData getCellData:message];
    } else if ([message isContainsCloudCustomOfDataType:TUICloudCustomDataType_MessageReference]) {
        /**
         * 判断是否包含「引用消息」
         * Determine whether to include "quote-message"
         */
        data = [TUIReferenceMessageCellData getCellData:message];
    }
    return data;
}

+ (nullable TUIMessageCellData *)parseMessageCellDataFromMessageElement:(V2TIMMessage *)message {
    TUIMessageCellData *data = nil;
    switch (message.elemType) {
        case V2TIM_ELEM_TYPE_TEXT: {
            data = [TUITextMessageCellData getCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_IMAGE: {
            data = [TUIImageMessageCellData getCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_SOUND: {
            data = [TUIVoiceMessageCellData getCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_VIDEO: {
            data = [TUIVideoMessageCellData getCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_FILE: {
            data = [TUIFileMessageCellData getCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_FACE: {
            data = [TUIFaceMessageCellData getCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_GROUP_TIPS: {
            data = [self getSystemCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_MERGER: {
            data = [TUIMergeMessageCellData getCellData:message];
        } break;
        case V2TIM_ELEM_TYPE_CUSTOM: {
            data = [self getCustomMessageCellData:message];
        } break;
        default:
            data = [self getUnsupportedCellData:message];
            break;
    }
    return data;
}

+ (void)fillPropertyToCellData:(TUIMessageCellData *)data ofMessage:(V2TIMMessage *)message {
    data.innerMessage = message;
    data.msgID = message.msgID;
    data.identifier = message.sender;
    data.name = [TUIMessageDataProvider getShowName:message];
    data.avatarUrl = [NSURL URLWithString:message.faceURL];
    if (message.groupID.length > 0 && !message.isSelf && ![data isKindOfClass:[TUISystemMessageCellData class]]) {
        data.showName = YES;
    }
    switch (message.status) {
        case V2TIM_MSG_STATUS_SEND_SUCC:
            data.status = Msg_Status_Succ;
            break;
        case V2TIM_MSG_STATUS_SEND_FAIL:
            data.status = Msg_Status_Fail;
            break;
        case V2TIM_MSG_STATUS_SENDING:
            data.status = Msg_Status_Sending_2;
            break;
        default:
            break;
    }

    /**
     * 更新消息的上传/下载进度
     * Update progress of message uploading/downloading
     */
    {
        NSInteger uploadProgress = [TUIMessageProgressManager.shareManager uploadProgressForMessage:message.msgID];
        NSInteger downloadProgress = [TUIMessageProgressManager.shareManager downloadProgressForMessage:message.msgID];
        if ([data conformsToProtocol:@protocol(TUIMessageCellDataFileUploadProtocol)]) {
            ((id<TUIMessageCellDataFileUploadProtocol>)data).uploadProgress = uploadProgress;
        }
        if ([data conformsToProtocol:@protocol(TUIMessageCellDataFileDownloadProtocol)]) {
            ((id<TUIMessageCellDataFileDownloadProtocol>)data).downladProgress = downloadProgress;
            ((id<TUIMessageCellDataFileDownloadProtocol>)data).isDownloading = (downloadProgress != 0) && (downloadProgress != 100);
        }
    }


    /**
     * 判断是否包含「消息回复数」
     * Determine whether to include "replies-message"
     */
    if ([message isContainsCloudCustomOfDataType:TUICloudCustomDataType_MessageReplies]) {
        [message doThingsInContainsCloudCustomOfDataType:TUICloudCustomDataType_MessageReplies
                                                callback:^(BOOL isContains, id obj) {
                                                  if (isContains) {
                                                      if ([data isKindOfClass:TUISystemMessageCellData.class] ||
                                                          [data isKindOfClass:TUIJoinGroupMessageCellData.class]) {
                                                          data.showMessageModifyReplies = NO;
                                                      } else {
                                                          data.showMessageModifyReplies = YES;
                                                      }
                                                      if (obj && [obj isKindOfClass:NSDictionary.class]) {
                                                          NSDictionary *dic = (NSDictionary *)obj;
                                                          NSString *typeStr =
                                                              [TUICloudCustomDataTypeCenter convertType2String:TUICloudCustomDataType_MessageReplies];
                                                          NSDictionary *messageReplies = [dic valueForKey:typeStr];
                                                          NSArray *repliesArr = [messageReplies valueForKey:@"replies"];
                                                          if ([repliesArr isKindOfClass:NSArray.class]) {
                                                              data.messageModifyReplies = repliesArr.copy;
                                                          }
                                                      }
                                                  }
                                                }];
    }
}

+ (nullable TUIMessageCellData *)getCustomMessageCellData:(V2TIMMessage *)message {
    // ************************************************************************************
    // ************************************************************************************
    // ************** TUICallKit 的兼容处理逻辑，待 TUICallKit 按照标准流程接入后移除 *************
    // ************************************************************************************
    // ************************************************************************************
    TUIMessageCellData *data = nil;
    id<TUIChatCallingInfoProtocol> callingInfo = nil;
    if ([self.callingDataProvider isCallingMessage:message callingInfo:&callingInfo]) {
        // Voice-video-call message
        if (callingInfo) {
            // Supported voice-video-call message
            if (callingInfo.excludeFromHistory) {
                // This message will be ignore in chat page
                data = nil;
            } else {
                data = [self getCallingCellData:callingInfo];
                if (data == nil) {
                    data = [self getUnsupportedCellData:message];
                }
            }
        } else {
            // Unsupported voice-video-call message
            data = [self getUnsupportedCellData:message];
        }
        
        return data;
    }
    // ************************************************************************************
    // ************************************************************************************
    // ************************************************************************************
    // ************************************************************************************
    
    NSString *businessID = nil;
    BOOL excludeFromHistory = NO;
    
    V2TIMSignalingInfo *signalingInfo = [V2TIMManager.sharedInstance getSignallingInfo:message];
    if (signalingInfo) {
        // This message is signaling message
        BOOL isOnlineOnly = NO;
        @try {
            isOnlineOnly = [[message valueForKeyPath:@"message.IsOnlineOnly"] boolValue];
        } @catch (NSException *exception) {
            isOnlineOnly = NO;
        }
        excludeFromHistory = isOnlineOnly || (message.isExcludedFromLastMessage && message.isExcludedFromUnreadCount);
        businessID = [self getSignalingBusinessID:signalingInfo];
    } else {
        // This message is normal custom message
        excludeFromHistory = NO;
        businessID = [self getCustomBusinessID:message];
    }
    
    if (excludeFromHistory) {
        // Return nil means not display in the chat page
        return nil;
    }

    if (businessID.length > 0) {
        Class cellDataClass = nil;
        if (gDataSourceClass && [gDataSourceClass respondsToSelector:@selector(onGetCustomMessageCellDataClass:)]) {
            cellDataClass = [gDataSourceClass onGetCustomMessageCellDataClass:businessID];
        }
        if (cellDataClass && [cellDataClass respondsToSelector:@selector(getCellData:)]) {
            TUIMessageCellData *data = [cellDataClass getCellData:message];
            if (data.shouldHide) {
                return nil;
            } else {
                data.reuseId = businessID;
                return data;
            }
        }
        // CustomerService、ChatBot 场景，不支持的消息直接不展示
        if ([businessID containsString:BussinessID_CustomerService] || [businessID containsString:BussinessID_ChatBot]) {
            return nil;
        }
        return [self getUnsupportedCellData:message];
    } else {
        return [self getUnsupportedCellData:message];
    }
}

+ (TUIMessageCellData *)getUnsupportedCellData:(V2TIMMessage *)message {
    TUITextMessageCellData *cellData = [[TUITextMessageCellData alloc] initWithDirection:(message.isSelf ? MsgDirectionOutgoing : MsgDirectionIncoming)];
    cellData.content = TIMCommonLocalizableString(TUIKitNotSupportThisMessage);
    cellData.reuseId = TTextMessageCell_ReuseId;
    return cellData;
}

+ (nullable TUISystemMessageCellData *)getSystemCellData:(V2TIMMessage *)message {
    V2TIMGroupTipsElem *tip = message.groupTipsElem;
    NSString *opUserName = [self getOpUserName:tip.opMember];
    NSMutableArray<NSString *> *userNameList = [self getUserNameList:tip.memberList];
    NSMutableArray<NSString *> *userIDList = [self getUserIDList:tip.memberList];
    if (tip.type == V2TIM_GROUP_TIPS_TYPE_JOIN || tip.type == V2TIM_GROUP_TIPS_TYPE_INVITE || tip.type == V2TIM_GROUP_TIPS_TYPE_KICKED ||
        tip.type == V2TIM_GROUP_TIPS_TYPE_GROUP_INFO_CHANGE || tip.type == V2TIM_GROUP_TIPS_TYPE_QUIT) {
        TUIJoinGroupMessageCellData *joinGroupData = [[TUIJoinGroupMessageCellData alloc] initWithDirection:MsgDirectionIncoming];
        joinGroupData.content = [self getDisplayString:message];
        joinGroupData.opUserName = opUserName;
        joinGroupData.opUserID = tip.opMember.userID;
        joinGroupData.userNameList = userNameList;
        joinGroupData.userIDList = userIDList;
        joinGroupData.reuseId = TJoinGroupMessageCell_ReuseId;
        return joinGroupData;
    } else {
        TUISystemMessageCellData *sysdata = [[TUISystemMessageCellData alloc] initWithDirection:MsgDirectionIncoming];
        sysdata.content = [self getDisplayString:message];
        sysdata.reuseId = TSystemMessageCell_ReuseId;
        if (sysdata.content.length) {
            return sysdata;
        }
    }
    return nil;
}

+ (nullable TUISystemMessageCellData *)getRevokeCellData:(V2TIMMessage *)message {
    TUISystemMessageCellData *revoke = [[TUISystemMessageCellData alloc] initWithDirection:(message.isSelf ? MsgDirectionOutgoing : MsgDirectionIncoming)];
    revoke.reuseId = TSystemMessageCell_ReuseId;
    revoke.content = [self getRevokeDispayString:message];
    revoke.innerMessage = message;
    V2TIMUserFullInfo *revokerInfo = message.revokerInfo;
    if (message.isSelf) {
        if (message.elemType == V2TIM_ELEM_TYPE_TEXT && fabs([[NSDate date] timeIntervalSinceDate:message.timestamp]) < MaxReEditMessageDelay) {
            if(revokerInfo &&![revokerInfo.userID isEqualToString:message.sender]) {
                //Super User revoke
                revoke.supportReEdit = NO;
            }
            else {
                revoke.supportReEdit = YES;
            }
        }
    } else if (message.groupID.length > 0) {
        /**
         * 对于群组消息的名称显示，优先显示群名片，昵称优先级其次，用户ID优先级最低。
         * For the name display of group messages, the group business card is displayed first, the nickname has the second priority, and the user ID has the
         * lowest priority.
         */
        NSString *userName = [TUIMessageDataProvider getShowName:message];
        TUIJoinGroupMessageCellData *joinGroupData = [[TUIJoinGroupMessageCellData alloc] initWithDirection:MsgDirectionIncoming];
        joinGroupData.content = [self getRevokeDispayString:message];
        joinGroupData.opUserID = message.sender;
        joinGroupData.opUserName = userName;
        joinGroupData.reuseId = TJoinGroupMessageCell_ReuseId;
        return joinGroupData;
    }
    return revoke;
}

+ (nullable TUISystemMessageCellData *)getSystemMsgFromDate:(NSDate *)date {
    TUISystemMessageCellData *system = [[TUISystemMessageCellData alloc] initWithDirection:MsgDirectionOutgoing];
    system.content = [TUITool convertDateToStr:date];
    system.reuseId = TSystemMessageCell_ReuseId;
    system.type = TUISystemMessageTypeDate;
    return system;
}

#pragma mark - Last message parser
+ (nullable NSString *)getDisplayString:(V2TIMMessage *)message {
    BOOL hasRiskContent = message.hasRiskContent;
    BOOL isRevoked = (message.status == V2TIM_MSG_STATUS_LOCAL_REVOKED);
    if (hasRiskContent && !isRevoked ) {
        return  TIMCommonLocalizableString(TUIKitMessageDisplayRiskContent);
    }
    NSString *str = [self parseDisplayStringFromMessageStatus:message];
    if (str == nil) {
        str = [self parseDisplayStringFromMessageElement:message];
    }
    
    if (str == nil) {
        NSLog(@"current message will be ignored in chat page or conversation list page, msg:%@", message);
    }
    return str;
}

+ (nullable NSString *)parseDisplayStringFromMessageStatus:(V2TIMMessage *)message {
    NSString *str = nil;
    if (message.status == V2TIM_MSG_STATUS_LOCAL_REVOKED) {
        str = [self getRevokeDispayString:message];
    }
    return str;
}

+ (nullable NSString *)parseDisplayStringFromMessageElement:(V2TIMMessage *)message {
    NSString *str = nil;
    switch (message.elemType) {
        case V2TIM_ELEM_TYPE_TEXT: {
            str = [TUITextMessageCellData getDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_IMAGE: {
            str = [TUIImageMessageCellData getDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_SOUND: {
            str = [TUIVoiceMessageCellData getDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_VIDEO: {
            str = [TUIVideoMessageCellData getDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_FILE: {
            str = [TUIFileMessageCellData getDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_FACE: {
            str = [TUIFaceMessageCellData getDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_MERGER: {
            str = [TUIMergeMessageCellData getDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_GROUP_TIPS: {
            str = [self getGroupTipsDisplayString:message];
        } break;
        case V2TIM_ELEM_TYPE_CUSTOM: {
            str = [self getCustomDisplayString:message];
        } break;
        default:
            str = TIMCommonLocalizableString(TUIKitMessageTipsUnsupportCustomMessage);
            break;
    }
    return str;
}

+ (nullable NSString *)getCustomDisplayString:(V2TIMMessage *)message {
    // ************************************************************************************
    // ************************************************************************************
    // ************** TUICallKit 的兼容处理逻辑，待 TUICallKit 按照标准流程接入后移除 *************
    // ************************************************************************************
    // ************************************************************************************
    NSString *str = nil;
    id<TUIChatCallingInfoProtocol> callingInfo = nil;
    if ([self.callingDataProvider isCallingMessage:message callingInfo:&callingInfo]) {
        // Voice-video-call message
        if (callingInfo) {
            // Supported voice-video-call message
            if (callingInfo.excludeFromHistory) {
                // This message will be ignore in chat page
                str = nil;
            } else {
                // Get display text
                str = callingInfo.content ?: TIMCommonLocalizableString(TUIKitMessageTipsUnsupportCustomMessage);
            }
        } else {
            // Unsupported voice-video-call message
            str = TIMCommonLocalizableString(TUIKitMessageTipsUnsupportCustomMessage);
        }
        return str;
    }
    // ************************************************************************************
    // ************************************************************************************
    // ************************************************************************************
    // ************************************************************************************
    
    
    NSString *businessID = nil;
    BOOL excludeFromHistory = NO;

    V2TIMSignalingInfo *signalingInfo = [V2TIMManager.sharedInstance getSignallingInfo:message];
    if (signalingInfo) {
        // This message is signaling message
        excludeFromHistory = message.isExcludedFromLastMessage && message.isExcludedFromUnreadCount;
        businessID = [self getSignalingBusinessID:signalingInfo];
    } else {
        // This message is normal custom message
        excludeFromHistory = NO;
        businessID = [self getCustomBusinessID:message];
    }

    if (excludeFromHistory) {
        // Return nil means not display int the chat page
        return nil;
    }

    if (businessID.length > 0) {
        Class cellDataClass = nil;
        if (gDataSourceClass && [gDataSourceClass respondsToSelector:@selector(onGetCustomMessageCellDataClass:)]) {
            cellDataClass = [gDataSourceClass onGetCustomMessageCellDataClass:businessID];
        }
        if (cellDataClass && [cellDataClass respondsToSelector:@selector(getDisplayString:)]) {
            return [cellDataClass getDisplayString:message];
        }
        // CustomerService、ChatBot 场景，不支持的消息直接不展示
        if ([businessID containsString:BussinessID_CustomerService] || [businessID containsString:BussinessID_ChatBot]) {
            return nil;
        }
        return TIMCommonLocalizableString(TUIKitMessageTipsUnsupportCustomMessage);
    } else {
        return TIMCommonLocalizableString(TUIKitMessageTipsUnsupportCustomMessage);
    }
}

#pragma mark - Data source operate
- (void)preProcessReplyMessageV2:(NSArray<TUIMessageCellData *> *)uiMsgs callback:(void (^)(void))callback {
    if (uiMsgs.count == 0) {
        if (callback) {
            callback();
        }
        return;
    }

    @weakify(self);
    dispatch_group_t group = dispatch_group_create();
    for (TUIMessageCellData *cellData in uiMsgs) {
        if (![cellData isKindOfClass:TUIReplyMessageCellData.class]) {
            continue;
        }

        TUIReplyMessageCellData *myData = (TUIReplyMessageCellData *)cellData;
        __weak typeof(myData) weakMyData = myData;
        myData.onFinish = ^{
            NSUInteger index = [self.uiMsgs indexOfObject:weakMyData];
            if (index != NSNotFound) {
                //if messageData exist In datasource, reload this data.
                @strongify(self);
                [self.dataSource dataProviderDataSourceWillChange:self];
                [self.dataSource dataProviderDataSourceChange:self withType:TUIMessageBaseDataProviderDataSourceChangeTypeReload atIndex:index animation:NO];
                [self.dataSource dataProviderDataSourceDidChange:self];
            }
        };
        dispatch_group_enter(group);
        [self loadOriginMessageFromReplyData:myData
                                dealCallback:^{
                                  dispatch_group_leave(group);
                                }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
      if (callback) {
          callback();
      }
    });
}

- (void)deleteUIMsgs:(NSArray<TUIMessageCellData *> *)uiMsgs SuccBlock:(nullable V2TIMSucc)succ FailBlock:(nullable V2TIMFail)fail {
    NSMutableArray *uiMsgList = [NSMutableArray array];
    NSMutableArray *imMsgList = [NSMutableArray array];
    for (TUIMessageCellData *uiMsg in uiMsgs) {
        if ([self.uiMsgs containsObject:uiMsg]) {
            // Check content cell
            [uiMsgList addObject:uiMsg];
            [imMsgList addObject:uiMsg.innerMessage];

            // Check time cell which also need to be deleted
            NSInteger index = [self.uiMsgs indexOfObject:uiMsg];
            index--;
            if (index >= 0 && index < self.uiMsgs.count && [[self.uiMsgs objectAtIndex:index] isKindOfClass:TUISystemMessageCellData.class]) {
                TUISystemMessageCellData *systemCellData = (TUISystemMessageCellData *)[self.uiMsgs objectAtIndex:index];
                if (systemCellData.type == TUISystemMessageTypeDate) {
                    [uiMsgList addObject:systemCellData];
                }
            }
        }
    }

    if (imMsgList.count == 0) {
        if (fail) {
            fail(ERR_INVALID_PARAMETERS, @"not found uiMsgs");
        }
        return;
    }

    @weakify(self);
    [self.class deleteMessages:imMsgList
                          succ:^{
                            @strongify(self);
                            [self.dataSource dataProviderDataSourceWillChange:self];
                            for (TUIMessageCellData *uiMsg in uiMsgList) {
                                NSInteger index = [self.uiMsgs indexOfObject:uiMsg];
                                [self.dataSource dataProviderDataSourceChange:self
                                                                     withType:TUIMessageBaseDataProviderDataSourceChangeTypeDelete
                                                                      atIndex:index
                                                                    animation:YES];
                            }
                            [self removeUIMsgList:uiMsgList];

                            [self.dataSource dataProviderDataSourceDidChange:self];
                            if (succ) {
                                succ();
                            }
                          }
                          fail:fail];
}

- (void)removeUIMsgList:(NSArray<TUIMessageCellData *> *)cellDatas {
    for (TUIMessageCellData *uiMsg in cellDatas) {
        [self removeUIMsg:uiMsg];
    }
}

#pragma mark - Utils
+ (nullable NSString *)getCustomBusinessID:(V2TIMMessage *)message {
    if (message == nil || message.customElem.data == nil) {
        return nil;
    }
    NSError *error = nil;
    NSDictionary *param = [NSJSONSerialization JSONObjectWithData:message.customElem.data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        NSLog(@"parse customElem data error: %@", error);
        return nil;
    }
    if (!param || ![param isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSString *businessID = param[BussinessID];
    if (businessID.length > 0 && [businessID isKindOfClass:[NSString class]]) {
        return businessID;
    } else {
        if ([param.allKeys containsObject:BussinessID_CustomerService]) {
            NSString *src = param[BussinessID_Src_CustomerService];
            if (src.length > 0 && [src isKindOfClass:[NSString class]]) {
                return [NSString stringWithFormat:@"%@%@", BussinessID_CustomerService, src];
            }
        } else if ([param.allKeys containsObject:BussinessID_ChatBot]) {
            NSNumber *src = param[BussinessID_Src_ChatBot];
            if (src && [src isKindOfClass:[NSNumber class]]) {
                return [NSString stringWithFormat:@"%@%@", BussinessID_ChatBot, src];
            }
        }
        return nil;
    }
}

+ (nullable NSString *)getSignalingBusinessID:(V2TIMSignalingInfo *)signalInfo {
    if (signalInfo.data == nil) {
        return nil;
    }
    
    NSError *error = nil;
    NSDictionary *param = [NSJSONSerialization JSONObjectWithData:[signalInfo.data dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:NSJSONReadingAllowFragments
                                                            error:&error];
    if (error) {
        NSLog(@"parse customElem data error: %@", error);
        return nil;
    }
    if (!param || ![param isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *businessID = param[BussinessID];
    if (!businessID || ![businessID isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    return businessID;
}

#pragma mark - TUICallKit 相关，待删除

static TUIChatCallingDataProvider *gCallingDataProvider;
+ (TUIChatCallingDataProvider *)callingDataProvider {
    if (gCallingDataProvider == nil) {
        gCallingDataProvider = [[TUIChatCallingDataProvider alloc] init];
    }
    return gCallingDataProvider;
}

+ (TUIMessageCellData *)getCallingCellData:(id<TUIChatCallingInfoProtocol>)callingInfo {
    TMsgDirection direction = MsgDirectionIncoming;
    if (callingInfo.direction == TUICallMessageDirectionIncoming) {
        direction = MsgDirectionIncoming;
    } else if (callingInfo.direction == TUICallMessageDirectionOutgoing) {
        direction = MsgDirectionOutgoing;
    }

    if (callingInfo.participantType == TUICallParticipantTypeC2C) {
        TUITextMessageCellData *cellData = [[TUITextMessageCellData alloc] initWithDirection:direction];
        if (callingInfo.streamMediaType == TUICallStreamMediaTypeVoice) {
            cellData.isAudioCall = YES;
        } else if (callingInfo.streamMediaType == TUICallStreamMediaTypeVideo) {
            cellData.isVideoCall = YES;
        } else {
            cellData.isAudioCall = NO;
            cellData.isVideoCall = NO;
        }
        cellData.content = callingInfo.content;
        cellData.isCaller = (callingInfo.participantRole == TUICallParticipantRoleCaller);
        cellData.showUnreadPoint = callingInfo.showUnreadPoint;
        cellData.isUseMsgReceiverAvatar = callingInfo.isUseReceiverAvatar;
        cellData.reuseId = TTextMessageCell_ReuseId;
        return cellData;
    } else if (callingInfo.participantType == TUICallParticipantTypeGroup) {
        TUISystemMessageCellData *cellData = [[TUISystemMessageCellData alloc] initWithDirection:direction];
        cellData.content = callingInfo.content;
        cellData.reuseId = TSystemMessageCell_ReuseId;
        return cellData;
    } else {
        return nil;
    }
}


@end
