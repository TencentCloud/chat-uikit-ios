
//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

#import <TIMCommon/TIMDefine.h>
#import "TUIBaseMessageController_Minimalist.h"

NS_ASSUME_NONNULL_BEGIN

@interface TUIMessageController_Minimalist : TUIBaseMessageController_Minimalist

/**
 * Highlight text
 * In the search scenario, when highlightKeyword is not empty and matches @locateMessage, opening the chat session page will highlight the current cell
 */
@property(nonatomic, copy) NSString *hightlightKeyword;

/**
 * Locate message
 * In the search scenario, when locateMessage is not empty, opening the chat session page will automatically scroll to here
 */
@property(nonatomic, strong) V2TIMMessage *locateMessage;

@property(nonatomic, strong) V2TIMMessage *C2CIncomingLastMsg;

@end

NS_ASSUME_NONNULL_END
