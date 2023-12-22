//
//  TUIChatConfig.m
//  TUIChat
//
//  Created by wyl on 2022/6/10.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "TUIChatConfig.h"
#import <TIMCommon/TIMDefine.h>
#import <TIMCommon/TIMDefine.h>
#import <TUICore/TUICore.h>

@implementation TUIChatConfig

- (id)init {
    self = [super init];
    if (self) {
        self.msgNeedReadReceipt = NO;
        self.enableVideoCall = YES;
        self.enableAudioCall = YES;
        self.enableWelcomeCustomMessage = YES;
        self.enablePopMenuEmojiReactAction = YES;
        self.enablePopMenuReplyAction = YES;
        self.enablePopMenuReferenceAction = YES;
        self.enableMainPageInputBar = YES;
        self.enableTypingStatus = YES;
        self.enableFloatWindowForCall = YES;
        self.enableMultiDeviceForCall = NO;
        self.timeIntervalForMessageRecall = 120;
        [self updateEmojiGroups];
    }
    return self;
}

+ (TUIChatConfig *)defaultConfig {
    static dispatch_once_t onceToken;
    static TUIChatConfig *config;
    dispatch_once(&onceToken, ^{
      config = [[TUIChatConfig alloc] init];
    });
    return config;
}

- (void)onChangeLanguage {
    [self updateEmojiGroups];
}

- (void)updateEmojiGroups {
    self.chatContextEmojiDetailGroups = [self updateFaceGroups:self.chatContextEmojiDetailGroups];
}

- (NSArray *)updateFaceGroups:(NSArray *)groups {
    if (groups.count) {
        NSMutableArray *arrayM = [NSMutableArray arrayWithArray:groups];
        [arrayM removeObjectAtIndex:0];

        TUIFaceGroup *defaultFaceGroup = [self findFaceGroup];
        if (defaultFaceGroup) {
            [arrayM insertObject:[self findFaceGroup] atIndex:0];
        }
        return [NSArray arrayWithArray:arrayM];
    } else {
        NSMutableArray *faceArray = [NSMutableArray array];
        TUIFaceGroup *defaultFaceGroup = [self findFaceGroup];
        if (defaultFaceGroup) {
            [faceArray addObject:defaultFaceGroup];
        }
        return faceArray;
    }
    return @[];
}
- (void)addFaceToCache:(NSString *)path {
    [[TUIImageCache sharedInstance] addFaceToCache:path];
}
- (TUIFaceGroup *)findFaceGroup {
    // emoji group

    NSMutableArray *emojiFaces = [NSMutableArray array];
    NSArray *emojis = [NSArray arrayWithContentsOfFile:TUIChatFaceImagePath(@"emoji/emoji.plist")];
    for (NSDictionary *dic in emojis) {
        TUIFaceCellData *data = [[TUIFaceCellData alloc] init];
        NSString *name = [dic objectForKey:@"face_name"];
        NSString *path = [NSString stringWithFormat:@"emoji/%@", name];
        NSString *localizableName = [TUIGlobalization g_localizedStringForKey:name bundle:@"TUIChatFace"];
        data.name = name;
        data.path = TUIChatFaceImagePath(path);
        data.localizableName = localizableName;
        [self addFaceToCache:data.path];
        [emojiFaces addObject:data];
    }
    if (emojiFaces.count != 0) {
        TUIFaceGroup *emojiGroup = [[TUIFaceGroup alloc] init];
        emojiGroup.faces = emojiFaces;
        emojiGroup.groupIndex = 0;
        emojiGroup.groupPath = TUIChatFaceImagePath(@"emoji/");
        emojiGroup.menuPath = TUIChatFaceImagePath(@"emoji/menu");
        emojiGroup.rowCount = 20;
        emojiGroup.itemCountPerRow = 7;
        emojiGroup.needBackDelete = NO;
        [self addFaceToCache:emojiGroup.menuPath];
        return emojiGroup;
    }

    return nil;
}

- (TUIChatEventConfig *)eventConfig {
    if (!_eventConfig) {
        _eventConfig = [[TUIChatEventConfig alloc] init];
    }
    return _eventConfig;
}

@end

@implementation TUIChatEventConfig

@end


@implementation TUIChatConfig (CustomMessageRegiser)

- (void)registerCustomMessage:(NSString *)businessID
             messageCellClassName:(NSString *)cellName
         messageCellDataClassName:(NSString *)cellDataName {
    [self registerCustomMessage:businessID
           messageCellClassName:cellName
       messageCellDataClassName:cellDataName
                      styleType:TUIChatRegisterCustomMessageStyleTypeClassic];
}

- (void)registerCustomMessage:(NSString *)businessID
              messageCellClassName:(NSString *)cellName
          messageCellDataClassName:(NSString *)cellDataName
                    styleType:(TUIChatRegisterCustomMessageStyleType)styleType {
    
    if (businessID.length <0 || cellName.length <0 ||cellDataName.length <0) {
        NSLog(@"registerCustomMessage Error, check info %s", __func__);
        return;
    }
    NSString * serviceName = @"";
    if (styleType == TUIChatRegisterCustomMessageStyleTypeClassic) {
        serviceName = TUICore_TUIChatService;
    }
    else {
        serviceName = TUICore_TUIChatService_Minimalist;
    }
    [TUICore callService:serviceName
                  method:TUICore_TUIChatService_AppendCustomMessageMethod
                   param:@{BussinessID : businessID,
                           TMessageCell_Name : cellName,
                           TMessageCell_Data_Name : cellDataName
                         }
    ];
}


@end
