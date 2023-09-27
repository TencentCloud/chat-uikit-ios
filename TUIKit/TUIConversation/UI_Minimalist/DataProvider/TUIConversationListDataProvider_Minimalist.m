//
//  V2TUIConversationListDataProvider.m
//  TUIConversation
//
//  Created by harvy on 2022/7/14.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "TUIConversationListDataProvider_Minimalist.h"
#import <TIMCommon/TIMDefine.h>
#import <TUICore/TUICore.h>
#import "TUIConversationCellData_Minimalist.h"
#import <TIMCommon/NSString+TUIEmoji.h>

@implementation TUIConversationListDataProvider_Minimalist
- (Class)getConversationCellClass {
    return [TUIConversationCellData_Minimalist class];
}

- (NSString *)getDisplayStringFromService:(V2TIMMessage *)msg {
    NSDictionary *param = @{TUICore_TUIChatService_GetDisplayStringMethod_MsgKey : msg};
    return [TUICore callService:TUICore_TUIChatService_Minimalist method:TUICore_TUIChatService_GetDisplayStringMethod param:param];
}

- (NSMutableAttributedString *)getLastDisplayString:(V2TIMConversation *)conv {
    /**
     * 如果有群 @ ，展示群 @ 信息
     * If has group-at message, the group-at information will be displayed first
     */
    NSString *atStr = [self getGroupAtTipString:conv];
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:atStr];
    NSDictionary *attributeDict = @{NSForegroundColorAttributeName : [UIColor d_systemRedColor]};
    [attributeString setAttributes:attributeDict range:NSMakeRange(0, attributeString.length)];

    /**
     * 如果有草稿箱，优先展示草稿箱信息
     * If there is a draft box, the draft box information will be displayed first
     */
    if (conv.draftText.length > 0) {
        NSAttributedString *draft = [[NSAttributedString alloc] initWithString:TIMCommonLocalizableString(TUIKitMessageTypeDraftFormat)
                                                                    attributes:@{NSForegroundColorAttributeName : RGB(250, 81, 81)}];
        [attributeString appendAttributedString:draft];

        NSString *draftContentStr = [self getDraftContent:conv];
        draftContentStr = [draftContentStr getLocalizableStringWithFaceContent];
        NSAttributedString *draftContent = [[NSAttributedString alloc] initWithString:draftContentStr
                                                                           attributes:@{NSForegroundColorAttributeName : [UIColor d_systemGrayColor]}];
        [attributeString appendAttributedString:draftContent];
    } else {
        /**
         * 没有草稿箱，展示会话 lastMsg 信息
         * No drafts, show conversation lastMsg information
         */
        NSString *lastMsgStr = @"";

        /**
         * 先看下外部有没自定义会话的 lastMsg 展示信息
         * Attempt to get externally customized display information
         */
        if (self.delegate && [self.delegate respondsToSelector:@selector(getConversationDisplayString:)]) {
            lastMsgStr = [self.delegate getConversationDisplayString:conv];
        }

        /**
         * 外部没有自定义，通过消息获取 lastMsg 展示信息
         * If there is no external customization, get the lastMsg display information through the message module
         */
        if (lastMsgStr.length == 0 && conv.lastMessage) {
            lastMsgStr = [self getDisplayStringFromService:conv.lastMessage];
        }

        /**
         * 如果没有 lastMsg 展示信息，也没有草稿信息，直接返回 nil
         * If there is no lastMsg display information and no draft information, return nil directly
         */
        if (lastMsgStr.length == 0) {
            return nil;
        }
        [attributeString appendAttributedString:[[NSAttributedString alloc] initWithString:lastMsgStr]];
    }

    /**
     * 如果设置了免打扰，展示消息免打扰状态
     * Meeting 群默认就是 V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE 状态，UI 上不特殊处理
     *
     * If do-not-disturb is set, the message do-not-disturb state is displayed
     * The default state of the meeting type group is V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE, and the UI does not process it.
     */
    if ([self isConversationNotDisturb:conv] && conv.unreadCount > 0) {
        NSAttributedString *unreadString = [[NSAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"[%d %@] ", conv.unreadCount, TIMCommonLocalizableString(TUIKitMessageTypeLastMsgCountFormat)]];
        [attributeString insertAttributedString:unreadString atIndex:0];
    }

    return attributeString;
}
@end
