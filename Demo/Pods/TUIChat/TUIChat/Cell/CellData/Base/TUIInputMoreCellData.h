/******************************************************************************
 *
 * 本文件声明了用于实现“更多”单元的模块。
 * 更多单元，即在点击聊天界面右下角“+”后出现的若干单元。
 * 目前更多单元提供拍摄、视频、图片、文件四种多媒体发送功能，您也可以继续根据您的需求进行自定义拓展。
 * TUIInputMoreCellData 负责存储一系列“更多”单元所需的信息由数据。
 *
 ******************************************************************************/

#import <Foundation/Foundation.h>
@import UIKit;
NS_ASSUME_NONNULL_BEGIN

/////////////////////////////////////////////////////////////////////////////////
//
//                            TUIInputMoreCellData
//
/////////////////////////////////////////////////////////////////////////////////

/**
 * 【模块名称】TUIInputMoreCellData
 * 【功能说明】更多单元数据源
 *  更多单元负责在更多视图中显示，向用户展示更多视图中包含的功能。同时作为各个功能的入口，相应用户的交互事件。
 *  而数据源则负责存储一系列“更多”单元所需的信息由数据。
 */
@interface TUIInputMoreCellData : NSObject

/**
 *  UI 扩展 view
 */
@property (nonatomic, strong) UIView *extentionView;

/**
 *  唯一标识 key
 */
@property (nonatomic, strong) NSString *key;

/**
 *  单元图标
 *  各个单元的图标有所不同，用于形象表示该单元所对应的功能。
 */
@property (nonatomic, strong) UIImage *image;

/**
 *  单元名称
 *  各个单元的名称有所不同（比如拍摄、录像、文件、相册等），用于在图标下方以文字形式展示单元对应的功能。
 */
@property (nonatomic, strong) NSString *title;

/**
 *  “相册”单元所对应的数据源。用于存放相册单元所需的各类信息与数据。
 */
@property (class, nonatomic, assign) TUIInputMoreCellData *photoData;

/**
 *  “拍摄”单元所对应的数据源。用于存放拍摄单元所需的各类信息与数据。
 */
@property (class, nonatomic, assign) TUIInputMoreCellData *pictureData;

/**
 *  “视频”单元所对应的数据源。用于存放视频单元所需的各类信息与数据。
 */
@property (class, nonatomic, assign) TUIInputMoreCellData *videoData;

/**
 *  “文件”单元所对应的数据源。用于存放文件单元所需的各类信息与数据。
 */
@property (class, nonatomic, assign) TUIInputMoreCellData *fileData;

@end

NS_ASSUME_NONNULL_END
