//
//  TUIChatSmallTongue.m
//  TUIChat
//
//  Created by xiangzhang on 2022/1/6.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "TUIChatSmallTongueView_Minimalist.h"
#import <TIMCommon/TIMDefine.h>
#import <TUICore/TUIDarkModel.h>
#import <TUICore/TUIThemeManager.h>
#import "TUIChatConfig.h"

#define TongueMiddleSpace 5.f
#define TongueRightSpace 10.f
#define TongueFontSize 14

@interface TUIChatSmallTongueView_Minimalist ()

@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UILabel *label;

@end

@implementation TUIChatSmallTongueView_Minimalist {
    TUIChatSmallTongue_Minimalist *_tongue;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 阴影
        self.layer.shadowColor = RGBA(0, 0, 0, 0.15).CGColor;
        self.layer.shadowOpacity = 1;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 2;
        self.clipsToBounds = NO;

        // 背景图
        UIImageView *backgroudView = [[UIImageView alloc] initWithFrame:frame];
        [self addSubview:backgroudView];
        backgroudView.mm_fill();
        backgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIImage *bkImage = [[TUIImageCache sharedInstance] getResourceFromCache:TUIChatImagePath_Minimalist(@"small_tongue_bk")];
        bkImage = [bkImage rtl_imageFlippedForRightToLeftLayoutDirection];
        UIEdgeInsets ei = UIEdgeInsetsFromString(@"{5,12,5,5}");
        ei = rtlEdgeInsetsWithInsets(ei);
        backgroudView.image = [bkImage resizableImageWithCapInsets:ei resizingMode:UIImageResizingModeStretch];

        // 点击事件
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)onTap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onChatSmallTongueClick:)]) {
        [self.delegate onChatSmallTongueClick:_tongue];
    }
}

- (void)setTongue:(TUIChatSmallTongue_Minimalist *)tongue {
    _tongue = tongue;
    if (!self.imageView) {
        self.imageView = [[UIImageView alloc] init];
        [self addSubview:self.imageView];
    }
    self.imageView.image = [TUIChatSmallTongueView_Minimalist getTongueImage:tongue];
    self.imageView.mm_width(kScale390(18)).mm_height(kScale390(18)).mm_left(kScale390(18)).mm_top(kScale390(5));

    if (!self.label) {
        self.label = [[UILabel alloc] init];
        self.label.font = [UIFont systemFontOfSize:TongueFontSize];
        [self addSubview:self.label];
    }
    NSString *text = [TUIChatSmallTongueView_Minimalist getTongueText:tongue];
    ;
    if (text) {
        self.label.hidden = NO;
        self.label.text = text;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = TUIChatDynamicColor(@"chat_drop_down_color", @"#147AFF");
        self.label.mm_width(kScale390(16)).mm_height(kScale390(20)).mm_top(self.imageView.mm_b + kScale390(2)).mm__centerX(self.imageView.mm_centerX);
    } else {
        self.label.hidden = YES;
    }
}

+ (CGFloat)getTongueWidth:(TUIChatSmallTongue_Minimalist *)tongue {
    return kScale390(54);
}

+ (CGFloat)getTongueHeight:(TUIChatSmallTongue_Minimalist *)tongue {
    CGFloat tongueHeight = 0;
    switch (tongue.type) {
        case TUIChatSmallTongueType_ScrollToBoom: {
            tongueHeight = kScale390(29);
        } break;
        case TUIChatSmallTongueType_ReceiveNewMsg: {
            tongueHeight = kScale390(47);
        } break;
        case TUIChatSmallTongueType_SomeoneAt: {
            tongueHeight = kScale390(47);
        } break;
        default:
            break;
    }
    return tongueHeight;
}

+ (NSString *)getTongueText:(TUIChatSmallTongue_Minimalist *)tongue {
    NSString *tongueText = nil;
    switch (tongue.type) {
        case TUIChatSmallTongueType_ScrollToBoom: {
            tongueText = nil;
        } break;
        case TUIChatSmallTongueType_ReceiveNewMsg: {
            tongueText = [NSString stringWithFormat:@"%@", tongue.unreadMsgCount > 99 ? @"99+" : @(tongue.unreadMsgCount)];
        } break;
        case TUIChatSmallTongueType_SomeoneAt: {
            tongueText = [NSString stringWithFormat:@"%@", tongue.atMsgSeqs.count > 99 ? @"99+" : @(tongue.atMsgSeqs.count)];
        } break;
        default:
            break;
    }
    return tongueText;
}

+ (UIImage *)getTongueImage:(TUIChatSmallTongue_Minimalist *)tongue {
    UIImage *tongueImage = nil;
    switch (tongue.type) {
        case TUIChatSmallTongueType_ScrollToBoom: {
            tongueImage = [[TUIImageCache sharedInstance] getResourceFromCache:TUIChatImagePath_Minimalist(@"small_tongue_scroll_to_boom")];
        } break;
        case TUIChatSmallTongueType_ReceiveNewMsg: {
            tongueImage = [[TUIImageCache sharedInstance] getResourceFromCache:TUIChatImagePath_Minimalist(@"small_tongue_scroll_to_boom")];
            break;
        }
        case TUIChatSmallTongueType_SomeoneAt: {
            tongueImage = [[TUIImageCache sharedInstance] getResourceFromCache:TUIChatImagePath_Minimalist(@"small_tongue_someone_at_me")];
        } break;
        default:
            break;
    }
    return tongueImage;
}

@end

@implementation TUIChatSmallTongue_Minimalist

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = TUIChatSmallTongueType_None;
    }
    return self;
}

@end

static TUIChatSmallTongueView_Minimalist *gTongueView = nil;
static TUIChatSmallTongue_Minimalist *gTongue = nil;
static UIWindow *gWindow = nil;

@implementation TUIChatSmallTongueManager_Minimalist

+ (void)showTongue:(TUIChatSmallTongue_Minimalist *)tongue delegate:(id<TUIChatSmallTongueViewDelegate_Minimalist>)delegate {
    if (tongue.type == gTongue.type && tongue.unreadMsgCount == gTongue.unreadMsgCount && tongue.atMsgSeqs == gTongue.atMsgSeqs) {
        return;
    }
    gTongue = tongue;

    if (!gWindow) {
        gWindow = [[UIWindow alloc] initWithFrame:CGRectZero];
        gWindow.windowLevel = UIWindowLevelAlert;
        gWindow.backgroundColor = [UIColor clearColor];

        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    gWindow.windowScene = windowScene;
                    break;
                }
            }
        }
    }

    CGFloat tongueWidth = [TUIChatSmallTongueView_Minimalist getTongueWidth:gTongue];
    CGFloat tongueHeight = [TUIChatSmallTongueView_Minimalist getTongueHeight:gTongue];
    if(isRTL()) {
        gWindow.frame =
            CGRectMake(kScale390(16), Screen_Height - Bottom_SafeHeight - TTextView_Height - 20 - tongueHeight, tongueWidth, tongueHeight);
    }
    else {
        gWindow.frame =
            CGRectMake(Screen_Width - kScale390(54), Screen_Height - Bottom_SafeHeight - TTextView_Height - 20 - tongueHeight, tongueWidth, tongueHeight);
    }
    if (!gTongueView) {
        gTongueView = [[TUIChatSmallTongueView_Minimalist alloc] initWithFrame:CGRectZero];
        [gWindow addSubview:gTongueView];
        gWindow.hidden = NO;
    }
    gTongueView.frame = gWindow.bounds;
    gTongueView.delegate = delegate;
    [gTongueView setTongue:gTongue];
}

+ (void)removeTongue:(TUIChatSmallTongueType)type {
    if (type != gTongue.type) {
        return;
    }
    [self removeTongue];
}

+ (void)removeTongue {
    gTongue = nil;
    gTongueView = nil;
    gWindow = nil;
}

+ (void)hideTongue:(BOOL)isHidden {
    if (gTongueView) {
        gTongueView.hidden = isHidden;
    }
}

@end
