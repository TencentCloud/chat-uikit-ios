//
//  TCommonCell.h
//  TXIMSDK_TUIKit_iOS
//
//  Created by annidyfeng on 2019/5/6.
//

#import <UIKit/UIKit.h>
#import "TUIDarkModel.h"

@import ImSDK_Plus;

NS_ASSUME_NONNULL_BEGIN
/////////////////////////////////////////////////////////////////////////////////
//
//                            TUIUserFullInfo
//
/////////////////////////////////////////////////////////////////////////////////
@interface V2TIMUserFullInfo (TUIUserFullInfo)
- (NSString *)showName;
- (NSString *)showGender;
- (NSString *)showSignature;
- (NSString *)showAllowType;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                            TUIUserModel
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUIUserModel : NSObject<NSCopying>
@property(nonatomic,copy) NSString *userId;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *avatar;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUIScrollView
//
/////////////////////////////////////////////////////////////////////////////////

@interface TUIScrollView : UIScrollView
@property (strong, nonatomic) UIImageView *imageView;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUIPopView
//
/////////////////////////////////////////////////////////////////////////////////
@class TUIPopView;
@protocol TUIPopViewDelegate <NSObject>
- (void)popView:(TUIPopView *)popView didSelectRowAtIndex:(NSInteger)index;
@end

@interface TUIPopView : UIView
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGPoint arrowPoint;
@property (nonatomic, weak) id<TUIPopViewDelegate> delegate;
- (void)setData:(NSMutableArray *)data;
- (void)showInWindow:(UIWindow *)window;
@end

@interface TUIPopCellData : NSObject
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *title;
@end

@interface TUIPopCell : UITableViewCell
@property (nonatomic, strong) UIImageView *image;
@property (nonatomic, strong) UILabel *title;
+ (CGFloat)getHeight;
- (void)setData:(TUIPopCellData *)data;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUIModifyView
//
/////////////////////////////////////////////////////////////////////////////////
@class TUIModifyView;
@protocol TUIModifyViewDelegate <NSObject>
- (void)modifyView:(TUIModifyView *)modifyView didModiyContent:(NSString *)content;
@end

@interface TUIModifyViewData : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, assign) BOOL enableNull;
@end

@interface TUIModifyView : UIView
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UITextField *content;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIButton *confirm;
@property (nonatomic, strong) UIView *hLine;
@property (nonatomic, weak) id<TUIModifyViewDelegate> delegate;
- (void)setData:(TUIModifyViewData *)data;
- (void)showInWindow:(UIWindow *)window;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUINaviBarIndicatorView
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUINaviBarIndicatorView : UIView

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@property (nonatomic, strong) UILabel *label;

- (void)setTitle:(NSString *)title;

- (void)startAnimating;

- (void)stopAnimating;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUICommonCell & data
//
/////////////////////////////////////////////////////////////////////////////////

@interface TUICommonCellData : NSObject
@property (strong) NSString *reuseId;
@property (nonatomic, assign) SEL cselector;
@property (nonatomic, strong) NSDictionary *ext;
- (CGFloat)heightOfWidth:(CGFloat)width;
- (CGFloat)estimatedHeight;
@end

@interface TUICommonTableViewCell : UITableViewCell

@property (readonly) TUICommonCellData *data;
@property UIColor *colorWhenTouched;
@property BOOL changeColorWhenTouched;

- (void)fillWithData:(TUICommonCellData *)data;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUICommonTextCell & data
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUICommonTextCellData : TUICommonCellData

@property NSString *key;
@property NSString *value;
@property BOOL showAccessory;
@property UIColor *keyColor;
@property UIColor *valueColor;
@property BOOL enableMultiLineValue;

@property (nonatomic, assign) UIEdgeInsets keyEdgeInsets;

@end

@interface TUICommonTextCell : TUICommonTableViewCell
@property UILabel *keyLabel;
@property UILabel *valueLabel;
@property (readonly) TUICommonTextCellData *textData;

- (void)fillWithData:(TUICommonTextCellData *)data;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUICommonSwitchCell & data
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUICommonSwitchCellData : TUICommonCellData

@property NSString *title;
@property NSString *desc;
@property (getter=isOn) BOOL on;
@property CGFloat margin;
@property SEL cswitchSelector;

@property (nonatomic,assign) BOOL displaySeparatorLine;

@property (nonatomic,assign) BOOL disableChecked;

@end

@interface TUICommonSwitchCell : TUICommonTableViewCell
@property UILabel *titleLabel; // main title label
@property UILabel *descLabel; // detail title label below the main title label, used for explaining details
@property UISwitch *switcher;

@property (readonly) TUICommonSwitchCellData *switchData;

- (void)fillWithData:(TUICommonSwitchCellData *)data;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                           TUIButtonCell & data
//
/////////////////////////////////////////////////////////////////////////////////
typedef enum : NSUInteger {
    ButtonGreen,
    ButtonWhite,
    ButtonRedText,
    ButtonBule,
} TUIButtonStyle;

@interface TUIButtonCellData : TUICommonCellData
@property (nonatomic, strong) NSString *title;
@property SEL cbuttonSelector;
@property TUIButtonStyle style;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, assign) BOOL hideSeparatorLine;
@end

@interface TUIButtonCell : TUICommonTableViewCell
@property (nonatomic, strong) UIButton *button;
@property TUIButtonCellData *buttonData;

- (void)fillWithData:(TUIButtonCellData *)data;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                             TUIGroupPendencyCell & data
//
/////////////////////////////////////////////////////////////////////////////////
#define TUIGroupPendencyCellData_onPendencyChanged @"TUIGroupPendencyCellData_onPendencyChanged"

@interface TUIGroupPendencyCellData : TUICommonCellData

@property(nonatomic,strong) NSString* groupId;

@property(nonatomic,strong) NSString* fromUser;

@property(nonatomic,strong) NSString* toUser;

@property (readonly) V2TIMGroupApplication *pendencyItem;

@property NSURL *avatarUrl;

@property NSString *title;

/**
 *  ???????????????????????????????????????????????????????????????
 *  The joining group introduction of the requester. Such as "Xiao Ming applied to join the group".
 */
@property NSString *requestMsg;

/**
 *  ???????????????YES????????????
 *  ???????????? NO????????????????????????????????????????????????????????????????????????
 *
 *  Agree or Not
 *  YES: Agree;  NO: Indicates that the current request was not granted, but does not mean that the request has been denied.
 */
@property BOOL isAccepted;

/**
 *  ???????????????YES????????????
 *  ???????????? NO????????????????????????????????????????????????????????????????????????
 *
 *  Refuse or Not
 *  YES: Refuse; NO: Indicates that the current request is not denied, but does not mean that the request has been granted.
 */
@property BOOL isRejectd;
@property SEL cbuttonSelector;


- (instancetype)initWithPendency:(V2TIMGroupApplication *)args;


- (void)accept;
- (void)reject;

@end

@interface TUIGroupPendencyCell : TUICommonTableViewCell

@property UIImageView *avatarView;

@property UILabel *titleLabel;

@property UILabel *addWordingLabel;

@property UIButton *agreeButton;

@property TUIGroupPendencyCellData *pendencyData;

- (void)fillWithData:(TUIGroupPendencyCellData *)pendencyData;

@end


/////////////////////////////////////////////////////////////////////////////////
//
//                             TUIFaceCell & data
//
/////////////////////////////////////////////////////////////////////////////////

/**
 * ??????????????????TUIFaceCellData
 * ???????????????????????????????????????????????????????????????
 *
 *
 * ???Module name??? TUIFaceCellData
 * ???Function description]???The name and local storage path of the stored emoticon.
 */
@interface TUIFaceCellData : NSObject

/**
 * ????????????
 * The name of emoticon
 */
@property (nonatomic, strong) NSString *name;

/**
 * ???????????????????????????????????????????????????????????????length???0???????????????name???
 * The localized name of the emoticon (the attribute used for internationalization, if it is empty or the length is 0, the name is displayed by default)
 */
@property (nonatomic, copy) NSString *localizableName;

/**
 * ???????????????????????????????????????
 * The storage path of the emoticon cached locally.
 */
@property (nonatomic, strong) NSString *path;
@end

/**
 * ??????????????????TUIFaceCell
 * ??????????????????????????????????????????????????? TUIFaceCellData ????????? Cell???
 *  ?????????????????????TUIFaceCell ??????????????????????????????
 *
 *
 * ???Module name???TUIFaceCell
 * ???Function description??? Store the image of the emoticon, and initialize the Cell according to TUIFaceCellData.
 *  In the emoticon view, TUIFaceCell is the unit displayed on the interface.
 */
@interface TUIFaceCell : UICollectionViewCell

/**
 *  ????????????
 *  The image view for displaying emoticon
 */
@property (nonatomic, strong) UIImageView *face;


- (void)setData:(TUIFaceCellData *)data;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                          TUIFaceGroup
//
/////////////////////////////////////////////////////////////////////////////////

/**
 * ??????????????????TUIFaceGroup
 * ??????????????????????????????????????????????????????????????????????????????????????????????????????
 *  ????????????????????????????????????????????????????????? FaceView ????????????????????????????????????
 *  ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
 *
 *
 * ???Module name??? TUIFaceGroup
 * ???Function description??? It is used to realize the grouping of emoticon, which is convenient for users to browse and select under different emoticon themes.
 *  This class stores the index of each emoticon group, so that FaceView can locate each emoticon group.
 *  At the same time, this class stores the path of all emoticon pictures in an emoticon group, and provides data such as the number of lines, the number of emoticons in each line, etc., to locate specific emoticons
 */
@interface TUIFaceGroup : NSObject

/**
 *  ????????????????????????0?????????
 *  Index of emoticons group, begining with zero.
 */
@property (nonatomic, assign) int groupIndex;

/**
 *  ???????????????
 *  The resource path of the entire expression group
 */
@property (nonatomic, strong) NSString *groupPath;

/**
 *  ??????????????????
 *  The number of lines of emoticons in the emoticon group
 */
@property (nonatomic, assign) int rowCount;

/**
 *  ???????????????????????????
 *  The number of emoticons contained in each line
 */
@property (nonatomic, assign) int itemCountPerRow;

@property (nonatomic, strong) NSMutableArray *faces;

/**
 *  ???????????????
 *  ???????????? YES ??????FaceView ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
 *
 *  The flag of indicating whether to display the delete button
 *  When set to YES, FaceView will display a "delete" icon in the lower right corner of the emoticon view. Clicking the icon can delete the entered emoticon directly without evoking the keyboard.
 */
@property (nonatomic, assign) BOOL needBackDelete;

/**
 *  ??????menu??????
 *  ??????????????????????????????????????????????????????????????????????????????????????????????????????
 *
 *  The path to the cover image of the emoticon group
 */
@property (nonatomic, strong) NSString *menuPath;
@end

@interface TUIEmojiTextAttachment : NSTextAttachment

@property(nonatomic,strong) TUIFaceCellData *faceCellData;

@property(nonatomic,copy) NSString *emojiTag;

@property(nonatomic,assign) CGSize emojiSize;  //For emoji image size

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                          TUIUnReadView?????????????????????
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUIUnReadView : UIView

/**
 * ??????????????? label
 * The label of displaying unread message count
 */
@property (nonatomic, strong) UILabel *unReadLabel;

/**
 * ???????????????
 * Set the unread message count
 */
- (void)setNum:(NSInteger)num;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                          TUIConversationPin
//
/////////////////////////////////////////////////////////////////////////////////
extern NSString *kTopConversationListChangedNotification;

@interface TUIConversationPin : NSObject

+ (instancetype)sharedInstance;

/**
 * ???????????????????????????
 * Getting the list of pinned conversations
 */
- (NSArray *)topConversationList;

/**
 * ????????????
 * Pin the conversation
 */
- (void)addTopConversation:(NSString *)conv callback:(void(^ __nullable)(BOOL success, NSString * __nullable errorMessage))callback;
/**
 * ?????????????????????
 * Remove pinned conversations
 */
- (void)removeTopConversation:(NSString *)conv callback:(void(^ __nullable)(BOOL success, NSString * __nullable errorMessage))callback;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                          TUIGroupAvatar
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUIGroupAvatar : NSObject

/**
 * ????????? id ?????????????????????????????????????????????????????????????????????????????????????????????
 * ?????????????????????????????????????????????????????????????????? getCacheGroupAvatar:imageCallback ?????? getCacheAvatarForGroup: number:
 *
 * Obtain the latest group avatar in real time according to the group id. After the avatar is updated, it will be cached locally. This interface will request the network
 * This interface will not use the cache. If you need to read the cache, please use getCacheGroupAvatar:imageCallback or getCacheAvatarForGroup: number:
 */
+ (void)fetchGroupAvatars:(NSString *)groupID placeholder:(UIImage *)placeholder callback:(void(^)(BOOL success, UIImage *image, NSString *groupID))callback;

/**
 * ???????????????url????????????????????????
 * Create a group avatar based on the given url array
 */
+ (void)createGroupAvatar:(NSArray *)group finished:(void (^)(UIImage *groupAvatar))finished;

/**
 * ???????????? ID ??????????????????????????????
 * Cache avatars based on group ID and number of group members
 */
+ (void)cacheGroupAvatar:(UIImage*)avatar number:(UInt32)memberNum groupID:(NSString *)groupID;

/**
 * ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
 * Get the cached avatar asynchronously, this interface will request the interface to get the current number of group members, and return the avatar corresponding to the local cache
 */
+ (void)getCacheGroupAvatar:(NSString *)groupID callback:(void(^)(UIImage *, NSString *groupID))imageCallBack;

/**
 * ???????????????????????????????????????????????????
 * Get the cached avatar synchronously, this interface does not request the network
 */
+ (UIImage *)getCacheAvatarForGroup:(NSString *)groupId number:(UInt32)memberNum;

/**
 * ?????????????????????????????????
 * Clear the avatar cache of the specified group
 */
+ (void)asyncClearCacheAvatarForGroup:(NSString *)groupID;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                          TUIImageCache
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUIImageCache : NSObject

+ (instancetype)sharedInstance;

- (void)addResourceToCache:(NSString *)path;
- (UIImage *)getResourceFromCache:(NSString *)path;


- (void)addFaceToCache:(NSString *)path;
- (UIImage *)getFaceFromCache:(NSString *)path;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                          TUICommonContactSelectCellData
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUICommonContactSelectCellData : TUICommonCellData


@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *avatarUrl;
@property (nonatomic, strong) UIImage *avatarImage;


@property (nonatomic,getter=isSelected) BOOL selected;
@property (nonatomic,getter=isEnabled) BOOL enabled;

@end


/////////////////////////////////////////////////////////////////////////////////
//
//                          TUICommonContactListPickerCell
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUICommonContactListPickerCell : UICollectionViewCell

@property UIImageView *avatar;

@end


/////////////////////////////////////////////////////////////////////////////////
//
//                          TUIContactListPickerOnCancel
//
/////////////////////////////////////////////////////////////////////////////////
typedef void(^TUIContactListPickerOnCancel)(TUICommonContactSelectCellData *data);

@interface TUIContactListPicker : UIControl

@property (nonatomic, strong, readonly) UIButton *accessoryBtn;
@property (nonatomic, strong) NSArray<TUICommonContactSelectCellData *> *selectArray;
@property (nonatomic, copy) TUIContactListPickerOnCancel onCancel;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                             TUIProfileCardCell & vc
//
/////////////////////////////////////////////////////////////////////////////////
@class TUIProfileCardCell;
@protocol TUIProfileCardDelegate <NSObject>
- (void)didTapOnAvatar:(TUIProfileCardCell *)cell;
@end

@interface TUIProfileCardCellData : TUICommonCellData
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) NSURL *avatarUrl;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *signature;
@property (nonatomic, strong) UIImage *genderIconImage;
@property (nonatomic, strong) NSString *genderString;
@property BOOL showAccessory;
@property BOOL showSignature;
@end

@interface TUIProfileCardCell : TUICommonTableViewCell
@property (nonatomic, strong) UIImageView *avatar;
@property (nonatomic, strong) UILabel *name;
@property (nonatomic, strong) UILabel *identifier;
@property (nonatomic, strong) UILabel *signature;
@property (nonatomic, strong) UIImageView *genderIcon;
@property (nonatomic, strong) TUIProfileCardCellData *cardData;
@property (nonatomic, weak)  id<TUIProfileCardDelegate> delegate;
- (void)fillWithData:(TUIProfileCardCellData *)data;
@end

@interface TUIAvatarViewController : UIViewController

@property (nonatomic, strong) TUIProfileCardCellData *avatarData;

@end

typedef NS_ENUM(NSUInteger, TUISelectAvatarType) {
    TUISelectAvatarTypeUserAvatar,
    TUISelectAvatarTypeGroupAvatar,
    TUISelectAvatarTypeCover,
    TUISelectAvatarTypeConversationBackGroundCover,
};
@interface TUISelectAvatarController : UIViewController
@property (nonatomic, copy) void (^selectCallBack)(NSString *urlStr);
@property (nonatomic, assign) TUISelectAvatarType selectAvatarType;
@property (nonatomic, copy) NSString *profilFaceURL;
@property (nonatomic, strong) UIImage *cacheGroupGridAvatarImage;
@property (nonatomic, copy) NSString *createGroupType;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                             TUICommonAvatarCell & Data
//
/////////////////////////////////////////////////////////////////////////////////
@interface TUICommonAvatarCellData : TUICommonCellData;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@property BOOL showAccessory;
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) NSURL *avatarUrl;

@end

@interface TUICommonAvatarCell :TUICommonTableViewCell
@property UILabel *keyLabel;
@property UILabel *valueLabel;
@property UIImageView *avatar;
@property (readonly) TUICommonAvatarCellData *avatarData;


- (void)fillWithData:(TUICommonAvatarCellData *) avatarData;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                          TUINavigationController
//
/////////////////////////////////////////////////////////////////////////////////
@class TUINavigationController;
@protocol TUINavigationControllerDelegate <NSObject>
@optional
- (void)navigationControllerDidClickLeftButton:(TUINavigationController *)controller;
- (void)navigationControllerDidSideSlideReturn:(TUINavigationController *)controller
                            fromViewController:(UIViewController *)fromViewController;
@end

@interface TUINavigationController : UINavigationController <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property(nonatomic,weak) UIViewController* currentShowVC;
@property (nonatomic, weak) id<TUINavigationControllerDelegate> uiNaviDelegate;

@end


@interface UIAlertController (TUITheme)

- (void)tuitheme_addAction:(UIAlertAction *)action;

@end

NS_ASSUME_NONNULL_END
