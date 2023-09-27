
//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

#import <TIMCommon/TIMCommonModel.h>
#import <TIMCommon/TIMDefine.h>
#import "TIMGroupInfo+TUIDataProvider.h"
#import "TUIGroupInfoDataProvider.h"
#import "TUIGroupMemberCellData.h"
#import "TUIGroupMembersCellData.h"
#import "TUIGroupNoticeCell.h"

@interface TUIGroupInfoDataProvider () <V2TIMGroupListener>
@property(nonatomic, strong) TUICommonTextCellData *addOptionData;
@property(nonatomic, strong) TUICommonTextCellData *inviteOptionData;
@property(nonatomic, strong) TUICommonTextCellData *groupNickNameCellData;
@property(nonatomic, strong, readwrite) TUIProfileCardCellData *profileCellData;
@property(nonatomic, strong) V2TIMGroupMemberFullInfo *selfInfo;
@property(nonatomic, strong) NSString *groupID;
@end

@implementation TUIGroupInfoDataProvider

- (instancetype)initWithGroupID:(NSString *)groupID {
    self = [super init];
    if (self) {
        self.groupID = groupID;
        [[V2TIMManager sharedInstance] addGroupListener:self];
    }
    return self;
}

#pragma mark V2TIMGroupListener
- (void)onMemberEnter:(NSString *)groupID memberList:(NSArray<V2TIMGroupMemberInfo *> *)memberList {
    [self loadData];
}

- (void)onMemberLeave:(NSString *)groupID member:(V2TIMGroupMemberInfo *)member {
    [self loadData];
}

- (void)onMemberInvited:(NSString *)groupID opUser:(V2TIMGroupMemberInfo *)opUser memberList:(NSArray<V2TIMGroupMemberInfo *> *)memberList {
    [self loadData];
}

- (void)onMemberKicked:(NSString *)groupID opUser:(V2TIMGroupMemberInfo *)opUser memberList:(NSArray<V2TIMGroupMemberInfo *> *)memberList {
    [self loadData];
}

- (void)onGroupInfoChanged:(NSString *)groupID changeInfoList:(NSArray<V2TIMGroupChangeInfo *> *)changeInfoList {
    if (![groupID isEqualToString:self.groupID]) {
        return;
    }

    [self loadData];
}

- (void)loadData {
    if (self.groupID.length == 0) {
        [TUITool makeToastError:ERR_INVALID_PARAMETERS msg:@"invalid groupID"];
        return;
    }
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self getGroupInfo:^{
      dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [self getGroupMembers:^{
      dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [self getSelfInfoInGroup:^{
      dispatch_group_leave(group);
    }];

    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
      [weakSelf setupData];
    });
}

- (void)updateGroupInfo {
    @weakify(self);
    [[V2TIMManager sharedInstance] getGroupsInfo:@[ self.groupID ]
        succ:^(NSArray<V2TIMGroupInfoResult *> *groupResultList) {
          @strongify(self);
          if (groupResultList.count == 1) {
              self.groupInfo = groupResultList[0].info;
              [self setupData];
          }
        }
        fail:^(int code, NSString *msg) {
          [TUITool makeToastError:code msg:msg];
        }];
}

- (void)transferGroupOwner:(NSString *)groupID member:(NSString *)userID succ:(V2TIMSucc)succ fail:(V2TIMFail)fail {
    [V2TIMManager.sharedInstance transferGroupOwner:groupID
        member:userID
        succ:^{
          succ();
        }
        fail:^(int code, NSString *desc) {
          fail(code, desc);
        }];
}

- (void)updateGroupAvatar:(NSString *)url succ:(V2TIMSucc)succ fail:(V2TIMFail)fail {
    V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
    info.groupID = self.groupID;
    info.faceURL = url;
    [V2TIMManager.sharedInstance setGroupInfo:info succ:succ fail:fail];
}

- (void)getGroupInfo:(dispatch_block_t)callback {
    __weak typeof(self) weakSelf = self;
    [[V2TIMManager sharedInstance] getGroupsInfo:@[ self.groupID ]
        succ:^(NSArray<V2TIMGroupInfoResult *> *groupResultList) {
          weakSelf.groupInfo = groupResultList.firstObject.info;
          if (callback) {
              callback();
          }
        }
        fail:^(int code, NSString *msg) {
          if (callback) {
              callback();
          }
          [TUITool makeToastError:code msg:msg];
        }];
}

- (void)getGroupMembers:(dispatch_block_t)callback {
    __weak typeof(self) weakSelf = self;
    [[V2TIMManager sharedInstance] getGroupMemberList:self.groupID
        filter:V2TIM_GROUP_MEMBER_FILTER_ALL
        nextSeq:0
        succ:^(uint64_t nextSeq, NSArray<V2TIMGroupMemberFullInfo *> *memberList) {
          NSMutableArray *membersData = [NSMutableArray array];
          for (V2TIMGroupMemberFullInfo *fullInfo in memberList) {
              TUIGroupMemberCellData *data = [[TUIGroupMemberCellData alloc] init];
              data.identifier = fullInfo.userID;
              data.name = fullInfo.userID;
              data.avatarUrl = fullInfo.faceURL;
              if (fullInfo.nameCard.length > 0) {
                  data.name = fullInfo.nameCard;
              } else if (fullInfo.friendRemark.length > 0) {
                  data.name = fullInfo.friendRemark;
              } else if (fullInfo.nickName.length > 0) {
                  data.name = fullInfo.nickName;
              }
              [membersData addObject:data];
          }
          weakSelf.membersData = membersData;
          if (callback) {
              callback();
          }
        }
        fail:^(int code, NSString *msg) {
          [TUITool makeToastError:code msg:msg];
          if (callback) {
              callback();
          }
        }];
}

- (void)getSelfInfoInGroup:(dispatch_block_t)callback {
    NSString *loginUserID = [[V2TIMManager sharedInstance] getLoginUser];
    if (loginUserID.length == 0) {
        if (callback) {
            callback();
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[V2TIMManager sharedInstance] getGroupMembersInfo:self.groupID
        memberList:@[ loginUserID ]
        succ:^(NSArray<V2TIMGroupMemberFullInfo *> *memberList) {
          for (V2TIMGroupMemberFullInfo *item in memberList) {
              if ([item.userID isEqualToString:loginUserID]) {
                  weakSelf.selfInfo = item;
                  break;
              }
          }
          if (callback) {
              callback();
          }
        }
        fail:^(int code, NSString *desc) {
          [TUITool makeToastError:code msg:desc];
          if (callback) {
              callback();
          }
        }];
}

- (void)setupData {
    NSMutableArray *dataList = [NSMutableArray array];
    if (self.groupInfo) {
        NSMutableArray *commonArray = [NSMutableArray array];
        TUIProfileCardCellData *commonData = [[TUIProfileCardCellData alloc] init];
        commonData.avatarImage = DefaultGroupAvatarImageByGroupType(self.groupInfo.groupType);
        commonData.avatarUrl = [NSURL URLWithString:self.groupInfo.faceURL];
        commonData.name = self.groupInfo.groupName;
        commonData.identifier = self.groupInfo.groupID;
        commonData.signature = self.groupInfo.notification;

        if ([TUIGroupInfoDataProvider isMeOwner:self.groupInfo] || [self.groupInfo isPrivate]) {
            commonData.cselector = @selector(didSelectCommon);
            commonData.showAccessory = YES;
        }
        self.profileCellData = commonData;

        [commonArray addObject:commonData];
        [dataList addObject:commonArray];

        NSMutableArray *memberArray = [NSMutableArray array];
        TUICommonTextCellData *countData = [[TUICommonTextCellData alloc] init];
        countData.key = TIMCommonLocalizableString(TUIKitGroupProfileMember);
        countData.value = [NSString stringWithFormat:TIMCommonLocalizableString(TUIKitGroupProfileMemberCount), self.groupInfo.memberCount];
        countData.cselector = @selector(didSelectMembers);
        countData.showAccessory = YES;
        [memberArray addObject:countData];

        NSMutableArray *tmpArray = [self getShowMembers:self.membersData];
        TUIGroupMembersCellData *membersData = [[TUIGroupMembersCellData alloc] init];
        membersData.members = tmpArray;
        [memberArray addObject:membersData];
        self.groupMembersCellData = membersData;
        [dataList addObject:memberArray];

        // group info
        NSMutableArray *groupInfoArray = [NSMutableArray array];

        TUIGroupNoticeCellData *notice = [[TUIGroupNoticeCellData alloc] init];
        notice.name = TIMCommonLocalizableString(TUIKitGroupNotice);
        notice.desc = self.groupInfo.notification ?: TIMCommonLocalizableString(TUIKitGroupNoticeNull);
        notice.target = self;
        notice.selector = @selector(didSelectNotice);
        [groupInfoArray addObject:notice];

        TUICommonTextCellData *manageData = [[TUICommonTextCellData alloc] init];
        manageData.key = TIMCommonLocalizableString(TUIKitGroupProfileManage);
        manageData.value = @"";
        manageData.showAccessory = YES;
        manageData.cselector = @selector(didSelectGroupManage);
        if (([TUIGroupInfoDataProvider isMeOwner:self.groupInfo])) {
            [groupInfoArray addObject:manageData];
        }

        TUICommonTextCellData *typeData = [[TUICommonTextCellData alloc] init];
        typeData.key = TIMCommonLocalizableString(TUIKitGroupProfileType);
        typeData.value = [TUIGroupInfoDataProvider getGroupTypeName:self.groupInfo];
        [groupInfoArray addObject:typeData];

        TUICommonTextCellData *addOptionData = [[TUICommonTextCellData alloc] init];
        addOptionData.key = TIMCommonLocalizableString(TUIKitGroupProfileJoinType);

        if ([self.groupInfo.groupType isEqualToString:@"Work"]) {
            addOptionData.value = TIMCommonLocalizableString(TUIKitGroupProfileInviteJoin);
        } else if ([self.groupInfo.groupType isEqualToString:@"Meeting"]) {
            addOptionData.value = TIMCommonLocalizableString(TUIKitGroupProfileAutoApproval);
        } else {
            if ([TUIGroupInfoDataProvider isMeOwner:self.groupInfo]) {
                addOptionData.cselector = @selector(didSelectAddOption:);
                addOptionData.showAccessory = YES;
            }
            addOptionData.value = [TUIGroupInfoDataProvider getAddOption:self.groupInfo];
        }
        [groupInfoArray addObject:addOptionData];
        self.addOptionData = addOptionData;

        TUICommonTextCellData *inviteOptionData = [[TUICommonTextCellData alloc] init];
        inviteOptionData.key = TIMCommonLocalizableString(TUIKitGroupProfileInviteType);
        if ([TUIGroupInfoDataProvider isMeOwner:self.groupInfo]) {
            inviteOptionData.cselector = @selector(didSelectAddOption:);
            inviteOptionData.showAccessory = YES;
        }
        inviteOptionData.value = [TUIGroupInfoDataProvider getApproveOption:self.groupInfo];
        [groupInfoArray addObject:inviteOptionData];
        self.inviteOptionData = inviteOptionData;
        [dataList addObject:groupInfoArray];

        // personal info
        TUICommonTextCellData *nickData = [[TUICommonTextCellData alloc] init];
        nickData.key = TIMCommonLocalizableString(TUIKitGroupProfileAlias);
        nickData.value = self.selfInfo.nameCard;
        nickData.cselector = @selector(didSelectGroupNick:);
        nickData.showAccessory = YES;
        self.groupNickNameCellData = nickData;
        [dataList addObject:@[ nickData ]];

        NSMutableArray *personalArray = [NSMutableArray array];

        TUICommonSwitchCellData *messageSwitchData = [[TUICommonSwitchCellData alloc] init];

        if (![self.groupInfo.groupType isEqualToString:GroupType_Meeting]) {
            messageSwitchData.on = (self.groupInfo.recvOpt == V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE);
            messageSwitchData.title = TIMCommonLocalizableString(TUIKitGroupProfileMessageDoNotDisturb);
            messageSwitchData.cswitchSelector = @selector(didSelectOnNotDisturb:);
            [personalArray addObject:messageSwitchData];
        }

        TUICommonSwitchCellData *markFold = [[TUICommonSwitchCellData alloc] init];

        TUICommonSwitchCellData *switchData = [[TUICommonSwitchCellData alloc] init];

        markFold.title = TIMCommonLocalizableString(TUIKitConversationMarkFold);

        markFold.displaySeparatorLine = YES;

        markFold.cswitchSelector = @selector(didSelectOnFoldConversation:);
        if (messageSwitchData.on) {
            [personalArray addObject:markFold];
        }

        switchData.title = TIMCommonLocalizableString(TUIKitGroupProfileStickyOnTop);
        [personalArray addObject:switchData];

        [dataList addObject:personalArray];

        TUICommonTextCellData *changeBackgroundImageItem = [[TUICommonTextCellData alloc] init];
        changeBackgroundImageItem.key = TIMCommonLocalizableString(ProfileSetBackgroundImage);
        changeBackgroundImageItem.cselector = @selector(didSelectOnChangeBackgroundImage:);
        changeBackgroundImageItem.showAccessory = YES;
        [dataList addObject:@[ changeBackgroundImageItem ]];

        NSMutableArray *buttonArray = [NSMutableArray array];
        TUIButtonCellData *clearHistory = [[TUIButtonCellData alloc] init];
        clearHistory.title = TIMCommonLocalizableString(TUIKitClearAllChatHistory);
        clearHistory.style = ButtonRedText;
        clearHistory.cbuttonSelector = @selector(didClearAllHistory:);
        [buttonArray addObject:clearHistory];

        TUIButtonCellData *quitButton = [[TUIButtonCellData alloc] init];
        quitButton.title = TIMCommonLocalizableString(TUIKitGroupProfileDeleteAndExit);
        quitButton.style = ButtonRedText;
        quitButton.cbuttonSelector = @selector(didDeleteGroup:);
        [buttonArray addObject:quitButton];

        if ([self.class isMeSuper:self.groupInfo]) {
            TUIButtonCellData *transferButton = [[TUIButtonCellData alloc] init];
            transferButton.title = TIMCommonLocalizableString(TUIKitGroupTransferOwner);
            transferButton.style = ButtonRedText;
            transferButton.cbuttonSelector = @selector(didTransferGroup:);
            [buttonArray addObject:transferButton];
        }

        if ([self.groupInfo canDismissGroup]) {
            TUIButtonCellData *deletebutton = [[TUIButtonCellData alloc] init];
            deletebutton.title = TIMCommonLocalizableString(TUIKitGroupProfileDissolve);
            deletebutton.style = ButtonRedText;
            deletebutton.cbuttonSelector = @selector(didDeleteGroup:);
            [buttonArray addObject:deletebutton];
        }

        TUIButtonCellData *lastCellData = [buttonArray lastObject];
        lastCellData.hideSeparatorLine = YES;
        [dataList addObject:buttonArray];

#ifndef SDKPlaceTop
#define SDKPlaceTop
#endif
#ifdef SDKPlaceTop
        @weakify(self);
        [V2TIMManager.sharedInstance getConversation:[NSString stringWithFormat:@"group_%@", self.groupID]
            succ:^(V2TIMConversation *conv) {
              @strongify(self);

              markFold.on = [self.class isMarkedByFoldType:conv.markList];

              switchData.cswitchSelector = @selector(didSelectOnTop:);
              switchData.on = conv.isPinned;

              if (markFold.on) {
                  switchData.on = NO;
                  switchData.disableChecked = YES;
              }

              self.dataList = dataList;
            }
            fail:^(int code, NSString *desc) {
              NSLog(@"");
            }];
#else
        if ([[[TUIConversationPin sharedInstance] topConversationList] containsObject:[NSString stringWithFormat:@"group_%@", self.groupID]]) {
            switchData.on = YES;
        }
#endif
    }
}

- (void)didSelectMembers {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectMembers)]) {
        [self.delegate didSelectMembers];
    }
}

- (void)didSelectGroupNick:(TUICommonTextCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectGroupNick:)]) {
        [self.delegate didSelectGroupNick:cell];
    }
}

- (void)didSelectAddOption:(UITableViewCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectAddOption:)]) {
        [self.delegate didSelectAddOption:cell];
    }
}

- (void)didSelectCommon {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectCommon)]) {
        [self.delegate didSelectCommon];
    }
}

- (void)didSelectOnNotDisturb:(TUICommonSwitchCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectOnNotDisturb:)]) {
        [self.delegate didSelectOnNotDisturb:cell];
    }
}

- (void)didSelectOnTop:(TUICommonSwitchCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectOnTop:)]) {
        [self.delegate didSelectOnTop:cell];
    }
}

- (void)didSelectOnFoldConversation:(TUICommonSwitchCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectOnFoldConversation:)]) {
        [self.delegate didSelectOnFoldConversation:cell];
    }
}

- (void)didSelectOnChangeBackgroundImage:(TUICommonTextCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectOnChangeBackgroundImage:)]) {
        [self.delegate didSelectOnChangeBackgroundImage:cell];
    }
}
- (void)didTransferGroup:(TUIButtonCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTransferGroup:)]) {
        [self.delegate didTransferGroup:cell];
    }
}
- (void)didDeleteGroup:(TUIButtonCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didDeleteGroup:)]) {
        [self.delegate didDeleteGroup:cell];
    }
}

- (void)didClearAllHistory:(TUIButtonCell *)cell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClearAllHistory:)]) {
        [self.delegate didClearAllHistory:cell];
    }
}

- (void)didSelectGroupManage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectGroupManage)]) {
        [self.delegate didSelectGroupManage];
    }
}

- (void)didSelectNotice {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectGroupNotice)]) {
        [self.delegate didSelectGroupNotice];
    }
}

- (NSMutableArray *)getShowMembers:(NSMutableArray *)members {
    int maxCount = TGroupMembersCell_Column_Count * TGroupMembersCell_Row_Count;
    if ([self.groupInfo canInviteMember]) maxCount--;
    if ([self.groupInfo canRemoveMember]) maxCount--;
    NSMutableArray *tmpArray = [NSMutableArray array];

    for (NSInteger i = 0; i < members.count && i < maxCount; ++i) {
        [tmpArray addObject:members[i]];
    }
    if ([self.groupInfo canInviteMember]) {
        TUIGroupMemberCellData *add = [[TUIGroupMemberCellData alloc] init];
        add.avatarImage = TUIGroupCommonBundleImage(@"add");
        add.tag = 1;
        [tmpArray addObject:add];
    }
    if ([self.groupInfo canRemoveMember]) {
        TUIGroupMemberCellData *delete = [[TUIGroupMemberCellData alloc] init];
        delete.avatarImage = TUIGroupCommonBundleImage(@"delete");
        delete.tag = 2;
        [tmpArray addObject:delete];
    }
    return tmpArray;
}

- (void)setGroupAddOpt:(V2TIMGroupAddOpt)opt {
    @weakify(self);
    V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
    info.groupID = self.groupID;
    info.groupAddOpt = opt;

    [[V2TIMManager sharedInstance] setGroupInfo:info
        succ:^{
          @strongify(self);
          self.groupInfo.groupAddOpt = opt;
          self.addOptionData.value = [TUIGroupInfoDataProvider getAddOptionWithV2AddOpt:opt];
        }
        fail:^(int code, NSString *desc) {
          [TUITool makeToastError:code msg:desc];
        }];
}

- (void)setGroupApproveOpt:(V2TIMGroupAddOpt)opt {
    @weakify(self);
    V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
    info.groupID = self.groupID;
    info.groupApproveOpt = opt;

    [[V2TIMManager sharedInstance] setGroupInfo:info
        succ:^{
          @strongify(self);
          self.groupInfo.groupApproveOpt = opt;
          self.inviteOptionData.value = [TUIGroupInfoDataProvider getApproveOption:self.groupInfo];
        }
        fail:^(int code, NSString *desc) {
          [TUITool makeToastError:code msg:desc];
        }];
}

- (void)setGroupReceiveMessageOpt:(V2TIMReceiveMessageOpt)opt Succ:(V2TIMSucc)succ fail:(V2TIMFail)fail {
    [[V2TIMManager sharedInstance] setGroupReceiveMessageOpt:self.groupID opt:opt succ:succ fail:fail];
}

- (void)setGroupName:(NSString *)groupName {
    V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
    info.groupID = self.groupID;
    info.groupName = groupName;
    @weakify(self);
    [[V2TIMManager sharedInstance] setGroupInfo:info
        succ:^{
          @strongify(self);
          self.profileCellData.name = groupName;
        }
        fail:^(int code, NSString *msg) {
          [TUITool makeToastError:code msg:msg];
        }];
}

- (void)setGroupNotification:(NSString *)notification {
    V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
    info.groupID = self.groupID;
    info.notification = notification;
    @weakify(self);
    [[V2TIMManager sharedInstance] setGroupInfo:info
        succ:^{
          @strongify(self);
          self.profileCellData.signature = notification;
        }
        fail:^(int code, NSString *msg) {
          [TUITool makeToastError:code msg:msg];
        }];
}

- (void)setGroupMemberNameCard:(NSString *)nameCard {
    NSString *userID = [V2TIMManager sharedInstance].getLoginUser;
    V2TIMGroupMemberFullInfo *info = [[V2TIMGroupMemberFullInfo alloc] init];
    info.userID = userID;
    info.nameCard = nameCard;
    @weakify(self);
    [[V2TIMManager sharedInstance] setGroupMemberInfo:self.groupID
        info:info
        succ:^{
          @strongify(self);
          self.groupNickNameCellData.value = nameCard;
          self.selfInfo.nameCard = nameCard;
        }
        fail:^(int code, NSString *msg) {
          [TUITool makeToastError:code msg:msg];
        }];
}

- (void)dismissGroup:(V2TIMSucc)succ fail:(V2TIMFail)fail {
    [[V2TIMManager sharedInstance] dismissGroup:self.groupID succ:succ fail:fail];
}

- (void)quitGroup:(V2TIMSucc)succ fail:(V2TIMFail)fail {
    [[V2TIMManager sharedInstance] quitGroup:self.groupID succ:succ fail:fail];
}

- (void)clearAllHistory:(V2TIMSucc)succ fail:(V2TIMFail)fail {
    [V2TIMManager.sharedInstance clearGroupHistoryMessage:self.groupID succ:succ fail:fail];
}

+ (NSString *)getGroupTypeName:(V2TIMGroupInfo *)groupInfo {
    if (groupInfo.groupType) {
        if ([groupInfo.groupType isEqualToString:@"Work"]) {
            return TIMCommonLocalizableString(TUIKitWorkGroup);
        } else if ([groupInfo.groupType isEqualToString:@"Public"]) {
            return TIMCommonLocalizableString(TUIKitPublicGroup);
        } else if ([groupInfo.groupType isEqualToString:@"Meeting"]) {
            return TIMCommonLocalizableString(TUIKitChatRoom);
        } else if ([groupInfo.groupType isEqualToString:@"Community"]) {
            return TIMCommonLocalizableString(TUIKitCommunity);
        }
    }

    return @"";
}

+ (NSString *)getAddOption:(V2TIMGroupInfo *)groupInfo {
    switch (groupInfo.groupAddOpt) {
        case V2TIM_GROUP_ADD_FORBID:
            return TIMCommonLocalizableString(TUIKitGroupProfileJoinDisable);
            break;
        case V2TIM_GROUP_ADD_AUTH:
            return TIMCommonLocalizableString(TUIKitGroupProfileAdminApprove);
            break;
        case V2TIM_GROUP_ADD_ANY:
            return TIMCommonLocalizableString(TUIKitGroupProfileAutoApproval);
            break;
        default:
            break;
    }
    return @"";
}

+ (NSString *)getAddOptionWithV2AddOpt:(V2TIMGroupAddOpt)opt {
    switch (opt) {
        case V2TIM_GROUP_ADD_FORBID:
            return TIMCommonLocalizableString(TUIKitGroupProfileJoinDisable);
            break;
        case V2TIM_GROUP_ADD_AUTH:
            return TIMCommonLocalizableString(TUIKitGroupProfileAdminApprove);
            break;
        case V2TIM_GROUP_ADD_ANY:
            return TIMCommonLocalizableString(TUIKitGroupProfileAutoApproval);
            break;
        default:
            break;
    }
    return @"";
}

+ (NSString *)getApproveOption:(V2TIMGroupInfo *)groupInfo {
    switch (groupInfo.groupApproveOpt) {
        case V2TIM_GROUP_ADD_FORBID:
            return TIMCommonLocalizableString(TUIKitGroupProfileInviteDisable);
            break;
        case V2TIM_GROUP_ADD_AUTH:
            return TIMCommonLocalizableString(TUIKitGroupProfileAdminApprove);
            break;
        case V2TIM_GROUP_ADD_ANY:
            return TIMCommonLocalizableString(TUIKitGroupProfileAutoApproval);
            break;
        default:
            break;
    }
    return @"";
}

+ (BOOL)isMarkedByFoldType:(NSArray *)markList {
    for (NSNumber *num in markList) {
        if (num.unsignedLongValue == V2TIM_CONVERSATION_MARK_TYPE_FOLD) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isMarkedByHideType:(NSArray *)markList {
    for (NSNumber *num in markList) {
        if (num.unsignedLongValue == V2TIM_CONVERSATION_MARK_TYPE_HIDE) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isMeOwner:(V2TIMGroupInfo *)groupInfo {
    return [groupInfo.owner isEqualToString:[[V2TIMManager sharedInstance] getLoginUser]] || (groupInfo.role == V2TIM_GROUP_MEMBER_ROLE_ADMIN);
}

+ (BOOL)isMeSuper:(V2TIMGroupInfo *)groupInfo {
    return [groupInfo.owner isEqualToString:[[V2TIMManager sharedInstance] getLoginUser]] && (groupInfo.role == V2TIM_GROUP_MEMBER_ROLE_SUPER);
}
@end
