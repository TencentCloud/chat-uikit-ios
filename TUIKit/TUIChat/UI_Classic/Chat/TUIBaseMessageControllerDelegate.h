
//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
@import ImSDK_Plus;

@class TUIBaseMessageController;
@class TUIMessageCellData;
@class TUIMessageCell;

NS_ASSUME_NONNULL_BEGIN

/////////////////////////////////////////////////////////////////////////////////
//
//                         TUIBaseMessageControllerDelegate
//
/////////////////////////////////////////////////////////////////////////////////

@protocol TUIBaseMessageControllerDelegate <NSObject>

/**
 *  Callback for clicking controller
 *  You can use this callback to: reset the InputController, dismiss the keyboard.
 *
 *  @param controller Delegator, Message Controller
 */
- (void)didTapInMessageController:(TUIBaseMessageController *)controller;

/**
 *  Callback after hide long press menu button
 *  You can customize the implementation of this delegate function according to your needs.
 *
 *  @param controller Delegator, Message Controller
 */
- (void)didHideMenuInMessageController:(TUIBaseMessageController *)controller;


/**
 *  Callback before hide long press menu button
 *  You can customize the implementation of this delegate function according to your needs.
 *
 *  @param controller Delegator, Message Controller
 *  @param view The view where the controller is located
 */
- (BOOL)messageController:(TUIBaseMessageController *)controller willShowMenuInCell:(UIView *)view;

/**
 *  Callback for receiving new message
 *  You can use this callback to initialize a new message based on the incoming data and perform a new message reminder.
 *
 *  @param controller Delegator, Message Controller
 *  @param message Incoming new message
 *
 *  @return Returns the new message unit that needs to be displayed.
 */
- (TUIMessageCellData *)messageController:(TUIBaseMessageController *)controller onNewMessage:(V2TIMMessage *)message;

/**
 *  Callback for displaying new message
 *  You can use this callback to initialize the message bubble based on the incoming data and display it
 *
 *  @param controller Delegator, Message Controller
 *  @param data Data needed to display
 *
 *  @return Returns the new message unit that needs to be displayed.。
 */
- (TUIMessageCell *)messageController:(TUIBaseMessageController *)controller onShowMessageData:(TUIMessageCellData *)data;

/**
 *  The callback the cell will be displayed with
 */
- (void)messageController:(TUIBaseMessageController *)controller willDisplayCell:(TUIMessageCell *)cell withData:(TUIMessageCellData *)cellData;

/**
 *  Callback for clicking avatar in the message cell
 *  You can use this callback to achieve: jump to the detailed information interface of the corresponding user.
 *  1. First pull user information, if the user is a friend of the current user, initialize the corresponding friend information interface and jump.
 *  2. If the user is not a friend of the current user, the corresponding interface for adding friends is initialized and a jump is performed.
 *
 */
- (void)messageController:(TUIBaseMessageController *)controller onSelectMessageAvatar:(TUIMessageCell *)cell;

/**
 *  Callback for long pressing avatar in the message cell
 */
- (void)messageController:(TUIBaseMessageController *)controller onLongSelectMessageAvatar:(TUIMessageCell *)cell;

/**
 *  Callback for clicking message content in the message cell
 */
- (void)messageController:(TUIBaseMessageController *)controller onSelectMessageContent:(TUIMessageCell *)cell;

/**
 * After long-pressing the message, the menu bar will pop up, and the callback after clicking the menu option
 * menuType: The type of menu that was clicked. 0 - multiple choice, 1 - forwarding.
 */
- (void)messageController:(TUIBaseMessageController *)controller onSelectMessageMenu:(NSInteger)menuType withData:(TUIMessageCellData *)data;

/**
 * Callback for about to reply to the message (usually triggered by long-pressing the message content and then clicking the reply button)
 */
- (void)messageController:(TUIBaseMessageController *)controller onRelyMessage:(TUIMessageCellData *)data;

/**
 * Callback for quoting message (triggered by long-pressing the message content and then clicking the quote button)
 */
- (void)messageController:(TUIBaseMessageController *)controller onReferenceMessage:(TUIMessageCellData *)data;

/**
 * Callback for re-editing message (usually for re-calling a message)
 */
- (void)messageController:(TUIBaseMessageController *)controller onReEditMessage:(TUIMessageCellData *)data;

/// Forward text.
- (void)messageController:(TUIBaseMessageController *)controller onForwardText:(NSString *)text;

/**
 * Get the height of custom Tips (such as safety tips in Demo)
 */
- (CGFloat)getTopMarginByCustomView;

@end

NS_ASSUME_NONNULL_END
