//
//  TUIChatMediaDataProvider.m
//  TUIChat
//
//  Created by harvy on 2022/12/20.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "TUIChatMediaDataProvider.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <SDWebImage/SDWebImage.h>

#import <TIMCommon/TIMDefine.h>
#import <TIMCommon/TUIUserAuthorizationCenter.h>
#import <TIMCommon/NSTimer+TUISafe.h>
#import <TUICore/TUITool.h>
#import "TUICameraViewController.h"

#define kTUIChatMediaSelectImageMax 9
@interface TUIChatMediaDataProvider () <PHPickerViewControllerDelegate,
                                        UINavigationControllerDelegate,
                                        UIImagePickerControllerDelegate,
                                        UIDocumentPickerDelegate,
                                        TUICameraViewControllerDelegate>

@end

@implementation TUIChatMediaDataProvider

#pragma mark - Public API
- (void)selectPhoto {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (@available(iOS 14.0, *)) {
          PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
          configuration.filter = [PHPickerFilter anyFilterMatchingSubfilters:@[ [PHPickerFilter imagesFilter], [PHPickerFilter videosFilter] ]];
          configuration.selectionLimit = kTUIChatMediaSelectImageMax;
          PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
          picker.delegate = self;
          picker.modalPresentationStyle = UIModalPresentationFullScreen;
          picker.view.backgroundColor = [UIColor whiteColor];
          [self.presentViewController presentViewController:picker animated:YES completion:nil];
      } else {
          if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
              UIImagePickerController *picker = [[UIImagePickerController alloc] init];
              picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
              picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
              picker.delegate = self;
              [self.presentViewController presentViewController:picker animated:YES completion:nil];
          }
      }
    });
}

- (void)takePicture {
    __weak typeof(self) weakSelf = self;
    void (^actionBlock)(void) = ^(void) {
      TUICameraViewController *vc = [[TUICameraViewController alloc] init];
      vc.type = TUICameraMediaTypePhoto;
      vc.delegate = weakSelf;
      if (weakSelf.presentViewController.navigationController) {
          [weakSelf.presentViewController.navigationController pushViewController:vc animated:YES];
      } else {
          [weakSelf.presentViewController presentViewController:vc animated:YES completion:nil];
      }
    };
    if ([TUIUserAuthorizationCenter isEnableCameraAuthorization]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          actionBlock();
        });
    } else {
        if (![TUIUserAuthorizationCenter isEnableCameraAuthorization]) {
            [TUIUserAuthorizationCenter cameraStateActionWithPopCompletion:^{
              dispatch_async(dispatch_get_main_queue(), ^{
                actionBlock();
              });
            }];
        };
    }
}

- (void)takeVideo {
    __weak typeof(self) weakSelf = self;
    void (^actionBlock)(void) = ^(void) {
      TUICameraViewController *vc = [[TUICameraViewController alloc] init];
      vc.type = TUICameraMediaTypeVideo;
      vc.videoMinimumDuration = 1.5;
      vc.delegate = weakSelf;
      if (weakSelf.presentViewController.navigationController) {
          [weakSelf.presentViewController.navigationController pushViewController:vc animated:YES];
      } else {
          [weakSelf.presentViewController presentViewController:vc animated:YES completion:nil];
      }
    };

    if ([TUIUserAuthorizationCenter isEnableMicroAuthorization] && [TUIUserAuthorizationCenter isEnableCameraAuthorization]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          actionBlock();
        });
    } else {
        if (![TUIUserAuthorizationCenter isEnableMicroAuthorization]) {
            [TUIUserAuthorizationCenter microStateActionWithPopCompletion:^{
              if ([TUIUserAuthorizationCenter isEnableCameraAuthorization]) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    actionBlock();
                  });
              }
            }];
        }
        if (![TUIUserAuthorizationCenter isEnableCameraAuthorization]) {
            [TUIUserAuthorizationCenter cameraStateActionWithPopCompletion:^{
              if ([TUIUserAuthorizationCenter isEnableMicroAuthorization]) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    actionBlock();
                  });
              }
            }];
        }
    }
}

- (void)selectFile {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[ (NSString *)kUTTypeData ]
                                                                                                    inMode:UIDocumentPickerModeOpen];
    picker.delegate = self;
    [self.presentViewController presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Private Do task
- (void)handleImagePick:(BOOL)succ message:(NSString *)message imageData:(NSData *)imageData {
    static NSDictionary *imageFormatExtensionMap = nil;
    if (imageFormatExtensionMap == nil) {
        imageFormatExtensionMap = @{
            @(SDImageFormatUndefined) : @"",
            @(SDImageFormatJPEG) : @"jpeg",
            @(SDImageFormatPNG) : @"png",
            @(SDImageFormatGIF) : @"gif",
            @(SDImageFormatTIFF) : @"tiff",
            @(SDImageFormatWebP) : @"webp",
            @(SDImageFormatHEIC) : @"heic",
            @(SDImageFormatHEIF) : @"heif",
            @(SDImageFormatPDF) : @"pdf",
            @(SDImageFormatSVG) : @"svg",
            @(SDImageFormatBMP) : @"bmp",
            @(SDImageFormatRAW) : @"raw"
        };
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      if (succ == NO || imageData == nil) {
          if ([self.listener respondsToSelector:@selector(onProvideImageError:)]) {
              [self.listener onProvideImageError:message];
          }
          return;
      }

      UIImage *image = [UIImage imageWithData:imageData];
      NSData *data = imageData;
      NSString *path = [TUIKit_Image_Path stringByAppendingString:[TUITool genImageName:nil]];
      NSString *extenionName = [imageFormatExtensionMap objectForKey:@(image.sd_imageFormat)];
      if (extenionName.length > 0) {
          path = [path stringByAppendingPathExtension:extenionName];
      }

      if (image.sd_imageFormat != SDImageFormatGIF) {
          UIImage *newImage = image;
          UIImageOrientation imageOrientation = image.imageOrientation;
          if (imageOrientation != UIImageOrientationUp || imageData.length > 28 * 1024 * 1024) {
              CGFloat aspectRatio = MIN(1920 / image.size.width, 1920 / image.size.height);
              CGFloat aspectWidth = image.size.width * aspectRatio;
              CGFloat aspectHeight = image.size.height * aspectRatio;

              UIGraphicsBeginImageContext(CGSizeMake(aspectWidth, aspectHeight));
              [image drawInRect:CGRectMake(0, 0, aspectWidth, aspectHeight)];
              newImage = UIGraphicsGetImageFromCurrentImageContext();
              UIGraphicsEndImageContext();
          }
          data = UIImageJPEGRepresentation(newImage, 0.75);
      }
      else {
          if (imageData.length > 10 * 1024 * 1024) {
              if ([self.listener respondsToSelector:@selector(onProvideFileError:)]) {
                  [self.listener onProvideFileError:TIMCommonLocalizableString(TUIKitImageSizeCheckLimited)];
              }
              return;
          }
      }

      [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
      if ([self.listener respondsToSelector:@selector(onProvideImage:)]) {
          [self.listener onProvideImage:path];
      }
    });
}

- (void)transcodeIfNeed:(BOOL)succ message:(NSString *)message videoUrl:(NSURL *)url {
    if (succ == NO || url == nil) {
        [self handleVideoPick:NO message:message videoUrl:nil];
        return;
    }

    if ([url.pathExtension.lowercaseString isEqualToString:@"mp4"]) {
        [self handleVideoPick:succ message:message videoUrl:url];
        return;
    }

    NSString *tempPath = NSTemporaryDirectory();
    NSURL *urlName = [url URLByDeletingPathExtension];
    NSURL *newUrl = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@%@.mp4", tempPath, [urlName.lastPathComponent stringByRemovingPercentEncoding]]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:newUrl.path]) {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:newUrl.path error:&error];
        if (!success || error) {
            NSAssert1(NO, @"removeItemFail: %@", error.localizedDescription);
            return;
        }
    }

    // mov to mp4
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = newUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    // intercept FirstTime VideoPicture
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    NSInteger duration = (NSInteger)urlAsset.duration.value / urlAsset.duration.timescale;
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:urlAsset];
    gen.appliesPreferredTrackTransform = YES;
    gen.maximumSize = CGSizeMake(192, 192);
    NSError *error = nil;
    CMTime actualTime;
    CMTime time = CMTimeMakeWithSeconds(0.5, 30);
    CGImageRef imageRef = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
        
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.listener respondsToSelector:@selector(onProvidePlaceholderVideoSnapshot:SnapImage:Completion:)]) {
            [self.listener onProvidePlaceholderVideoSnapshot:@"" SnapImage:image Completion:^(BOOL finished, TUIMessageCellData * _Nonnull placeHolderCellData) {
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                  switch ([exportSession status]) {
                      case AVAssetExportSessionStatusFailed:
                          NSLog(@"Export session failed");
                          break;
                      case AVAssetExportSessionStatusCancelled:
                          NSLog(@"Export canceled");
                          break;
                      case AVAssetExportSessionStatusCompleted: {
                          // Video conversion finished
                          NSLog(@"Successful!");
                          [self handleVideoPick:succ message:message videoUrl:newUrl placeHolderCellData:placeHolderCellData];
                      }
                          break;
                      default:
                          break;
                  }
                }];
                
                [NSTimer tui_scheduledTimerWithTimeInterval:.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    if (exportSession.status == AVAssetExportSessionStatusExporting) {
                        NSLog(@"exportSession.progress:%f",exportSession.progress);
                        placeHolderCellData.videoTranscodingProgress = exportSession.progress;
                    }
                }];

            }];
        }
        else {
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
              switch ([exportSession status]) {
                  case AVAssetExportSessionStatusCompleted: {
                      // Video conversion finished
                      NSLog(@"Successful!");
                      [self handleVideoPick:succ message:message videoUrl:newUrl];
                  } break;
                  default:
                      break;
              }
            }];
        }
    });

    
}

- (void)handleVideoPick:(BOOL)succ message:(NSString *)message videoUrl:(NSURL *)videoUrl {
    [self handleVideoPick:succ message:message videoUrl:videoUrl placeHolderCellData:nil];
}
- (void)handleVideoPick:(BOOL)succ message:(NSString *)message videoUrl:(NSURL *)videoUrl placeHolderCellData:(TUIMessageCellData*)placeHolderCellData{
    if (succ == NO || videoUrl == nil) {
        if ([self.listener respondsToSelector:@selector(onProvideVideoError:)]) {
            [self.listener onProvideVideoError:message];
        }
        return;
    }

    NSData *videoData = [NSData dataWithContentsOfURL:videoUrl];
    NSString *videoPath = [NSString stringWithFormat:@"%@%@_%u.mp4", TUIKit_Video_Path, [TUITool genVideoName:nil],arc4random()];
    [[NSFileManager defaultManager] createFileAtPath:videoPath contents:videoData attributes:nil];

    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoUrl options:opts];
    NSInteger duration = (NSInteger)urlAsset.duration.value / urlAsset.duration.timescale;
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:urlAsset];
    gen.appliesPreferredTrackTransform = YES;
    gen.maximumSize = CGSizeMake(192, 192);
    NSError *error = nil;
    CMTime actualTime;
    CMTime time = CMTimeMakeWithSeconds(0.5, 30);
    CGImageRef imageRef = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);

    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *imagePath = [TUIKit_Video_Path stringByAppendingFormat:@"%@_%u",[TUITool genSnapshotName:nil],arc4random()];
    [[NSFileManager defaultManager] createFileAtPath:imagePath contents:imageData attributes:nil];

    if ([self.listener respondsToSelector:@selector(onProvideVideo:snapshot:duration:placeHolderCellData:)]) {
        [self.listener onProvideVideo:videoPath snapshot:imagePath duration:duration placeHolderCellData:placeHolderCellData];
    }
}

#pragma mark - PHPickerViewControllerDelegate
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [picker dismissViewControllerAnimated:YES completion:nil];
    });

    if (!results || results.count == 0) {
        return;
    }

    PHPickerResult *result = [results firstObject];
    for (PHPickerResult *result in results) {
        [self _dealPHPickerResultFinishPicking:result];
    }
}

- (void)_dealPHPickerResultFinishPicking:(PHPickerResult *)result API_AVAILABLE(ios(14)) {
    NSItemProvider *itemProvoider = result.itemProvider;
    __weak typeof(self) weakSelf = self;
    if ([itemProvoider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
        [itemProvoider loadDataRepresentationForTypeIdentifier:(NSString *)kUTTypeImage
                                             completionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 BOOL succ = YES;
                                                 NSString *message = nil;
                                                 if (error) {
                                                     succ = NO;
                                                     message = error.localizedDescription;
                                                 }
                                                 [weakSelf handleImagePick:succ message:message imageData:data];
                                               });
                                             }];
    } else if ([itemProvoider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMPEG4]) {
        [itemProvoider loadDataRepresentationForTypeIdentifier:(NSString *)kUTTypeMovie
                                             completionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 NSString *fileName = @"temp.mp4";
                                                 NSString *tempPath = NSTemporaryDirectory();
                                                 NSString *filePath = [tempPath stringByAppendingPathComponent:fileName];
                                                 if ([NSFileManager.defaultManager isDeletableFileAtPath:filePath]) {
                                                     [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
                                                 }
                                                 NSURL *newUrl = [NSURL fileURLWithPath:filePath];
                                                 BOOL flag = [NSFileManager.defaultManager createFileAtPath:filePath contents:data attributes:nil];
                                                 [weakSelf transcodeIfNeed:flag message:flag ? nil : @"video not found" videoUrl:newUrl];
                                               });
                                             }];
    } else if ([itemProvoider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
        [itemProvoider loadDataRepresentationForTypeIdentifier:(NSString *)kUTTypeMovie
                                             completionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 // 非 mp4 格式视频，暂时用 mov 后缀，后面会统一转换成 mp4 格式
                                                 // Non-mp4 format video, temporarily use mov suffix, will be converted to mp4 format later
                                                 NSDate *datenow = [NSDate date];
                                                 NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];
                                                 NSString *fileName = [NSString stringWithFormat:@"%@_temp.mov",timeSp];
                                                 NSString *tempPath = NSTemporaryDirectory();
                                                 NSString *filePath = [tempPath stringByAppendingPathComponent:fileName];
                                                 if ([NSFileManager.defaultManager isDeletableFileAtPath:filePath]) {
                                                     [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
                                                 }
                                                 NSURL *newUrl = [NSURL fileURLWithPath:filePath];
                                                 BOOL flag = [NSFileManager.defaultManager createFileAtPath:filePath contents:data attributes:nil];
                                                 [weakSelf transcodeIfNeed:flag message:flag ? nil : @"movie not found" videoUrl:newUrl];
                                               });
                                             }];
    } else {
        NSString *typeIdentifier = result.itemProvider.registeredTypeIdentifiers.firstObject;
        [itemProvoider loadFileRepresentationForTypeIdentifier:typeIdentifier
                                             completionHandler:^(NSURL *_Nullable url, NSError *_Nullable error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 UIImage *result;
                                                 NSData *data = [NSData dataWithContentsOfURL:url];
                                                 result = [UIImage imageWithData:data];

                                                 /**
                                                  * Can't get url when typeIdentifier is public.jepg on emulator:
                                                  * There is a separate JEPG transcoding issue that only affects the simulator (63426347), please refer to
                                                  * https://developer.apple.com/forums/thread/658135 for more information.
                                                  */
                                               });
                                             }];
    }
}

#pragma mark - UIImagePickerController
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    __weak typeof(self) weakSelf = self;
    picker.delegate = nil;
    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                 NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
                                 if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
                                     NSURL *url = nil;
                                     if (@available(iOS 11.0, *)) {
                                         url = [info objectForKey:UIImagePickerControllerImageURL];
                                     } else {
                                         url = [info objectForKey:UIImagePickerControllerReferenceURL];
                                     }

                                     BOOL succ = YES;
                                     NSData *imageData = nil;
                                     NSString *errorMessage = nil;
                                     if (url) {
                                         succ = YES;
                                         imageData = [NSData dataWithContentsOfURL:url];
                                     } else {
                                         succ = NO;
                                         errorMessage = @"image not found";
                                     }
                                     [weakSelf handleImagePick:succ message:errorMessage imageData:imageData];
                                 } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
                                     NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
                                     if (url) {
                                         [weakSelf transcodeIfNeed:YES message:nil videoUrl:url];
                                         return;
                                     }

                                     /**
                                      * 在某些情况下，UIImagePickerControllerMediaURL 可能为空，使用 UIImagePickerControllerPHAsset
                                      * In some cases UIImagePickerControllerMediaURL may be empty, use UIImagePickerControllerPHAsset
                                      */
                                     PHAsset *asset = nil;
                                     if (@available(iOS 11.0, *)) {
                                         asset = [info objectForKey:UIImagePickerControllerPHAsset];
                                     }
                                     if (asset) {
                                         [self originURLWithAsset:asset
                                                       completion:^(BOOL success, NSURL *URL) {
                                                         [weakSelf transcodeIfNeed:success
                                                                           message:success ? nil : @"origin url with asset not found"
                                                                          videoUrl:URL];
                                                       }];
                                         return;
                                     }

                                     /**
                                      * 在 ios 12 的情况下，UIImagePickerControllerMediaURL 及 UIImagePickerControllerPHAsset
                                      * 可能为空，需要使用其他方式获取视频文件原始路径 In the case of ios 12, UIImagePickerControllerMediaURL and
                                      * UIImagePickerControllerPHAsset may be empty, and other methods need to be used to obtain the original path of the video
                                      * file
                                      */
                                     url = [info objectForKey:UIImagePickerControllerReferenceURL];
                                     if (url) {
                                         [weakSelf originURLWithRefrenceURL:url
                                                                 completion:^(BOOL success, NSURL *URL) {
                                                                   [weakSelf transcodeIfNeed:success
                                                                                     message:success ? nil : @"origin url with asset not found"
                                                                                    videoUrl:URL];
                                                                 }];
                                         return;
                                     }

                                     // not support the video
                                     [weakSelf transcodeIfNeed:NO message:@"not support the video" videoUrl:nil];
                                 }
                               }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

/**
 * 根据 UIImagePickerControllerReferenceURL 获取原始文件路径
 * Get the original file path based on UIImagePickerControllerReferenceURL
 */
- (void)originURLWithRefrenceURL:(NSURL *)URL completion:(void (^)(BOOL success, NSURL *URL))completion {
    if (completion == nil) {
        return;
    }
    NSDictionary *queryInfo = [self dictionaryWithURLQuery:URL.query];
    NSString *fileName = @"temp.mp4";
    if ([queryInfo.allKeys containsObject:@"id"] && [queryInfo.allKeys containsObject:@"ext"]) {
        fileName = [NSString stringWithFormat:@"%@.%@", queryInfo[@"id"], [queryInfo[@"ext"] lowercaseString]];
    }
    NSString *tempPath = NSTemporaryDirectory();
    NSString *filePath = [tempPath stringByAppendingPathComponent:fileName];
    if ([NSFileManager.defaultManager isDeletableFileAtPath:filePath]) {
        [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
    }
    NSURL *newUrl = [NSURL fileURLWithPath:filePath];
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    [assetLibrary assetForURL:URL
        resultBlock:^(ALAsset *asset) {
          if (asset == nil) {
              completion(NO, nil);
              return;
          }
          ALAssetRepresentation *rep = [asset defaultRepresentation];
          Byte *buffer = (Byte *)malloc(rep.size);
          NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
          NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];  // this is NSData may be what you want
          BOOL flag = [NSFileManager.defaultManager createFileAtPath:filePath contents:data attributes:nil];
          completion(flag, newUrl);
        }
        failureBlock:^(NSError *err) {
          completion(NO, nil);
        }];
}

- (void)originURLWithAsset:(PHAsset *)asset completion:(void (^)(BOOL success, NSURL *URL))completion {
    if (completion == nil) {
        return;
    }

    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:asset];
    if (resources.count == 0) {
        completion(NO, nil);
        return;
    }

    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = NO;
    __block BOOL invoked = NO;
    [PHAssetResourceManager.defaultManager requestDataForAssetResource:resources.firstObject
        options:options
        dataReceivedHandler:^(NSData *_Nonnull data) {
          /**
           * 此处会有重复回调的问题
           * There will be a problem of repeated callbacks here
           */
          if (invoked) {
              return;
          }
          invoked = YES;
          if (data == nil) {
              completion(NO, nil);
              return;
          }
          NSString *fileName = @"temp.mp4";
          NSString *tempPath = NSTemporaryDirectory();
          NSString *filePath = [tempPath stringByAppendingPathComponent:fileName];
          if ([NSFileManager.defaultManager isDeletableFileAtPath:filePath]) {
              [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
          }
          NSURL *newUrl = [NSURL fileURLWithPath:filePath];
          BOOL flag = [NSFileManager.defaultManager createFileAtPath:filePath contents:data attributes:nil];
          completion(flag, newUrl);
        }
        completionHandler:^(NSError *_Nullable error) {
          completion(NO, nil);
        }];
}

- (NSDictionary *)dictionaryWithURLQuery:(NSString *)query {
    NSArray *components = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *item in components) {
        NSArray *subs = [item componentsSeparatedByString:@"="];
        if (subs.count == 2) {
            [dict setObject:subs.lastObject forKey:subs.firstObject];
        }
    }
    return [NSDictionary dictionaryWithDictionary:dict];
    ;
}

#pragma mark - TUICameraViewControllerDelegate
- (void)cameraViewController:(TUICameraViewController *)controller didFinishPickingMediaWithVideoURL:(NSURL *)url {
    [self transcodeIfNeed:YES message:nil videoUrl:url];
}

- (void)cameraViewController:(TUICameraViewController *)controller didFinishPickingMediaWithImageData:(NSData *)data {
    [self handleImagePick:YES message:nil imageData:data];
}

- (void)cameraViewControllerDidCancel:(TUICameraViewController *)controller {
}

- (void)cameraViewControllerDidPictureLib:(TUICameraViewController *)controller finishCallback:(void (^)(void))callback {
    [self selectPhoto];
    if (callback) {
        callback();
    }
}

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [url startAccessingSecurityScopedResource];
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    NSError *error;
    @weakify(self);
    [coordinator
        coordinateReadingItemAtURL:url
                           options:0
                             error:&error
                        byAccessor:^(NSURL *newURL) {
                          @strongify(self);
                          NSData *fileData = [NSData dataWithContentsOfURL:newURL options:NSDataReadingMappedIfSafe error:nil];
                          NSString *fileName = [url lastPathComponent];
                          NSString *filePath = [TUIKit_File_Path stringByAppendingString:fileName];
                          if (fileData.length > 1e9 || fileData.length == 0) { // 1e9 bytes = 1GB
                                UIAlertController *ac = [UIAlertController alertControllerWithTitle:TIMCommonLocalizableString(TUIKitFileSizeCheckLimited) message:nil preferredStyle:UIAlertControllerStyleAlert];
                                [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TIMCommonLocalizableString(Confirm) style:UIAlertActionStyleDefault handler:nil]];
                                [self.presentViewController presentViewController:ac animated:YES completion:nil];
                                return;
                          }
                          if ([NSFileManager.defaultManager fileExistsAtPath:filePath]) {
                              /**
                               * 存在同名文件，对文件名进行递增
                               * If a file with the same name exists, increment the file name
                               */
                              int i = 0;
                              NSArray *arrayM = [NSFileManager.defaultManager subpathsAtPath:TUIKit_File_Path];
                              for (NSString *sub in arrayM) {
                                  if ([sub.pathExtension isEqualToString:fileName.pathExtension] &&
                                      [sub.stringByDeletingPathExtension containsString:fileName.stringByDeletingPathExtension]) {
                                      i++;
                                  }
                              }
                              if (i) {
                                  fileName = [fileName
                                      stringByReplacingOccurrencesOfString:fileName.stringByDeletingPathExtension
                                                                withString:[NSString stringWithFormat:@"%@(%d)", fileName.stringByDeletingPathExtension, i]];
                                  filePath = [TUIKit_File_Path stringByAppendingString:fileName];
                              }
                          }

                          [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileData attributes:nil];
                          if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                              unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
                              if ([self.listener respondsToSelector:@selector(onProvideFile:filename:fileSize:)]) {
                                  [self.listener onProvideFile:filePath filename:fileName fileSize:fileSize];
                              }
                          } else {
                              if ([self.listener respondsToSelector:@selector(onProvideFileError:)]) {
                                  [self.listener onProvideFileError:@"file not found"];
                              }
                          }
                        }];
    [url stopAccessingSecurityScopedResource];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
