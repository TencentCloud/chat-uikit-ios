//
//  TUIBaseMessageController.m
//  UIKit
//
//  Created by annidyfeng on 2019/7/1.
//  Copyright © 2022 Tencent. All rights reserved.
//

#import "TUIBaseMessageController.h"
#import <TIMCommon/TIMConfig.h>
#import <TIMCommon/TIMDefine.h>
#import <TIMCommon/TIMPopActionProtocol.h>
#import <TIMCommon/TUISystemMessageCell.h>
#import <TUICore/TUICore.h>
#import <TUICore/TUIThemeManager.h>
#import <TUICore/TUITool.h>
#import <UIKit/UIWindow.h>
#import "TUIChatCallingDataProvider.h"
#import "TUIChatConversationModel.h"
#import "TUIChatDataProvider.h"
#import "TUIChatPopMenu.h"
#import "TUIFaceMessageCell.h"
#import "TUIFaceView.h"
#import "TUIFileMessageCell.h"
#import "TUIFileViewController.h"
#import "TUIImageMessageCell.h"
#import "TUIJoinGroupMessageCell.h"
#import "TUILinkCell.h"
#import "TUIMediaView.h"
#import "TUIMergeMessageCell.h"
#import "TUIMergeMessageListController.h"
#import "TUIMessageDataProvider.h"
#import "TUIMessageProgressManager.h"
#import "TUIMessageReadViewController.h"
#import "TUIOrderCell.h"
#import "TUIReferenceMessageCell.h"
#import "TUIRepliesDetailViewController.h"
#import "TUIReplyMessageCell.h"
#import "TUIReplyMessageCellData.h"
#import "TUITextMessageCell.h"
#import "TUIVideoMessageCell.h"
#import "TUIVoiceMessageCell.h"
#import "TUIMessageCellConfig.h"

@interface TUIBaseMessageController () <TUIMessageCellDelegate,
                                        TUIJoinGroupMessageCellDelegate,
                                        TUIMessageProgressManagerDelegate,
                                        TUIMessageDataProviderDataSource,
                                        TUINotificationProtocol,
                                        TIMPopActionProtocol>

@property(nonatomic, strong) TUIMessageDataProvider *messageDataProvider;
@property(nonatomic, strong) TUIMessageCellData *menuUIMsg;
@property(nonatomic, strong) TUIMessageCellData *reSendUIMsg;
@property(nonatomic, strong) TUIChatConversationModel *conversationData;
@property(nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property(nonatomic, assign) BOOL isActive;
@property(nonatomic, assign) BOOL showCheckBox;
@property(nonatomic, assign) BOOL scrollingTriggeredByUser;
@property(nonatomic, assign) BOOL isAutoScrolledToBottom;
@property(nonatomic, assign) BOOL hasCoverPage;
@property(nonatomic, strong) TUIMessageCellConfig *messageCellConfig;
@end

@implementation TUIBaseMessageController
+ (void)initialize {
    [TUIMessageDataProvider setDataSourceClass:self];
}

+ (nullable NSString *)getDisplayString:(V2TIMMessage *)message {
    return [TUIMessageDataProvider getDisplayString:message];
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self registerEvents];
    self.isActive = YES;
    [TUITool addUnsupportNotificationInVC:self];
    [TUIMessageProgressManager.shareManager addDelegate:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [TUIMessageProgressManager.shareManager removeDelegate:self];
    [TUICore unRegisterEventByObject:self];
    NSLog(@"%s dealloc", __FUNCTION__);
}

- (void)viewWillAppear:(BOOL)animated {
    self.isInVC = YES;
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self sendVisibleReadGroupMessages];
    [self limitReadReport];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isInVC = NO;
}

- (void)applicationBecomeActive {
    self.isActive = YES;
    [self sendVisibleReadGroupMessages];
}

- (void)applicationEnterBackground {
    self.isActive = NO;
}

- (void)setupViews {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapViewController)];
    /**
     * 解决触摸事件没有往下传递，导致手势和 collectionView didselect 冲突的问题
     * Solve the problem that the touch event is not passed down, causing the gesture to conflict with the collectionView didselect
     */
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    self.tableView.scrollsToTop = NO;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.backgroundColor = TUIChatDynamicColor(@"chat_controller_bg_color", @"#FFFFFF");
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, TMessageController_Header_Height)];
    self.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    self.tableView.tableHeaderView = self.indicatorView;
    
    [self.messageCellConfig bindTableView:self.tableView];
}

- (void)registerEvents {
    [TUICore registerEvent:TUICore_TUIPluginNotify
                    subKey:TUICore_TUIPluginNotify_PluginViewSizeChangedSubKey
                    object:self];
    [TUICore registerEvent:TUICore_TUIPluginNotify
                    subKey:TUICore_TUIPluginNotify_WillForwardTextSubKey
                    object:self];
    [TUICore registerEvent:TUICore_TUIPluginNotify
                    subKey:TUICore_TUIPluginNotify_DidChangePluginViewSubKey
                    object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationBecomeActive)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceivedSendMessageRequest:) name:TUIChatSendMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceivedSendMessageWithoutUpdateUIRequest:) name:TUIChatSendMessageWithoutUpdateUINotification object:nil];
}

- (TUIMessageCellConfig *)messageCellConfig {
    if (_messageCellConfig == nil) {
        _messageCellConfig = [[TUIMessageCellConfig alloc] init];
    }
    return _messageCellConfig;
}

#pragma mark - Data Provider
- (void)setConversation:(TUIChatConversationModel *)conversationData {
    self.conversationData = conversationData;
    if (!self.messageDataProvider) {
        self.messageDataProvider = [[TUIMessageDataProvider alloc] initWithConversationModel:conversationData];
        self.messageDataProvider.dataSource = self;
    }
    [self loadMessage];
}

- (void)loadMessage {
    if (self.messageDataProvider.isLoadingData || self.messageDataProvider.isNoMoreMsg) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.messageDataProvider
     loadMessageSucceedBlock:^(BOOL isFirstLoad, BOOL isNoMoreMsg, NSArray<TUIMessageCellData *> *_Nonnull newMsgs) {
        if (isNoMoreMsg) {
            weakSelf.indicatorView.mm_h = 0;
        }
        if (newMsgs.count != 0) {
            [weakSelf.tableView reloadData];
            [weakSelf.tableView layoutIfNeeded];
            
            if (isFirstLoad) {
                [weakSelf scrollToBottom:NO];
            } else {
                CGFloat visibleHeight = 0;
                for (NSInteger i = 0; i < newMsgs.count; ++i) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    visibleHeight += [weakSelf tableView:weakSelf.tableView heightForRowAtIndexPath:indexPath];
                }
                if (isNoMoreMsg) {
                    visibleHeight -= TMessageController_Header_Height;
                }
                [weakSelf.tableView scrollRectToVisible:CGRectMake(0, weakSelf.tableView.contentOffset.y + visibleHeight, weakSelf.tableView.frame.size.width,
                                                                   weakSelf.tableView.frame.size.height)
                                               animated:NO];
            }
        }
    }
     FailBlock:^(int code, NSString *desc) {
        [TUITool makeToastError:code msg:desc];
    }];
}

- (void)clearUImsg {
    [self.messageDataProvider clearUIMsgList];
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
}

- (void)reloadAndScrollToBottomOfMessage:(NSString *)messageID needScroll:(BOOL)isNeedScroll {
    // Dispatch the task to RunLoop to ensure that they are executed after the UITableView refresh is complete.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadCellOfMessage:messageID];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isNeedScroll) {
                [self scrollCellToBottomOfMessage:messageID];
            }
        });
    });
}
- (void)reloadAndScrollToBottomOfMessage:(NSString *)messageID {
    [self reloadAndScrollToBottomOfMessage:messageID needScroll:YES];
}

- (void)reloadCellOfMessage:(NSString *)messageID {
    NSIndexPath *indexPath = [self indexPathOfMessage:messageID];
    
    // Disable animation when loading to avoid cell jumping.
    if (indexPath == nil) {
        return;
    }
    [UIView performWithoutAnimation:^{
        [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)scrollCellToBottomOfMessage:(NSString *)messageID {
    if (self.hasCoverPage) {
        return;
    }
    NSIndexPath *indexPath = [self indexPathOfMessage:messageID];
    
    // Scroll the tableView only if the bottom of the cell is invisible.
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    CGRect tableViewRect = self.tableView.bounds;
    BOOL isBottomInvisible = (cellRect.origin.y < CGRectGetMaxY(tableViewRect) && CGRectGetMaxY(cellRect) > CGRectGetMaxY(tableViewRect)) ||
    (cellRect.origin.y >= CGRectGetMaxY(tableViewRect));
    if (isBottomInvisible) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    if (self.isAutoScrolledToBottom) {
        [self scrollToBottom:YES];
    }
}

- (NSIndexPath *)indexPathOfMessage:(NSString *)messageID {
    for (int i = 0; i < self.messageDataProvider.uiMsgs.count; i++) {
        TUIMessageCellData *data = self.messageDataProvider.uiMsgs[i];
        if ([data.innerMessage.msgID isEqualToString:messageID]) {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    return nil;
}

#pragma mark - Event Response
- (void)scrollToBottom:(BOOL)animate {
    if (self.messageDataProvider.uiMsgs.count > 0) {
        NSIndexPath *bottom = [NSIndexPath indexPathForRow:self.messageDataProvider.uiMsgs.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:bottom atScrollPosition:UITableViewScrollPositionBottom animated:animate];
        self.isAutoScrolledToBottom = YES;
    }
}

- (void)didTapViewController {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapInMessageController:)]) {
        [self.delegate didTapInMessageController:self];
    }
}

- (void)sendPlaceHolderUIMessage:(TUIMessageCellData *)cellData {
    [self.messageDataProvider sendPlaceHolderUIMessage:cellData];
    [self scrollToBottom:YES];
}

- (void)sendUIMessage:(TUIMessageCellData *)cellData {
    @weakify(self);
    cellData.innerMessage.needReadReceipt = self.isMsgNeedReadReceipt;
    [self.messageDataProvider sendUIMsg:cellData
                         toConversation:self.conversationData
                          willSendBlock:^(BOOL isReSend, TUIMessageCellData *_Nonnull dateUIMsg) {
        @strongify(self);
        [self scrollToBottom:YES];
        
        int delay = 1;
        if ([cellData isKindOfClass:[TUIImageMessageCellData class]]) {
            delay = 0;
        }
        
        @weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            if (cellData.status == Msg_Status_Sending) {
                [self changeMsg:cellData status:Msg_Status_Sending_2];
            }
        });
    }
                              SuccBlock:^{
        @strongify(self);
        [self reloadUIMessage:cellData];
        [self changeMsg:cellData status:Msg_Status_Succ];
        
        NSDictionary *param = @{
            TUICore_TUIChatNotify_SendMessageSubKey_Code : @0,
            TUICore_TUIChatNotify_SendMessageSubKey_Desc : @"",
            TUICore_TUIChatNotify_SendMessageSubKey_Message : cellData.innerMessage
        };
        [TUICore notifyEvent:TUICore_TUIChatNotify subKey:TUICore_TUIChatNotify_SendMessageSubKey object:self param:nil];
    }
                              FailBlock:^(int code, NSString *desc) {
        @strongify(self);
        NSString *errorMsg = @"";
        if (self.isMsgNeedReadReceipt && code == ERR_SDK_INTERFACE_NOT_SUPPORT) {
            errorMsg = [NSString stringWithFormat:@"%@%@", TUIKitLocalizableString(TUIKitErrorUnsupportIntefaceMessageRead),
                                             TUIKitLocalizableString(TUIKitErrorUnsupporInterfaceSuffix)];
        } else {
            errorMsg = [TUITool convertIMError:code msg:desc];
        }
        [self reloadUIMessage:cellData];
        [self makeSendErrorHud:code msg:errorMsg];
        [self changeMsg:cellData status:Msg_Status_Fail];
        
        NSDictionary *param = @{TUICore_TUIChatNotify_SendMessageSubKey_Code : @(code), TUICore_TUIChatNotify_SendMessageSubKey_Desc : desc};
        [TUICore notifyEvent:TUICore_TUIChatNotify subKey:TUICore_TUIChatNotify_SendMessageSubKey object:self param:param];
    }];
}
- (void)makeSendErrorHud:(int)code msg:(NSString *)msg  {
    if (code == 80001 || code == 80004) {
        return;
    }
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleAlert];
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TIMCommonLocalizableString(Confirm) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)sendMessage:(V2TIMMessage *)message {
    [self sendMessage:message placeHolderCellData:nil];
}

- (void)sendMessage:(V2TIMMessage *)message placeHolderCellData:(TUIMessageCellData *)placeHolderCellData {
    TUIMessageCellData *cellData = nil;
    if (message.elemType == V2TIM_ELEM_TYPE_CUSTOM) {
        cellData = [self.delegate messageController:self onNewMessage:message];
        cellData.innerMessage = message;
    }
    if (!cellData) {
        cellData = [TUIMessageDataProvider getCellData:message];
    }
    if (cellData) {
        cellData.placeHolderCellData = placeHolderCellData;
        [self sendUIMessage:cellData];
    }
}

- (void)reloadUIMessage:(TUIMessageCellData *)msg {
    // innerMessage maybe changed, reload it
    NSInteger index = [self.messageDataProvider.uiMsgs indexOfObject:msg];
    TUIMessageCellData *newData = [self.messageDataProvider transUIMsgFromIMMsg:@[ msg.innerMessage ]].lastObject;
    __weak typeof(self) weakSelf = self;
    [self.messageDataProvider preProcessMessage:@[ newData ]
                                       callback:^{
        [weakSelf.messageDataProvider replaceUIMsg:newData atIndex:index];
        [weakSelf.tableView reloadData];
    }];
}

- (void)changeMsg:(TUIMessageCellData *)msg status:(TMsgStatus)status {
    msg.status = status;
    NSInteger index = [self.messageDataProvider.uiMsgs indexOfObject:msg];
    if ([self.tableView numberOfRowsInSection:0] > index) {
        TUIMessageCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [cell fillWithData:msg];
    } else {
        NSLog(@"lack of cell");
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kTUINotifyMessageStatusChanged"
                                                        object:nil
                                                      userInfo:@{
        @"msg" : msg,
        @"status" : [NSNumber numberWithUnsignedInteger:status],
        @"msgSender" : self,
    }];
}

- (void)onReceivedSendMessageRequest:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo == nil) {
        return;
    }
    V2TIMMessage *message = [userInfo objectForKey:TUICore_TUIChatService_SendMessageMethod_MsgKey];
    if (message == nil) {
        return;
    }
    [self sendMessage:message];
}

- (void)onReceivedSendMessageWithoutUpdateUIRequest:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo == nil) {
        return;
    }
    V2TIMMessage *message = [userInfo objectForKey:TUICore_TUIChatService_SendMessageMethodWithoutUpdateUI_MsgKey];
    if (message == nil) {
        return;
    }
    TUISendMessageAppendParams *param = [TUISendMessageAppendParams new];
    param.isOnlineUserOnly = YES;
    [TUIMessageDataProvider sendMessage:message
                         toConversation:self.conversationData
                           appendParams:param
                               Progress:nil
                              SuccBlock:^{
        NSLog(@"send message without updating UI succeed");
    }
                              FailBlock:^(int code, NSString *desc) {
        NSLog(@"send message without updating UI failed, code: %d, desc: %@", code, desc);
    }];
}

#pragma mark - TUINotificationProtocol
- (void)onNotifyEvent:(NSString *)key subKey:(NSString *)subKey object:(id)anObject param:(NSDictionary *)param {
    if ([key isEqualToString:TUICore_TUIPluginNotify] && [subKey isEqualToString:TUICore_TUIPluginNotify_PluginViewSizeChangedSubKey]) {
        V2TIMMessage *message = param[TUICore_TUIPluginNotify_PluginViewSizeChangedSubKey_Message];
        for (TUIMessageCellData *data in self.messageDataProvider.uiMsgs) {
            if (data.innerMessage == message) {
                [self.messageCellConfig removeHeightCacheOfMessageCellData:data];
                [self reloadAndScrollToBottomOfMessage:data.innerMessage.msgID];
                NSIndexPath *indexPath = [self indexPathOfMessage:data.innerMessage.msgID];
                [self.tableView beginUpdates];
                [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
                [self.tableView endUpdates];
                break;
            }
        }
    } else if ([key isEqualToString: TUICore_TUIPluginNotify] && [subKey isEqualToString:TUICore_TUIPluginNotify_DidChangePluginViewSubKey]) {
        // Plugin View is Shown or content changed.
        TUIMessageCellData *data = param[TUICore_TUIPluginNotify_DidChangePluginViewSubKey_Data];
        BOOL isAllowScroll2Bottom = YES;
        if ([param[TUICore_TUIPluginNotify_DidChangePluginViewSubKey_isAllowScroll2Bottom] isEqualToString:@"0"] ) {
            isAllowScroll2Bottom = NO ;
            TUIMessageCellData *lasData = [self.messageDataProvider.uiMsgs lastObject];
            if ([lasData.msgID isEqualToString:data.msgID] ) {
                isAllowScroll2Bottom = YES;
            }
        }
        [self.messageCellConfig removeHeightCacheOfMessageCellData:data];
        [self reloadAndScrollToBottomOfMessage:data.innerMessage.msgID needScroll:isAllowScroll2Bottom];
    } else if ([key isEqualToString:TUICore_TUIPluginNotify] && [subKey isEqualToString:TUICore_TUIPluginNotify_WillForwardTextSubKey]) {
        // Text will be forwarded.
        NSString *text = param[TUICore_TUIPluginNotify_WillForwardTextSubKey_Text];
        if (self.delegate && [self.delegate respondsToSelector:@selector(messageController:onForwardText:)]) {
            [self.delegate messageController:self onForwardText:text];
        }
    }
}

#pragma mark - TUIMessageProgressManagerDelegate
- (void)onMessageSendingResultChanged:(TUIMessageSendingResultType)type messageID:(NSString *)msgID {
    // async
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (TUIMessageCellData *cellData in weakSelf.messageDataProvider.uiMsgs) {
            if ([cellData.msgID isEqual:msgID]) {
                [weakSelf changeMsg:cellData status:(type == TUIMessageSendingResultTypeSucc) ? Msg_Status_Succ : Msg_Status_Fail];
            }
        }
    });
}

#pragma mark - TUIMessageBaseDataProviderDataSource
+ (Class)onGetCustomMessageCellDataClass:(NSString *)businessID {
    return [TUIMessageCellConfig getCustomMessageCellDataClass:businessID];
}

- (void)dataProviderDataSourceWillChange:(TUIMessageDataProvider *)dataProvider {
    [self.tableView beginUpdates];
}

- (void)dataProviderDataSourceChange:(TUIMessageDataProvider *)dataProvider
                            withType:(TUIMessageBaseDataProviderDataSourceChangeType)type
                             atIndex:(NSUInteger)index
                           animation:(BOOL)animation {
    switch (type) {
        case TUIMessageBaseDataProviderDataSourceChangeTypeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ]
                                  withRowAnimation:animation ? UITableViewRowAnimationFade : UITableViewRowAnimationNone];
            break;
        case TUIMessageBaseDataProviderDataSourceChangeTypeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ]
                                  withRowAnimation:animation ? UITableViewRowAnimationFade : UITableViewRowAnimationNone];
            break;
        case TUIMessageBaseDataProviderDataSourceChangeTypeReload:
            [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ]
                                  withRowAnimation:animation ? UITableViewRowAnimationFade : UITableViewRowAnimationNone];
            break;
        default:
            break;
    }
}

- (void)dataProviderDataSourceDidChange:(TUIMessageDataProvider *)dataProvider {
    [self.tableView endUpdates];
}

- (void)dataProvider:(TUIMessageBaseDataProvider *)dataProvider onRemoveHeightCache:(TUIMessageCellData *)cellData {
    if (cellData) {
        [self.messageCellConfig removeHeightCacheOfMessageCellData:cellData];
    }
}

- (nullable TUIMessageCellData *)dataProvider:(TUIMessageDataProvider *)dataProvider CustomCellDataFromNewIMMessage:(V2TIMMessage *)msg {
    if (![msg.userID isEqualToString:self.conversationData.userID] && ![msg.groupID isEqualToString:self.conversationData.groupID]) {
        return nil;
    }
    
    if (msg.status == V2TIM_MSG_STATUS_LOCAL_REVOKED) {
        return nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(messageController:onNewMessage:)]) {
        TUIMessageCellData *customCellData = [self.delegate messageController:self onNewMessage:msg];
        if (customCellData) {
            customCellData.innerMessage = msg;
            return customCellData;
        }
    }
    return nil;
}

- (void)dataProvider:(TUIMessageDataProvider *)dataProvider ReceiveReadMsgWithUserID:(NSString *)userId Time:(time_t)timestamp {
    if (userId.length > 0 && [userId isEqualToString:self.conversationData.userID]) {
        for (int i = 0; i < self.messageDataProvider.uiMsgs.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageDataProvider.uiMsgs.count - 1 - i inSection:0];
            TUIMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            /**
             * 通过回调时间戳判定当前的未读状态是否需要改为已读状态
             * Determine whether the current unread needs to be changed to read by the callback timestamp
             */
            time_t msgTime = [cell.messageData.innerMessage.timestamp timeIntervalSince1970];
            if (msgTime <= timestamp && ![cell.readReceiptLabel.text isEqualToString:TIMCommonLocalizableString(Read)]) {
                cell.readReceiptLabel.text = TIMCommonLocalizableString(Read);
            }
        }
    }
}

- (void)dataProvider:(TUIMessageDataProvider *)dataProvider
ReceiveReadMsgWithGroupID:(NSString *)groupID
               msgID:(NSString *)msgID
           readCount:(NSUInteger)readCount
         unreadCount:(NSUInteger)unreadCount {
    if (groupID != nil && ![groupID isEqualToString:self.conversationData.groupID]) {
        return;
    }
    NSInteger row = [self.messageDataProvider getIndexOfMessage:msgID];
    if (row < 0 || row >= self.messageDataProvider.uiMsgs.count) {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TUIMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateReadLabelText];
}

- (void)dataProvider:(TUIMessageDataProvider *)dataProvider ReceiveNewUIMsg:(TUIMessageCellData *)uiMsg {
    /**
     * 查看历史消息的时候根据当前 contentOffset 判断是否需要滑动到底部
     * When viewing historical messages, judge whether you need to slide to the bottom according to the current contentOffset
     */
    if (self.tableView.contentSize.height - self.tableView.contentOffset.y < Screen_Height * 1.5) {
        [self scrollToBottom:YES];
        if (self.isInVC && self.isActive) {
            [self.messageDataProvider sendLatestMessageReadReceipt];
        }
    }
    
    [self limitReadReport];
}

- (void)dataProvider:(TUIMessageDataProvider *)dataProvider ReceiveRevokeUIMsg:(TUIMessageCellData *)uiMsg {
    return;
}

#pragma mark - Private
- (void)limitReadReport {
    static uint64_t lastTs = 0;
    uint64_t curTs = [[NSDate date] timeIntervalSince1970];
    /**
     * 超过 1s && 非首次，立即上报已读
     * More than 1s && Not the first time, report immediately
     */
    if (curTs - lastTs >= 1 && lastTs) {
        lastTs = curTs;
        [self readReport];
    } else {
        /**
         * 低于 1s || 首次  延迟 1s 合并上报
         * Less than 1s || First time, delay 1s and merge report
         */
        static BOOL delayReport = NO;
        if (delayReport) {
            return;
        }
        delayReport = YES;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf readReport];
            delayReport = NO;
        });
    }
}

- (void)readReport {
    if (self.isInVC && self.isActive) {
        NSString *userID = self.conversationData.userID;
        if (userID.length > 0) {
            [TUIMessageDataProvider markC2CMessageAsRead:userID succ:nil fail:nil];
        }
        NSString *groupID = self.conversationData.groupID;
        if (groupID.length > 0) {
            [TUIMessageDataProvider markGroupMessageAsRead:groupID succ:nil fail:nil];
        }
        
        NSString *conversationID = @"";
        
        if (IS_NOT_EMPTY_NSSTRING(userID)) {
            conversationID = [NSString stringWithFormat:@"c2c_%@", userID];
        }
        
        if (IS_NOT_EMPTY_NSSTRING(groupID)) {
            conversationID = [NSString stringWithFormat:@"group_%@", groupID];
        }
        
        if (IS_NOT_EMPTY_NSSTRING(self.conversationData.conversationID)) {
            conversationID = self.conversationData.conversationID;
        }
        if (conversationID.length > 0) {
            [TUIMessageDataProvider markConversationAsUndead:@[ conversationID ] enableMark:NO];
        }
    }
}

/**
 * 接收方需发送可见消息已读回执的时机：
 * 1、messageVC 可见时。在 [self viewDidAppear:] 中获得通知。
 * 2、代码调用 [self scrollToBottom:] 后 scrollView 自动跳转到底部停止时（例如点击右下角 "x 条新消息" tips）。在 [UIScrollViewDelegate
 * scrollViewDidEndScrollingAnimation:] 中获得通知。
 *    + 注意需要借助 scrollView 的状态来准确判断 scrollView 是否真的停止了滑动。
 * 3、用户连续地拖拽 scrollView 滑动查看消息时。在 [UIScrollViewDelegate scrollViewDidScroll:] 中得到通知。
 *    + 注意此处要判断 scrollView 的滑动是否由用户手势触发（而不是自动代码触发）。因此借助 self.scrollingTriggeredByUser 标志位来区分。
 *    + self.scrollingTriggeredByUser 的更新逻辑：
 *      - 用户手指触碰到屏幕并且开始拖拽时（scrollViewWillBeginDragging:）置 YES；
 *      - 用户手指以一定的加速度拖拽后离开屏幕，屏幕自动停止滑动时（scrollViewDidEndDecelerating:）置 NO；
 *      - 用户手指滑动后不施加加速度，直接抬起手指时（scrollViewDidEndDragging:）置 NO。
 * 4、用户停留在最新消息界面，此时收到了新消息时。在 [self dataProvider:ReceiveNewUIMsg:] 中得到通知。
 *
 * When the receiver sends a visible message read receipt:
 * 1. The time when messageVC is visible.  You will be notified when [self viewDidAppear:] is invoked
 * 2. The time when scrollview scrolled to bottom by called [self scrollToBottom:] (For example, click the "x new message" tips in the lower right corner). You
 * will be notified when  [UIScrollViewDelegate scrollViewDidEndScrollingAnimation:]  is invoked.
 *   + Note that you need to use the state of the scrollView to accurately determine whether the scrollView has really stopped sliding.
 * 3. The time when the user drags the scrollView continuously to view the message. You will be notified when [UIScrollViewDelegate scrollViewDidScroll:]  is
 * invoked.
 *   + Note here to determine whether the scrolling of the scrollView is triggered by user gestures (rather than automatic code triggers). So use the
 * self.scrollingTriggeredByUser flag to distinguish.
 *   + The update logic of self.scrollingTriggeredByUser is as follows:
 *     - Set YES when the user's finger touches the screen and starts to drag (scrollViewWillBeginDragging:);
 *     - When the user's finger drags at a certain acceleration and leaves the screen, when the screen automatically stops sliding
 * (scrollViewDidEndDecelerating:), set to NO;
 *     - No acceleration is applied after the user's finger slides, and when the user lifts the finger directly (scrollViewDidEndDragging:), set NO.
 * 4. When the user stays in the latest message interface and receives a new message at this time. Get notified in [self dataProvider:ReceiveNewUIMsg:] .
 */
- (void)sendVisibleReadGroupMessages {
    if (self.isInVC && self.isActive) {
        NSRange range = [self calcVisibleCellRange];
        [self.messageDataProvider sendMessageReadReceiptAtIndexes:[self transferIndexFromRange:range]];
    }
}

- (NSRange)calcVisibleCellRange {
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    if (indexPaths.count == 0) {
        return NSMakeRange(0, 0);
    }
    NSIndexPath *topmost = indexPaths.firstObject;
    NSIndexPath *downmost = indexPaths.lastObject;
    return NSMakeRange(topmost.row, downmost.row - topmost.row + 1);
}

- (NSArray *)transferIndexFromRange:(NSRange)range {
    NSMutableArray *index = [NSMutableArray array];
    NSInteger start = range.location;
    for (int i = 0; i < range.length; i++) {
        [index addObject:@(start + i)];
    }
    return index;
}

- (void)hideKeyboardIfNeeded {
    [self.view endEditing:YES];
    [TUITool.applicationKeywindow endEditing:YES];
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageDataProvider.uiMsgs.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.messageDataProvider.uiMsgs.count) {
        TUIMessageCellData *cellData = self.messageDataProvider.uiMsgs[indexPath.row];
        return [self.messageCellConfig getHeightFromMessageCellData:cellData];
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.messageDataProvider.uiMsgs.count) {
        TUIMessageCellData *cellData = self.messageDataProvider.uiMsgs[indexPath.row];
        CGFloat height = [self.messageCellConfig getEstimatedHeightFromMessageCellData:cellData];
        return height > 0 ? height : 60;
    } else {
        return 60.f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TUIMessageCellData *data = self.messageDataProvider.uiMsgs[indexPath.row];
    data.showCheckBox = self.showCheckBox && [self supportCheckBox:data];
    TUIMessageCell *cell = nil;
    if ([self.delegate respondsToSelector:@selector(messageController:onShowMessageData:)]) {
        cell = [self.delegate messageController:self onShowMessageData:data];
        if (cell) {
            cell.delegate = self;
            return cell;
        }
    }
    
    if (!data.reuseId) {
        NSAssert(NO, @"Unknow cell");
        return nil;
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:data.reuseId forIndexPath:indexPath];
    TUIMessageCellData *oldData = cell.messageData;
    cell.delegate = self;
    [cell fillWithData:data];
    [cell notifyBottomContainerReadyOfData:oldData];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    TUIMessageCell *uiMsg = (TUIMessageCell *)cell;
    if ([uiMsg isKindOfClass:TUIMessageCell.class] && [self.delegate respondsToSelector:@selector(messageController:willDisplayCell:withData:)]) {
        [self.delegate messageController:self willDisplayCell:uiMsg withData:uiMsg.messageData];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.messageDataProvider.uiMsgs.count) {
        TUITextMessageCellData *cellData = (TUITextMessageCellData *)self.messageDataProvider.uiMsgs[indexPath.row];
        // 待 TUICallKit 按照标准流程介入后删除
        if ([cellData isKindOfClass:TUITextMessageCellData.class]) {
            if ((cellData.isAudioCall || cellData.isVideoCall) && cellData.showUnreadPoint) {
                cellData.innerMessage.localCustomInt = 1;
                cellData.showUnreadPoint = NO;
            }
        }
        [TUICore notifyEvent:TUICore_TUIChatNotify
                              subKey:TUICore_TUIChatNotify_MessageDisplayedSubKey
                              object:cellData
                               param:nil];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollingTriggeredByUser) {
        // only if the scrollView is dragged by user's finger to scroll, we need to send read receipts.
        [self sendVisibleReadGroupMessages];
        self.isAutoScrolledToBottom = NO;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.scrollingTriggeredByUser = YES;
    [self didTapViewController];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self isScrollViewEndDragging:scrollView]) {
        // user presses on the scrolling scrollView and forces it to stop scrolling immediately.
        self.scrollingTriggeredByUser = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self isScrollViewEndDecelerating:scrollView]) {
        // user drags the scrollView with a certain acceleration and makes a flick gesture, and scrollView will stop scrolling after decelerating.
        self.scrollingTriggeredByUser = NO;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self isScrollViewEndDecelerating:scrollView]) {
        // UIScrollView automatically stops scrolling, for example triggered after calling scrollToBottom
        [self sendVisibleReadGroupMessages];
    }
}

- (BOOL)isScrollViewEndDecelerating:(UIScrollView *)scrollView {
    return scrollView.tracking == 0 && scrollView.dragging == 0 && scrollView.decelerating == 0;
}

- (BOOL)isScrollViewEndDragging:(UIScrollView *)scrollView {
    return scrollView.tracking == 1 && scrollView.dragging == 0 && scrollView.decelerating == 0;
}

#pragma mark - TUIMessageCellDelegate

- (void)onSelectMessage:(TUIMessageCell *)cell {
    
    if (TUIChatConfig.defaultConfig.eventConfig.chatEventListener &&
        [TUIChatConfig.defaultConfig.eventConfig.chatEventListener respondsToSelector:@selector(onMessageClicked:messageCellData:)]) {
        BOOL result = [TUIChatConfig.defaultConfig.eventConfig.chatEventListener onMessageClicked:cell messageCellData:cell.messageData];
        if (result) {
            return;
        }
    }

    if (cell.messageData.innerMessage.hasRiskContent) {
        if (![cell isKindOfClass:[TUIReferenceMessageCell class]]) {
            return;
        }
    }
    if (self.showCheckBox && [self supportCheckBox:(TUIMessageCellData *)cell.data]) {
        TUIMessageCellData *data = (TUIMessageCellData *)cell.data;
        data.selected = !data.selected;
        [self.tableView reloadData];
        return;
    }
    
    if ([TUIMessageCellConfig isPluginCustomMessageCellData:cell.messageData]) {
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        if (cell) {
            param[TUICore_TUIPluginNotify_PluginCustomCellClick_Cell] = cell;
        }
        if (self.navigationController) {
            param[TUICore_TUIPluginNotify_PluginCustomCellClick_PushVC] = self.navigationController;
        }
        if (cell.pluginMsgSelectCallback) {
            cell.pluginMsgSelectCallback(param);
        }
    } else if ([cell isKindOfClass:[TUITextMessageCell class]]) {
        [self clickTextMessage:(TUITextMessageCell *)cell];
    } else if ([cell isKindOfClass:[TUISystemMessageCell class]]) {
        [self clickSystemMessage:(TUISystemMessageCell *)cell];
    } else if ([cell isKindOfClass:[TUIVoiceMessageCell class]]) {
        [self playVoiceMessage:(TUIVoiceMessageCell *)cell];
    } else if ([cell isKindOfClass:[TUIImageMessageCell class]]) {
        [self showImageMessage:(TUIImageMessageCell *)cell];
    } else if ([cell isKindOfClass:[TUIVideoMessageCell class]]) {
        [self showVideoMessage:(TUIVideoMessageCell *)cell];
    } else if ([cell isKindOfClass:[TUIFileMessageCell class]]) {
        [self showFileMessage:(TUIFileMessageCell *)cell];
    } else if ([cell isKindOfClass:[TUIMergeMessageCell class]]) {
        [self showRelayMessage:(TUIMergeMessageCell *)cell];
    } else if ([cell isKindOfClass:[TUILinkCell class]]) {
        [self showLinkMessage:(TUILinkCell *)cell];
    } else if ([cell isKindOfClass:TUIReplyMessageCell.class]) {
        [self showReplyMessage:(TUIReplyMessageCell *)cell];
    } else if ([cell isKindOfClass:TUIReferenceMessageCell.class]) {
        [self showReplyMessage:(TUIReplyMessageCell *)cell];
    } else if ([cell isKindOfClass:TUIOrderCell.class]) {
        [self showOrderMessage:(TUIOrderCell *)cell];
    }
    
    if ([self.delegate respondsToSelector:@selector(messageController:onSelectMessageContent:)]) {
        [self.delegate messageController:self onSelectMessageContent:cell];
    }
}

- (void)onLongPressMessage:(TUIMessageCell *)cell {
    if (TUIChatConfig.defaultConfig.eventConfig.chatEventListener &&
        [TUIChatConfig.defaultConfig.eventConfig.chatEventListener respondsToSelector:@selector(onMessageLongClicked:messageCellData:)]) {
        BOOL result = [TUIChatConfig.defaultConfig.eventConfig.chatEventListener onMessageLongClicked:cell messageCellData:cell.messageData];
        if (result) {
            return;
        }
    }
    
    [UIApplication.sharedApplication.keyWindow endEditing:NO];
    TUIMessageCellData *data = cell.messageData;
    if (![data canLongPress]) {
        return;
    }
    if ([data isKindOfClass:[TUISystemMessageCellData class]]) {
        return;
    }
    
    self.menuUIMsg = data;
    
    __weak typeof(self) weakSelf = self;
    TUIChatPopMenu *menu = [[TUIChatPopMenu alloc] initWithEmojiView:YES frame:CGRectZero];
    menu.targetCellData = data;
    __weak typeof(menu) weakMenu = menu;
    BOOL isPluginCustomMessage = [TUIMessageCellConfig isPluginCustomMessageCellData:data];
    BOOL isChatNoramlMessageOrCustomMessage = !isPluginCustomMessage;
    
    // Insert Action
    if (isChatNoramlMessageOrCustomMessage) {
        // Chat common Action
        [self addChatCommonActionToCell:cell ofMenu:menu];
    } else {
        // Plugin common Action
        // 多选（multiAction） 引用（quoteAction） 回复（referenceAction） 删除(deleteAction) 撤回(recallAction)
        [self addChatPluginCommonActionToCell:cell ofMenu:menu];
    }
    
    // Actions from extension
    [self addExtensionActionToCell:cell ofMenu:menu];
    
    if ([data isKindOfClass:[TUITextMessageCellData class]]) {
        /**
         * 文本消息选中状态的时候会默认 becomeFirstResponder 导致键盘消失，界面错乱，这里先收起已经弹出的键盘。
         * When the text message is selected, it will becomeFirstResponder by default, causing the keyboard to disappear and the interface to be chaotic. Here,
         * the keyboard that has popped up is put away first.
         */
        TUITextMessageCell *textCell = (TUITextMessageCell *)cell;
        [textCell.textView becomeFirstResponder];
    } else if ([data isKindOfClass:[TUIReferenceMessageCellData class]]) {
        TUIReferenceMessageCell *referenceCell = (TUIReferenceMessageCell *)cell;
        [referenceCell.textView becomeFirstResponder];
    }
    
    BOOL isFirstResponder = NO;
    if (_delegate && [_delegate respondsToSelector:@selector(messageController:willShowMenuInCell:)]) {
        isFirstResponder = [_delegate messageController:self willShowMenuInCell:cell];
    }
    if (isFirstResponder) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
    } else {
        [self becomeFirstResponder];
    }
    
    CGRect frame = [UIApplication.sharedApplication.keyWindow convertRect:cell.container.frame fromView:cell];
    
    CGFloat topMarginiByCustomView = 0;
    
    if (_delegate && [_delegate respondsToSelector:@selector(getTopMarginByCustomView)]) {
        topMarginiByCustomView = [_delegate getTopMarginByCustomView];
    }
    
    [menu setArrawPosition:CGPointMake(frame.origin.x + frame.size.width * 0.5, frame.origin.y - 5 - topMarginiByCustomView)
              adjustHeight:frame.size.height + 5];
    [menu showInView:self.tableView];
    
    [self configSelectActionToCell:cell ofMenu:menu];
}

- (void)addChatCommonActionToCell:(TUIMessageCell *)cell ofMenu:(TUIChatPopMenu *)menu {
    // Setup popAction
    TUIChatPopMenuAction *copyAction = [self setupCopyAction:cell];
    TUIChatPopMenuAction *deleteAction = [self setupDeleteAction:cell];
    TUIChatPopMenuAction *recallAction = [self setupRecallAction:cell];
    TUIChatPopMenuAction *multiAction = [self setupMulitSelectAction:cell];
    TUIChatPopMenuAction *forwardAction = [self setupForwardAction:cell];
    TUIChatPopMenuAction *quoteAction = [self setupQuoteAction:cell];
    TUIChatPopMenuAction *referenceAction = [self setupReferenceAction:cell];
    TUIChatPopMenuAction *audioPlaybackStyleAction = [self setupAudioPlaybackStyleAction:cell];
    
    TUIMessageCellData *data = cell.messageData;
    V2TIMMessage *imMsg = data.innerMessage;
    
    if (imMsg.soundElem) {
        [menu addAction:audioPlaybackStyleAction];
    }
    if ([data isKindOfClass:[TUITextMessageCellData class]] || [data isKindOfClass:TUIReplyMessageCellData.class] ||
        [data isKindOfClass:TUIReferenceMessageCellData.class]) {
        [menu addAction:copyAction];
    }
    [menu addAction:deleteAction];
    [menu addAction:multiAction];
    if (imMsg) {
        if ([imMsg isSelf] && [[NSDate date] timeIntervalSinceDate:imMsg.timestamp] < TUIChatConfig.defaultConfig.timeIntervalForMessageRecall &&
            (imMsg.status == V2TIM_MSG_STATUS_SEND_SUCC)) {
            [menu addAction:recallAction];
        }
    }
    if ([self canForward:data] && imMsg.status == V2TIM_MSG_STATUS_SEND_SUCC && !imMsg.hasRiskContent) {
        [menu addAction:forwardAction];
    }
    if (imMsg.status == V2TIM_MSG_STATUS_SEND_SUCC && [TUIChatConfig defaultConfig].enablePopMenuReplyAction) {
        [menu addAction:quoteAction];
    }
    if (imMsg.status == V2TIM_MSG_STATUS_SEND_SUCC && [TUIChatConfig defaultConfig].enablePopMenuReferenceAction) {
        [menu addAction:referenceAction];
    }
}

- (void)addChatPluginCommonActionToCell:(TUIMessageCell *)cell ofMenu:(TUIChatPopMenu *)menu {
    // Setup popAction
    TUIChatPopMenuAction *deleteAction = [self setupDeleteAction:cell];
    TUIChatPopMenuAction *recallAction = [self setupRecallAction:cell];
    TUIChatPopMenuAction *multiAction = [self setupMulitSelectAction:cell];
    TUIChatPopMenuAction *quoteAction = [self setupQuoteAction:cell];
    TUIChatPopMenuAction *referenceAction = [self setupReferenceAction:cell];

    TUIMessageCellData *data = cell.messageData;
    V2TIMMessage *imMsg = data.innerMessage;

    [menu addAction:multiAction];

    if (imMsg.status == V2TIM_MSG_STATUS_SEND_SUCC && [TUIChatConfig defaultConfig].enablePopMenuReplyAction) {
        [menu addAction:quoteAction];
    }
    if (imMsg.status == V2TIM_MSG_STATUS_SEND_SUCC && [TUIChatConfig defaultConfig].enablePopMenuReferenceAction) {
        [menu addAction:referenceAction];
    }

    [menu addAction:deleteAction];

    if (imMsg && [imMsg isSelf] && [[NSDate date] timeIntervalSinceDate:imMsg.timestamp] < TUIChatConfig.defaultConfig.timeIntervalForMessageRecall &&
        (imMsg.status == V2TIM_MSG_STATUS_SEND_SUCC)) {
        [menu addAction:recallAction];
    }
}
- (void)addExtensionActionToCell:(TUIMessageCell *)cell ofMenu:(TUIChatPopMenu *)menu {
    // extra
    NSArray<TUIExtensionInfo *> *infoArray =
        [TUICore getExtensionList:TUICore_TUIChatExtension_PopMenuActionItem_ClassicExtensionID
                            param:@{TUICore_TUIChatExtension_PopMenuActionItem_TargetVC : self, TUICore_TUIChatExtension_PopMenuActionItem_ClickCell : cell}];
    for (TUIExtensionInfo *info in infoArray) {
        if (info.text && info.icon && info.onClicked) {
            TUIChatPopMenuAction *extension = [[TUIChatPopMenuAction alloc] initWithTitle:info.text
                                                                                    image:info.icon
                                                                                   weight:info.weight
                                                                                 callback:^{
                                                                                   info.onClicked(@{});
                                                                                 }];
            [menu addAction:extension];
        }
    }
}

- (void)configSelectActionToCell:(TUIMessageCell *)cell ofMenu:(TUIChatPopMenu *)menu {
    
    // Setup popAction
    TUIChatPopMenuAction *copyAction = [self setupCopyAction:cell];
    TUIChatPopMenuAction *deleteAction = [self setupDeleteAction:cell];
    TUIChatPopMenuAction *multiAction = [self setupMulitSelectAction:cell];
    TUIChatPopMenuAction *forwardAction = [self setupForwardAction:cell];
    TUIChatPopMenuAction *quoteAction = [self setupQuoteAction:cell];
    TUIChatPopMenuAction *referenceAction = [self setupReferenceAction:cell];
    
    TUIMessageCellData *data = cell.messageData;

    //Chat common Action special operator
    @weakify(self);
    @weakify(cell);
    @weakify(menu);
    __block BOOL isSelectAll = YES;
    void (^selectAllContentCallback)(BOOL) = ^(BOOL selectAll) {
      @strongify(self);
      @strongify(cell);
      @strongify(menu);
      if (isSelectAll == selectAll) {
          return;
      }
      isSelectAll = selectAll;
      [menu removeAllAction];
      if (isSelectAll) {
          [menu addAction:copyAction];
          [menu addAction:deleteAction];
          [menu addAction:multiAction];
          if ([self canForward:data]) {
              [menu addAction:forwardAction];
          }
          if ([TUIChatConfig defaultConfig].enablePopMenuReplyAction) {
              [menu addAction:quoteAction];
          }
          if ([TUIChatConfig defaultConfig].enablePopMenuReferenceAction) {
              [menu addAction:referenceAction];
          }
      } else {
          [menu addAction:copyAction];
          if ([self canForward:data]) {
              [menu addAction:forwardAction];
          }
      }
      // Select all or not may affect the action menu
      [self addExtensionActionToCell:cell ofMenu:menu];
      [menu layoutSubview];
    };
    /**
     * 如果是文本类型消息，设置文本消息光标选中状态，如果文字不是全选状态，只保留复制和转发
     * If it is a text type message, set the text message cursor selected state, if the text is not all selected state, only keep copy and forward
     */
    if ([data isKindOfClass:[TUITextMessageCellData class]]) {
        TUITextMessageCell *textCell = (TUITextMessageCell *)cell;
        [textCell.textView selectAll:self];
        textCell.selectAllContentContent = selectAllContentCallback;
        menu.hideCallback = ^{
          [textCell.textView setSelectedTextRange:nil];
        };
    }
    if ([data isKindOfClass:[TUIReferenceMessageCellData class]] || [data isKindOfClass:[TUIReplyMessageCellData class]]) {
        TUIReplyMessageCell *textCell = (TUIReplyMessageCell *)cell;
        [textCell.textView selectAll:self];
        textCell.selectAllContentContent = selectAllContentCallback;
        menu.hideCallback = ^{
          [textCell.textView setSelectedTextRange:nil];
        };
    };
}
- (TUIChatPopMenuAction *)setupCopyAction:(TUIMessageCell *)cell {
    TUIChatPopMenuAction *copyAction = nil;
    @weakify(self);
    @weakify(cell);
    copyAction = [[TUIChatPopMenuAction alloc] initWithTitle:TIMCommonLocalizableString(Copy)
                                                       image:TUIChatBundleThemeImage(@"chat_icon_copy_img", @"icon_copy")
                                                      weight:10000
                                                    callback:^{
                                                      @strongify(self);
                                                      @strongify(cell);
                                                      [self onCopyMsg:cell];
                                                    }];
    return copyAction;
}
- (TUIChatPopMenuAction *)setupDeleteAction:(TUIMessageCell *)cell {
    @weakify(self);
    TUIChatPopMenuAction *deleteAction = [[TUIChatPopMenuAction alloc] initWithTitle:TIMCommonLocalizableString(Delete)
                                                                               image:TUIChatBundleThemeImage(@"chat_icon_delete_img", @"icon_delete")
                                                                              weight:3000
                                                                            callback:^{
                                                                              @strongify(self);
                                                                              [self onDelete:nil];
                                                                            }];
    return deleteAction;
}

- (TUIChatPopMenuAction *)setupRecallAction:(TUIMessageCell *)cell {
    TUIChatPopMenuAction *recallAction = nil;
    TUIMessageCellData *data = cell.messageData;
    V2TIMMessage *imMsg = data.innerMessage;
    @weakify(self);
    recallAction = [[TUIChatPopMenuAction alloc] initWithTitle:TIMCommonLocalizableString(Revoke)
                                                         image:TUIChatBundleThemeImage(@"chat_icon_recall_img", @"icon_recall")
                                                        weight:4000
                                                      callback:^{
                                                        @strongify(self);
                                                        [self onRevoke:nil];
                                                      }];

    return recallAction;
}
- (TUIChatPopMenuAction *)setupMulitSelectAction:(TUIMessageCell *)cell {
    @weakify(self);
    TUIChatPopMenuAction *multiAction = nil;
    multiAction = [[TUIChatPopMenuAction alloc] initWithTitle:TIMCommonLocalizableString(Multiple)
                                                        image:TUIChatBundleThemeImage(@"chat_icon_multi_img", @"icon_multi")
                                                       weight:8000
                                                     callback:^{
                                                       @strongify(self);
                                                       [self onMulitSelect:nil];
                                                     }];

    return multiAction;
}

- (TUIChatPopMenuAction *)setupForwardAction:(TUIMessageCell *)cell {
    @weakify(self);
    TUIChatPopMenuAction *forwardAction = nil;
    forwardAction = [[TUIChatPopMenuAction alloc] initWithTitle:TIMCommonLocalizableString(Forward)
                                                          image:TUIChatBundleThemeImage(@"chat_icon_forward_img", @"icon_forward")
                                                         weight:9000
                                                       callback:^{
                                                         @strongify(self);
                                                         [self onForward:nil];
                                                       }];
    return forwardAction;
}

- (TUIChatPopMenuAction *)setupQuoteAction:(TUIMessageCell *)cell {
    @weakify(self);
    TUIChatPopMenuAction *quoteAction = nil;
    quoteAction = [[TUIChatPopMenuAction alloc] initWithTitle:TIMCommonLocalizableString(Reply)
                                                        image:TUIChatBundleThemeImage(@"chat_icon_reply_img", @"icon_reply")
                                                       weight:5000
                                                     callback:^{
                                                       @strongify(self);
                                                       [self onReply:nil];
                                                     }];
    return quoteAction;
}

- (TUIChatPopMenuAction *)setupReferenceAction:(TUIMessageCell *)cell {
    @weakify(self);
    TUIChatPopMenuAction *referenceAction = nil;
    referenceAction = [[TUIChatPopMenuAction alloc] initWithTitle:TIMCommonLocalizableString(TUIKitReference)
                                                            image:TUIChatBundleThemeImage(@"chat_icon_reference_img", @"icon_reference")
                                                           weight:7000
                                                         callback:^{
                                                           @strongify(self);
                                                           [self onReference:nil];
                                                         }];
    return referenceAction;
}

- (TUIChatPopMenuAction *)setupAudioPlaybackStyleAction:(TUIMessageCell *)cell {
    @weakify(self);
    TUIChatPopMenuAction *audioPlaybackStyleAction = nil;
    __weak typeof(audioPlaybackStyleAction)  weakAction = audioPlaybackStyleAction;
    TUIVoiceAudioPlaybackStyle originStyle = [TUIVoiceMessageCellData getAudioplaybackStyle];
    NSString *title = @"";
    UIImage *img = nil;
    if (originStyle == TUIVoiceAudioPlaybackStyleLoudspeaker) {
        title = TIMCommonLocalizableString(TUIKitAudioPlaybackStyleHandset);
        img   = TUIChatBundleThemeImage(@"chat_icon_audio_handset_img", @"icon_handset");
    }
    else {
        title = TIMCommonLocalizableString(TUIKitAudioPlaybackStyleLoudspeaker);
        img   = TUIChatBundleThemeImage(@"chat_icon_audio_loudspeaker_img", @"icon_loudspeaker");
    }
    
    audioPlaybackStyleAction = [[TUIChatPopMenuAction alloc] initWithTitle:title
                                                            image:img
                                                           weight:11000
                                                         callback:^{
        if (originStyle == TUIVoiceAudioPlaybackStyleLoudspeaker) {
            //Change To Handset
            weakAction.title = TIMCommonLocalizableString(TUIKitAudioPlaybackStyleLoudspeaker);
            [TUITool hideToast];
            [TUITool makeToast:TIMCommonLocalizableString(TUIKitAudioPlaybackStyleChange2Handset) duration:2];
        }
        else {
            weakAction.title = TIMCommonLocalizableString(TUIKitAudioPlaybackStyleHandset);
            [TUITool hideToast];
            [TUITool makeToast:TIMCommonLocalizableString(TUIKitAudioPlaybackStyleChange2Loudspeaker) duration:2];
        }
        [TUIVoiceMessageCellData changeAudioPlaybackStyle];

    }];
    return audioPlaybackStyleAction;
}
- (BOOL)canForward:(TUIMessageCellData *)data {
    return ![TUIMessageCellConfig isPluginCustomMessageCellData:data];
}

- (void)onLongSelectMessageAvatar:(TUIMessageCell *)cell {    
    if (TUIChatConfig.defaultConfig.eventConfig.chatEventListener &&
    [TUIChatConfig.defaultConfig.eventConfig.chatEventListener respondsToSelector:@selector(onUserIconLongClicked:messageCellData:)]) {
        BOOL result = [TUIChatConfig.defaultConfig.eventConfig.chatEventListener onUserIconLongClicked:cell messageCellData:cell.messageData];
        if (result) {
            return;
        }
    }

    if (_delegate && [_delegate respondsToSelector:@selector(messageController:onLongSelectMessageAvatar:)]) {
        [_delegate messageController:self onLongSelectMessageAvatar:cell];
    }
}

- (void)onRetryMessage:(TUIMessageCell *)cell {
    _reSendUIMsg = cell.messageData;
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:TIMCommonLocalizableString(TUIKitTipsConfirmResendMessage)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert tuitheme_addAction:[UIAlertAction actionWithTitle:TIMCommonLocalizableString(Re_send)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *_Nonnull action) {
                                                       [weakSelf sendUIMessage:weakSelf.reSendUIMsg];
                                                     }]];
    [alert tuitheme_addAction:[UIAlertAction actionWithTitle:TIMCommonLocalizableString(Cancel)
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *_Nonnull action){

                                                     }]];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)onSelectMessageAvatar:(TUIMessageCell *)cell {
    if (TUIChatConfig.defaultConfig.eventConfig.chatEventListener &&
        [TUIChatConfig.defaultConfig.eventConfig.chatEventListener respondsToSelector:@selector(onUserIconClicked:messageCellData:)]) {
       BOOL result = [TUIChatConfig.defaultConfig.eventConfig.chatEventListener onUserIconClicked:cell messageCellData:cell.messageData];
        if (result) {
            return;
        }
    }
    if ([self.delegate respondsToSelector:@selector(messageController:onSelectMessageAvatar:)]) {
        [self.delegate messageController:self onSelectMessageAvatar:cell];
    }
}

- (void)onSelectReadReceipt:(TUIMessageCellData *)data {
    @weakify(self);
    if (data.innerMessage.groupID.length > 0) {
        // Navigate to group message read VC. Should get members first.
        [TUIMessageDataProvider getMessageReadReceipt:@[ data.innerMessage ]
            succ:^(NSArray<V2TIMMessageReceipt *> *receiptList) {
              @strongify(self);
              if (receiptList.count == 0) {
                  return;
              }
              // To avoid the labels in messageReadVC displaying all 0 which is not accurate, try to get message read count before navigation.
              V2TIMMessageReceipt *receipt = receiptList.firstObject;
              data.messageReceipt = receipt;
              [self pushMessageReadViewController:data];
            }
            fail:^(int code, NSString *desc) {
              @strongify(self);
              [self pushMessageReadViewController:data];
            }];
    } else {
        // navigate to c2c message read VC. No need to get member.
        [self pushMessageReadViewController:data];
    }
}

- (void)pushMessageReadViewController:(TUIMessageCellData *)data {
    self.hasCoverPage = YES;
    TUIMessageReadViewController *controller = [[TUIMessageReadViewController alloc] initWithCellData:data
                                                                                         dataProvider:self.messageDataProvider
                                                                                showReadStatusDisable:NO
                                                                                      c2cReceiverName:self.conversationData.title
                                                                                    c2cReceiverAvatar:self.conversationData.faceUrl];
    [self.navigationController pushViewController:controller animated:YES];
    __weak typeof(self) weakSelf = self;
    controller.viewWillDismissHandler = ^{
        weakSelf.hasCoverPage = NO;
    };
}

- (void)onJumpToRepliesDetailPage:(TUIMessageCellData *)data {
    self.hasCoverPage = YES;
    TUIRepliesDetailViewController *repliesDetailVC = [[TUIRepliesDetailViewController alloc] initWithCellData:data conversationData:self.conversationData];
    repliesDetailVC.delegate = self.delegate;
    [self.navigationController pushViewController:repliesDetailVC animated:YES];
    repliesDetailVC.parentPageDataProvider = self.messageDataProvider;
    __weak typeof(self) weakSelf = self;
    repliesDetailVC.willCloseCallback = ^() {
      [weakSelf.tableView reloadData];
      weakSelf.hasCoverPage = NO;
    };
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(onDelete:) || action == @selector(onRevoke:) || action == @selector(onReSend:) || action == @selector(onCopyMsg:) ||
        action == @selector(onMulitSelect:) || action == @selector(onForward:) || action == @selector(onReply:)) {
        return YES;
    }
    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder API_AVAILABLE(ios(13.0)) {
    if (@available(iOS 16.0, *)) {
        [builder removeMenuForIdentifier:UIMenuLookup];
    }
    [super buildMenuWithBuilder:builder];
}

- (void)onDelete:(id)sender {
    @weakify(self);
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil
                                                                message:TIMCommonLocalizableString(ConfirmDeleteMessage)
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
    [vc tuitheme_addAction:[UIAlertAction actionWithTitle:TIMCommonLocalizableString(Delete)
                                                    style:UIAlertActionStyleDestructive
                                                  handler:^(UIAlertAction *_Nonnull action) {
                                                    @strongify(self);
                                                    [self.messageDataProvider deleteUIMsgs:@[ self.menuUIMsg ]
                                                                                 SuccBlock:nil
                                                                                 FailBlock:^(int code, NSString *desc) {
                                                                                   NSLog(@"remove msg failed!");
                                                                                   NSAssert(NO, desc);
                                                                                 }];
                                                  }]];
    [vc tuitheme_addAction:[UIAlertAction actionWithTitle:TIMCommonLocalizableString(Cancel) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)menuDidHide:(NSNotification *)notification {
    if (_delegate && [_delegate respondsToSelector:@selector(didHideMenuInMessageController:)]) {
        [_delegate didHideMenuInMessageController:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)onCopyMsg:(id)sender {
    NSString *content = @"";
    /**
     * 文本消息要以光标实际选中的消息内容为准
     * The text message should be based on the content of the message actually selected by the cursor
     */
    if ([sender isKindOfClass:[TUITextMessageCell class]]) {
        TUITextMessageCell *txtCell = (TUITextMessageCell *)sender;
        content = txtCell.selectContent;
    }
    if ([sender isKindOfClass:TUIReplyMessageCell.class] || [sender isKindOfClass:TUIReferenceMessageCell.class]) {
        TUIReplyMessageCellData *replyMsg = (TUIReplyMessageCellData *)sender;
        content = replyMsg.selectContent;
    }
    if (content.length > 0) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = content;
        [TUITool makeToast:TIMCommonLocalizableString(Copied)];
    }
}

- (void)onRevoke:(id)sender {
    @weakify(self);
    [self.messageDataProvider revokeUIMsg:self.menuUIMsg
        SuccBlock:^{
          @strongify(self);
          if (self.delegate && [self.delegate respondsToSelector:@selector(didHideMenuInMessageController:)]) {
              [self.delegate didHideMenuInMessageController:self];
          }
        }
        FailBlock:^(int code, NSString *desc) {
          NSAssert(NO, desc);
        }];
}

- (void)onReSend:(id)sender {
    [self sendUIMessage:_menuUIMsg];
}

- (void)onMulitSelect:(id)sender {
    [self enableMultiSelectedMode:YES];
    if (self.menuUIMsg.innerMessage.hasRiskContent) {
        if (_delegate && [_delegate respondsToSelector:@selector(messageController:onSelectMessageMenu:withData:)]) {
            [_delegate messageController:self onSelectMessageMenu:0 withData:nil];
        }
        return;
    }
    self.menuUIMsg.selected = YES;
    [self.tableView beginUpdates];
    NSInteger index = [self.messageDataProvider.uiMsgs indexOfObject:self.menuUIMsg];
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];

    if (_delegate && [_delegate respondsToSelector:@selector(messageController:onSelectMessageMenu:withData:)]) {
        [_delegate messageController:self onSelectMessageMenu:0 withData:_menuUIMsg];
    }
}

- (void)onForward:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(messageController:onSelectMessageMenu:withData:)]) {
        [_delegate messageController:self onSelectMessageMenu:1 withData:_menuUIMsg];
    }
}

- (void)onReply:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(messageController:onRelyMessage:)]) {
        [_delegate messageController:self onRelyMessage:self.menuUIMsg];
    }
}

- (void)onReference:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(messageController:onReferenceMessage:)]) {
        [_delegate messageController:self onReferenceMessage:self.menuUIMsg];
    }
}

- (BOOL)supportCheckBox:(TUIMessageCellData *)data {
    if ([data isKindOfClass:TUISystemMessageCellData.class]) {
        return NO;
    }
    return YES;
}

- (BOOL)supportRelay:(TUIMessageCellData *)data {
    if ([data isKindOfClass:TUIVoiceMessageCellData.class]) {
        return NO;
    }
    return YES;
}

- (void)enableMultiSelectedMode:(BOOL)enable {
    self.showCheckBox = enable;
    if (!enable) {
        for (TUIMessageCellData *cellData in self.messageDataProvider.uiMsgs) {
            cellData.selected = NO;
        }
    }
    [self.tableView reloadData];
}

- (NSArray<TUIMessageCellData *> *)multiSelectedResult:(TUIMultiResultOption)option {
    NSMutableArray *arrayM = [NSMutableArray array];
    if (!self.showCheckBox) {
        return [NSArray arrayWithArray:arrayM];
    }
    BOOL filterUnsupported = option & TUIMultiResultOptionFiterUnsupportRelay;
    for (TUIMessageCellData *data in self.messageDataProvider.uiMsgs) {
        if (data.selected) {
            if (filterUnsupported && ![self supportRelay:data]) {
                continue;
            }
            [arrayM addObject:data];
        }
    }
    return [NSArray arrayWithArray:arrayM];
}

- (void)deleteMessages:(NSArray<TUIMessageCellData *> *)uiMsgs {
    if (uiMsgs.count == 0 || uiMsgs.count > 30) {
        NSLog(@"The size of messages must be between 0 and 30");
        return;
    }
    [self.messageDataProvider deleteUIMsgs:uiMsgs
                                 SuccBlock:nil
                                 FailBlock:^(int code, NSString *desc) {
                                   NSLog(@"deleteMessages failed!");
                                   NSAssert(NO, desc);
                                 }];
}

- (void)clickTextMessage:(TUITextMessageCell *)cell {
    V2TIMMessage *message = cell.messageData.innerMessage;
    if (0 == message.userID.length) {
        return;
    }
    [TUIMessageDataProvider.callingDataProvider redialFromMessage:message];
}

- (void)clickSystemMessage:(TUISystemMessageCell *)cell {
    TUISystemMessageCellData *data = (TUISystemMessageCellData *)cell.messageData;
    if (data.supportReEdit) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(messageController:onReEditMessage:)]) {
            [self.delegate messageController:self onReEditMessage:cell.messageData];
        }
    }
}

- (void)playVoiceMessage:(TUIVoiceMessageCell *)cell {
    for (TUIMessageCellData *cellData in self.messageDataProvider.uiMsgs) {
        if (![cellData isKindOfClass:[TUIVoiceMessageCellData class]]) {
            continue;
        }
        TUIVoiceMessageCellData *voiceMsg = (TUIVoiceMessageCellData *)cellData;
        if (voiceMsg == cell.voiceData) {
            [voiceMsg playVoiceMessage];
            cell.voiceReadPoint.hidden = YES;
            NSMutableArray *unPlayVoiceMessageAfterSelectVoiceMessage = [self getCurrentUnPlayVoiceMessageAfterSelectVoiceMessage:voiceMsg];
            @weakify(self);
            voiceMsg.audioPlayerDidFinishPlayingBlock = ^{
              @strongify(self);
              if (unPlayVoiceMessageAfterSelectVoiceMessage.count > 0) {
                  TUIVoiceMessageCellData *nextVoiceCellData = [unPlayVoiceMessageAfterSelectVoiceMessage firstObject];
                  NSIndexPath *nextIndex = [self indexPathOfMessage:nextVoiceCellData.msgID];
                  [self scrollCellToBottomOfMessage:nextVoiceCellData.msgID];
                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    TUIVoiceMessageCell *nextCell = [self.tableView cellForRowAtIndexPath:nextIndex];
                    if (nextCell) {
                        [self playVoiceMessage:nextCell];
                        [unPlayVoiceMessageAfterSelectVoiceMessage removeObject:nextVoiceCellData];
                    } else {
                        // rerty: avoid nextCell is nil
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                          TUIVoiceMessageCell *retryNextCell = [self.tableView cellForRowAtIndexPath:nextIndex];
                          if (retryNextCell) {
                              [self playVoiceMessage:retryNextCell];
                              [unPlayVoiceMessageAfterSelectVoiceMessage removeObject:nextVoiceCellData];
                          }
                        });
                    }
                  });
              }
            };
        } else {
            [voiceMsg stopVoiceMessage];
        }
    }
}

- (NSMutableArray *)getCurrentUnPlayVoiceMessageAfterSelectVoiceMessage:(TUIVoiceMessageCellData *)playingCellData {
    NSMutableArray *neverHitsPlayVoiceQueue = [NSMutableArray array];
    for (TUIMessageCellData *cellData in self.messageDataProvider.uiMsgs) {
        if ([cellData isKindOfClass:[TUIVoiceMessageCellData class]]) {
            TUIVoiceMessageCellData *voiceMsg = (TUIVoiceMessageCellData *)cellData;
            if ((voiceMsg.innerMessage.localCustomInt == 0 && voiceMsg.direction == MsgDirectionIncoming &&
                 [voiceMsg.innerMessage.timestamp timeIntervalSince1970] >= [playingCellData.innerMessage.timestamp timeIntervalSince1970])) {
                if (voiceMsg != playingCellData) {
                    [neverHitsPlayVoiceQueue addObject:voiceMsg];
                }
            }
        }
    }
    return neverHitsPlayVoiceQueue;
}
- (void)showImageMessage:(TUIImageMessageCell *)cell {
    [self hideKeyboardIfNeeded];
    CGRect frame = [cell.thumb convertRect:cell.thumb.bounds toView:[UIApplication sharedApplication].delegate.window];
    TUIMediaView *mediaView = [[TUIMediaView alloc] initWithFrame:CGRectMake(0, 0, Screen_Width, Screen_Height)];
    [mediaView setThumb:cell.thumb frame:frame];
    [mediaView setCurMessage:cell.messageData.innerMessage];
    __weak typeof(self) weakSelf = self;
    mediaView.onClose = ^{
      [weakSelf didCloseMediaMessage:cell];
    };
    [self willShowMediaMessage:cell];
    [[UIApplication sharedApplication].keyWindow addSubview:mediaView];
}

- (void)showVideoMessage:(TUIVideoMessageCell *)cell {
    if (![cell.videoData isVideoExist]) {
        [cell.videoData downloadVideo];
    } else {
        [self hideKeyboardIfNeeded];
        CGRect frame = [cell.thumb convertRect:cell.thumb.bounds toView:[UIApplication sharedApplication].delegate.window];
        TUIMediaView *mediaView = [[TUIMediaView alloc] initWithFrame:CGRectMake(0, 0, Screen_Width, Screen_Height)];
        [mediaView setThumb:cell.thumb frame:frame];
        [mediaView setCurMessage:cell.messageData.innerMessage];
        __weak typeof(self) weakSelf = self;
        mediaView.onClose = ^{
          [weakSelf didCloseMediaMessage:cell];
        };
        [self willShowMediaMessage:cell];
        [[UIApplication sharedApplication].keyWindow addSubview:mediaView];
    }
}

- (void)showFileMessage:(TUIFileMessageCell *)cell {
    [self hideKeyboardIfNeeded];
    TUIFileMessageCellData *fileData = cell.fileData;
    if (![fileData isLocalExist]) {
        [fileData downloadFile];
        return;
    }

    TUIFileViewController *file = [[TUIFileViewController alloc] init];
    file.data = [cell fileData];
    [self.navigationController pushViewController:file animated:YES];
}

- (void)showRelayMessage:(TUIMergeMessageCell *)cell {
    TUIMergeMessageListController *relayVc = [[TUIMergeMessageListController alloc] init];
    relayVc.delegate = self.delegate;
    relayVc.mergerElem = cell.relayData.mergerElem;
    relayVc.conversationData = self.conversationData;
    relayVc.parentPageDataProvider = self.messageDataProvider;
    __weak typeof(self) weakSelf = self;
    relayVc.willCloseCallback = ^() {
      [weakSelf.tableView reloadData];
    };
    [self.navigationController pushViewController:relayVc animated:YES];
}

- (void)showLinkMessage:(TUILinkCell *)cell {
    TUILinkCellData *cellData = cell.customData;
    if (cellData.link) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cellData.link]];
    }
}

- (void)showOrderMessage:(TUIOrderCell *)cell {
    TUIOrderCellData *cellData = cell.customData;
    if (cellData.link) {
        [TUITool openLinkWithURL:[NSURL URLWithString:cellData.link]];
    }
}

- (void)showReplyMessage:(TUIReplyMessageCell *)cell {
}

- (void)willShowMediaMessage:(TUIMessageCell *)cell {
}

- (void)didCloseMediaMessage:(TUIMessageCell *)cell {
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (@available(iOS 16.0, *)) {
        // send reloadview
        [[NSNotificationCenter defaultCenter] postNotificationName:TUIMessageMediaViewDeviceOrientationChangeNotification object:nil];
    } else {
        // Fallback on earlier versions
    }
}

@end
