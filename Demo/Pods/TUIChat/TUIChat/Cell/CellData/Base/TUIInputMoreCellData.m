
#import "TUIInputMoreCellData.h"
#import "TUIDefine.h"

static TUIInputMoreCellData *TUI_Photo_MoreCell;
static TUIInputMoreCellData *TUI_Picture_MoreCell;
static TUIInputMoreCellData *TUI_Video_MoreCell;
static TUIInputMoreCellData *TUI_File_MoreCell;
static TUIInputMoreCellData *TUI_VideoCall_MoreCell;
static TUIInputMoreCellData *TUI_AudioCall_MoreCell;
static TUIInputMoreCellData *TUI_GroupLivePlay_MoreCell;

@implementation TUIInputMoreCellData

+ (TUIInputMoreCellData *)pictureData
{
    if (!TUI_Picture_MoreCell) {
        TUI_Picture_MoreCell = [[TUIInputMoreCellData alloc] init];
        TUI_Picture_MoreCell.title = TUIKitLocalizableString(TUIKitMoreCamera);
        TUI_Picture_MoreCell.image = [UIImage d_imageNamed:@"more_camera" bundle:TUIChatBundle];

    }
    return TUI_Picture_MoreCell;
}

+ (void)setPictureData:(TUIInputMoreCellData *)cameraData
{
    TUI_Picture_MoreCell = cameraData;
}

+ (TUIInputMoreCellData *)photoData
{
    if (!TUI_Photo_MoreCell) {
        TUI_Photo_MoreCell = [[TUIInputMoreCellData alloc] init];
        TUI_Photo_MoreCell.title = TUIKitLocalizableString(TUIKitMorePhoto);
        TUI_Photo_MoreCell.image = [UIImage d_imageNamed:@"more_picture" bundle:TUIChatBundle];
    }
    return TUI_Photo_MoreCell;
}

+ (void)setPhotoData:(TUIInputMoreCellData *)pictureData
{
    TUI_Photo_MoreCell = pictureData;
}

+ (TUIInputMoreCellData *)videoData
{
    if (!TUI_Video_MoreCell) {
        TUI_Video_MoreCell = [[TUIInputMoreCellData alloc] init];
        TUI_Video_MoreCell.title = TUIKitLocalizableString(TUIKitMoreVideo);
        TUI_Video_MoreCell.image = [UIImage d_imageNamed:@"more_video" bundle:TUIChatBundle];
    }
    return TUI_Video_MoreCell;
}

+ (void)setVideoData:(TUIInputMoreCellData *)videoData
{
    TUI_Video_MoreCell = videoData;
}

+ (TUIInputMoreCellData *)fileData
{
    if (!TUI_File_MoreCell) {
        TUI_File_MoreCell = [[TUIInputMoreCellData alloc] init];
        TUI_File_MoreCell.title = TUIKitLocalizableString(TUIKitMoreFile);
        TUI_File_MoreCell.image = [UIImage d_imageNamed:@"more_file" bundle:TUIChatBundle];
    }
    return TUI_File_MoreCell;
}

+ (void)setFileData:(TUIInputMoreCellData *)fileData
{
    TUI_File_MoreCell = fileData;
}

@end
