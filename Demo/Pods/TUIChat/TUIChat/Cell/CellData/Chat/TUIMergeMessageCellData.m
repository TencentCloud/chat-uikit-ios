//
//  TUIMergeMessageCellData.m
//  Pods
//
//  Created by harvy on 2020/12/9.
//

#import "TUIMergeMessageCellData.h"
#import "TUITextMessageCellData.h"
#import "TUIDefine.h"

#ifndef CGFLOAT_CEIL
#ifdef CGFLOAT_IS_DOUBLE
#define CGFLOAT_CEIL(value) ceil(value)
#else
#define CGFLOAT_CEIL(value) ceilf(value)
#endif
#endif

@implementation TUIMergeMessageCellData

+ (TUIMessageCellData *)getCellData:(V2TIMMessage *)message {
    V2TIMMergerElem *elem = message.mergerElem;
    if (elem.layersOverLimit) {
        TUITextMessageCellData *limitCell = [[TUITextMessageCellData alloc] initWithDirection:(message.isSelf ? MsgDirectionOutgoing : MsgDirectionIncoming)];
        limitCell.content = TUIKitLocalizableString(TUIKitRelayLayerLimitTips);
        return limitCell;
    }
    
    TUIMergeMessageCellData *relayData = [[TUIMergeMessageCellData alloc] initWithDirection:(message.isSelf ? MsgDirectionOutgoing : MsgDirectionIncoming)];
    relayData.title = elem.title;
    relayData.abstractList = [NSArray arrayWithArray:elem.abstractList];
    relayData.mergerElem = elem;
    relayData.reuseId = TRelayMessageCell_ReuserId;
    return relayData;
}

+ (NSString *)getDisplayString:(V2TIMMessage *)message {
    return [NSString stringWithFormat:@"[%@]", TUIKitLocalizableString(TUIKitRelayChatHistory)];
}

- (CGSize)contentSize
{
    CGRect rect = [[self abstractAttributedString] boundingRectWithSize:CGSizeMake(TRelayMessageCell_Text_Width_Max, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGSize size = CGSizeMake(CGFLOAT_CEIL(rect.size.width), CGFLOAT_CEIL(rect.size.height));
    self.abstractSize = size;
    CGFloat height = size.height + 30;
    if (height > TRelayMessageCell_Text_Height_Max) {
        self.abstractSize = CGSizeMake(size.width, size.height - (height - TRelayMessageCell_Text_Height_Max));
        height = TRelayMessageCell_Text_Height_Max;
    }
    return CGSizeMake(200, height);
}

- (NSAttributedString *)abstractAttributedString
{
    NSMutableAttributedString *abstr = [[NSMutableAttributedString alloc] initWithString:@""];
    int i = 0;
    for (NSString *ab in self.abstractList) {
        if (i >= 3) {
            break;
        }
        NSString *str = [NSString stringWithFormat:@"%@\n", ab];
        [abstr appendAttributedString:[[NSAttributedString alloc] initWithString:str]];
        i++;
    }
    return abstr;
}


@end
