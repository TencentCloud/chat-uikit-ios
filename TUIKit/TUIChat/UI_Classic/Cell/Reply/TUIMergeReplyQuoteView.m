//
//  TUIMergeReplyQuoteView.m
//  TUIChat
//
//  Created by harvy on 2021/11/25.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "TUIMergeReplyQuoteView.h"
#import <TUICore/TUIDarkModel.h>
#import <TUICore/UIView+TUILayout.h>
#import "TUIMergeReplyQuoteViewData.h"

@implementation TUIMergeReplyQuoteView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"title";
        _titleLabel.font = [UIFont systemFontOfSize:10.0];
        _titleLabel.textColor = [UIColor d_systemGrayColor];
        _titleLabel.numberOfLines = 1;

        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.text = @"1\n2";
        _subTitleLabel.font = [UIFont systemFontOfSize:10.0];
        _subTitleLabel.textColor = [UIColor d_systemGrayColor];
        _subTitleLabel.numberOfLines = 2;

        [self addSubview:_titleLabel];
        [self addSubview:_subTitleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)fillWithData:(TUIReplyQuoteViewData *)data {
    [super fillWithData:data];

    if (![data isKindOfClass:TUIMergeReplyQuoteViewData.class]) {
        return;
    }

    TUIMergeReplyQuoteViewData *myData = (TUIMergeReplyQuoteViewData *)data;
    self.titleLabel.text = myData.title;
    self.subTitleLabel.text = myData.abstract;

    // tell constraints they need updating
    [self setNeedsUpdateConstraints];

    // update constraints now so we can animate the change
    [self updateConstraintsIfNeeded];

    [self layoutIfNeeded];

}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}
// this is Apple's recommended place for adding/updating constraints
- (void)updateConstraints {
     
    [super updateConstraints];
    
    [self.titleLabel sizeToFit];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self);
        make.top.mas_equalTo(self);
        make.trailing.mas_equalTo(self.mas_trailing);
        make.height.mas_equalTo(self.titleLabel.font.lineHeight);
    }];
    
    [self.subTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.titleLabel);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).mas_offset(3);
        make.trailing.mas_equalTo(self.mas_trailing).mas_offset(-8);
        make.height.mas_equalTo(self.subTitleLabel.font.lineHeight);
    }];

}

- (void)reset {
    [super reset];
    self.titleLabel.text = @"";
    self.subTitleLabel.text = @"";
}

@end
