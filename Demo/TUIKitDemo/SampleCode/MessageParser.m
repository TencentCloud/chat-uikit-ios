- (void)onRecvNewMessage:(V2TIMMessage *)msg
{
    // Text message
    if (msg.elemType == V2TIM_ELEM_TYPE_TEXT) {
        V2TIMTextElem *textElem = msg.textElem;
        NSString *text = textElem.text;
        NSLog(@"Text message : %@", text);
    }
    // Custom message
    else if (msg.elemType == V2TIM_ELEM_TYPE_CUSTOM) {
        V2TIMCustomElem *customElem = msg.customElem;
        NSData *customData = customElem.data;
        NSLog(@"Custom message : %@",customData);
    }
    // Image Message
    else if (msg.elemType == V2TIM_ELEM_TYPE_IMAGE) {
        V2TIMImageElem *imageElem = msg.imageElem;
        NSArray<V2TIMImage *> *imageList = imageElem.imageList;
        for (V2TIMImage *timImage in imageList) {
            NSString *uuid = timImage.uuid;
            V2TIMImageType type = timImage.type;
            int size = timImage.size;
            int width = timImage.width;
            int height = timImage.height;
            NSString *imagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"testImage%@",timImage.uuid]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                [timImage downloadImage:imagePath progress:^(NSInteger curSize, NSInteger totalSize) {
                    NSLog(@"Progress: curSize:%lu,totalSize:%lu",curSize,totalSize);
                } succ:^{
                    NSLog(@"Done");
                } fail:^(int code, NSString *msg) {
                    NSLog(@"Fail: code:%d,msg:%@",code,msg);
                }];
            } else {
            }
            NSLog(@"Image info:uuid:%@,type:%ld,size:%d,width:%d,height:%d",uuid,(long)type,size,width,height);
        }
    }
    // Sound message
    else if (msg.elemType == V2TIM_ELEM_TYPE_SOUND) {
        V2TIMSoundElem *soundElem = msg.soundElem;
        NSString *uuid = soundElem.uuid;
        int dataSize = soundElem.dataSize;
        int duration = soundElem.duration;
        NSString *soundPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"testSound%@",uuid]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:soundPath]) {
            [soundElem downloadSound:soundPath progress:^(NSInteger curSize, NSInteger totalSize) {
                NSLog(@"Progress: curSize:%lu,totalSize:%lu",curSize,totalSize);
            } succ:^{
                NSLog(@"Done");
            } fail:^(int code, NSString *msg) {
                NSLog(@"Fail: code:%d,msg:%@",code,msg);
            }];
        } else {
        }
        NSLog(@"Sound info:uuid:%@,dataSize：%d,duration:%d,soundPath:%@",uuid,dataSize,duration,soundPath);
    }
    // Video message
    else if (msg.elemType == V2TIM_ELEM_TYPE_VIDEO) {
        V2TIMVideoElem *videoElem = msg.videoElem;
        NSString *snapshotUUID = videoElem.snapshotUUID;
        int snapshotSize = videoElem.snapshotSize;
        int snapshotWidth = videoElem.snapshotWidth;
        int snapshotHeight = videoElem.snapshotHeight;
        NSString *videoUUID = videoElem.videoUUID;
        int videoSize = videoElem.videoSize;
        int duration = videoElem.duration;
        NSString *snapshotPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"testVideoSnapshot%@",snapshotUUID]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:snapshotPath]) {
            [videoElem downloadSnapshot:snapshotPath progress:^(NSInteger curSize, NSInteger totalSize) {
                NSLog(@"%@", [NSString stringWithFormat:@"progress: curSize:%lu,totalSize:%lu",curSize,totalSize]);
            } succ:^{
                NSLog(@"Done");
            } fail:^(int code, NSString *msg) {
                NSLog(@"%@", [NSString stringWithFormat:@"Fail: code:%d,msg:%@",code,msg]);
            }];
        } else {
        }
        NSLog(@"Vodeo snapshot info：snapshotUUID:%@,snapshotSize:%d,snapshotWidth:%d,snapshotWidth:%d,snapshotPath:%@",snapshotUUID,snapshotSize,snapshotWidth,snapshotHeight,snapshotPath);
    
        NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"testVideo%@",videoUUID]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
            [videoElem downloadVideo:videoPath progress:^(NSInteger curSize, NSInteger totalSize) {
                NSLog(@"%@", [NSString stringWithFormat:@"Progress: curSize:%lu,totalSize:%lu",curSize,totalSize]);
            } succ:^{
                NSLog(@"Done");
            } fail:^(int code, NSString *msg) {
                NSLog(@"%@", [NSString stringWithFormat:@"Fail: code:%d,msg:%@",code,msg]);
            }];
        } else {
        }
        NSLog(@"Vodeo info：videoUUID:%@,videoSize:%d,duration:%d,videoPath:%@",videoUUID,videoSize,duration,videoPath);
    }
    // File message
    else if (msg.elemType == V2TIM_ELEM_TYPE_FILE) {
        V2TIMFileElem *fileElem = msg.fileElem;
        NSString *uuid = fileElem.uuid;
        NSString *filename = fileElem.filename;
        int fileSize = fileElem.fileSize;
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"testFile%@",uuid]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [fileElem downloadFile:filePath progress:^(NSInteger curSize, NSInteger totalSize) {
                NSLog(@"%@", [NSString stringWithFormat:@"Progress: curSize:%lu,totalSize:%lu",curSize,totalSize]);
            } succ:^{
                NSLog(@"Done");
            } fail:^(int code, NSString *msg) {
                NSLog(@"%@", [NSString stringWithFormat:@"Fail: code:%d,msg:%@",code,msg]);
            }];
        } else {
        }
        NSLog(@"File info: uuid:%@,filename:%@,fileSize:%d,filePath:%@",uuid,filename,fileSize,filePath);
    }
    else if (msg.elemType == V2TIM_ELEM_TYPE_LOCATION) {
        V2TIMLocationElem *locationElem = msg.locationElem;
        NSString *desc = locationElem.desc;
        double longitude = locationElem.longitude;
        double latitude = locationElem.latitude;
        NSLog(@"location info: desc:%@,longitude:%f,latitude:%f",desc,longitude,latitude);
    }
    else if (msg.elemType == V2TIM_ELEM_TYPE_FACE) {
        V2TIMFaceElem *faceElem = msg.faceElem;
        int index = faceElem.index;
        NSData *data = faceElem.data;
        NSLog(@"Sticker info: index:%d,data:%@",index,data);
    }
    else if (msg.elemType == V2TIM_ELEM_TYPE_GROUP_TIPS) {
        V2TIMGroupTipsElem *tipsElem = msg.groupTipsElem;
        NSString *groupID = tipsElem.groupID;
        V2TIMGroupTipsType type = tipsElem.type;
        V2TIMGroupMemberInfo * opMember = tipsElem.opMember;
        NSArray<V2TIMGroupMemberInfo *> * memberList = tipsElem.memberList;
        NSArray<V2TIMGroupChangeInfo *> * groupChangeInfoList = tipsElem.groupChangeInfoList;
        NSArray<V2TIMGroupMemberChangeInfo *> * memberChangeInfoList = tipsElem.memberChangeInfoList;
        uint32_t memberCount = tipsElem.memberCount;
        NSLog(@"tips info: groupID:%@,type:%ld,opMember:%@,memberList:%@,groupChangeInfoList:%@,memberChangeInfoList:%@,memberCount:%u",groupID,(long)type,opMember,memberList,groupChangeInfoList,memberChangeInfoList,memberCount);
    }
}
