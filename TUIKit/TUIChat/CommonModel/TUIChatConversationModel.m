//
//  TUIChatConversationModel.m
//  TXIMSDK_TUIKit_iOS
//
//  Created by kayev on 2021/8/12.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "TUIChatConversationModel.h"

@implementation TUIChatConversationModel

- (instancetype)init {
    self = [super init];
    if (self){
        self.msgNeedReadReceipt = YES;
        self.enableVideoCall = YES;
        self.enableAudioCall = YES;
        self.enabelRoom  = YES;
        self.enableWelcomeCustomMessage  = YES;
        self.isLimitedPortraitOrientation = NO;
        self.enablePoll = YES;
        self.enableGroupNote = YES;
    }
    return self;
}
@end
