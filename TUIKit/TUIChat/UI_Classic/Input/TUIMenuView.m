//
//  MenuView.m
//  UIKit
//
//  Created by kennethmiao on 2018/9/18.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "TUIMenuView.h"
#import <TIMCommon/TIMDefine.h>
#import <TUICore/TUIDarkModel.h>
#import <TUICore/TUIGlobalization.h>
#import <TUICore/TUIThemeManager.h>
#import "TUIMenuCell.h"

@interface TUIMenuView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property(nonatomic, strong) NSMutableArray<TUIMenuCellData *> *data;
@end

@implementation TUIMenuView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setData:(NSMutableArray<TUIMenuCellData *> *)data {
    _data = data;
    [_menuCollectionView reloadData];
    [self defaultLayout];
    [_menuCollectionView layoutIfNeeded];
    [_menuCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)setupViews {
    self.backgroundColor = TUIChatDynamicColor(@"chat_input_controller_bg_color", @"#EBF0F6");

    _menuFlowLayout = [[TUICollectionRTLFitFlowLayout alloc] init];
    _menuFlowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _menuFlowLayout.minimumLineSpacing = 0;
    _menuFlowLayout.minimumInteritemSpacing = 0;
    //_menuFlowLayout.headerReferenceSize = CGSizeMake(TMenuView_Margin, 1);

    _menuCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_menuFlowLayout];
    [_menuCollectionView registerClass:[TUIMenuCell class] forCellWithReuseIdentifier:TMenuCell_ReuseId];
    [_menuCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:TMenuCell_Line_ReuseId];
    _menuCollectionView.collectionViewLayout = _menuFlowLayout;
    _menuCollectionView.delegate = self;
    _menuCollectionView.dataSource = self;
    _menuCollectionView.showsHorizontalScrollIndicator = NO;
    _menuCollectionView.showsVerticalScrollIndicator = NO;
    _menuCollectionView.backgroundColor = self.backgroundColor;
    _menuCollectionView.alwaysBounceHorizontal = YES;
    _menuCollectionView.backgroundColor = TUIChatDynamicColor(@"chat_input_controller_bg_color", @"#EBF0F6");
    [self addSubview:_menuCollectionView];
}

- (void)defaultLayout {
    [_menuCollectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(0);
        make.trailing.mas_equalTo(self.mas_trailing).mas_offset(0);
        make.height.mas_equalTo(40);
        make.centerY.mas_equalTo(self);
    }];
}

- (void)sendUpInside:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(menuViewDidSendMessage:)]) {
        [_delegate menuViewDidSendMessage:self];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _data.count * 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 0) {
        TUIMenuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:TMenuCell_ReuseId forIndexPath:indexPath];
        [cell setData:_data[indexPath.row / 2]];
        return cell;
    } else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:TMenuCell_Line_ReuseId forIndexPath:indexPath];
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 != 0) {
        return;
    }
    for (NSInteger i = 0; i < _data.count; ++i) {
        TUIMenuCellData *data = _data[i];
        data.isSelected = (i == indexPath.row / 2);
    }
    [_menuCollectionView reloadData];
    if (_delegate && [_delegate respondsToSelector:@selector(menuView:didSelectItemAtIndex:)]) {
        [_delegate menuView:self didSelectItemAtIndex:indexPath.row / 2];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 0) {
        CGFloat wh = collectionView.frame.size.height;
        return CGSizeMake(wh, wh);
    } else {
        return CGSizeMake(TLine_Heigh, collectionView.frame.size.height);
    }
}

- (void)scrollToMenuIndex:(NSInteger)index {
    for (NSInteger i = 0; i < _data.count; ++i) {
        TUIMenuCellData *data = _data[i];
        data.isSelected = (i == index);
    }
    [_menuCollectionView reloadData];
}
@end
