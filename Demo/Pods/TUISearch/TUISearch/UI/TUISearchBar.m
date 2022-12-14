//
//  TUISearchBar.m
//  Pods
//
//  Created by harvy on 2020/12/23.
//

#import "TUISearchBar.h"
#import "TUISearchViewController.h"
#import "TUIGlobalization.h"
#import "TUIDarkModel.h"
#import "UIView+TUILayout.h"
#import "TUICore.h"
#import "TUIDefine.h"

@interface TUISearchBar () <UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isEntrance;
@end

@implementation TUISearchBar
@synthesize delegate;

- (void)setEntrance:(BOOL)isEntrance {
    self.isEntrance = isEntrance;
    [self setupViews];
}

- (void)setupViews
{
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.placeholder = TUIKitLocalizableString(Search); // @"搜索";
    _searchBar.backgroundImage = [UIImage new];
    _searchBar.barTintColor = [UIColor d_colorWithColorLight:[UIColor whiteColor] dark:[UIColor colorWithRed:55/255.0 green:55/255.0 blue:55/255.0 alpha:1.0]];
    _searchBar.showsCancelButton = NO;
    _searchBar.delegate = self;
    _searchBar.showsCancelButton = !self.isEntrance;
    if (@available(iOS 13.0, *)) {
        _searchBar.searchTextField.backgroundColor = [UIColor d_colorWithColorLight:[UIColor whiteColor] dark:[UIColor colorWithRed:55/255.0 green:55/255.0 blue:55/255.0 alpha:1.0]];
    }
    [self addSubview:_searchBar];
    [self enableCancelButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.searchBar.frame = CGRectMake(10, 5, self.mm_w - 10 - 10, self.mm_h - 5 - 5);
}

- (void)showSearchVC {
    TUISearchViewController *vc = [[TUISearchViewController alloc] init];
    TUINavigationController *nav = [[TUINavigationController alloc] initWithRootViewController:(UIViewController *)vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.parentVC presentViewController:nav animated:NO completion:nil];
}

#pragma mark - UISearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [self showSearchVC];
    
    if (self.isEntrance && [self.delegate respondsToSelector:@selector(searchBarDidEnterSearch:)]) {
        [self.delegate searchBarDidEnterSearch:self];
    }
    return !self.isEntrance;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(searchBarDidCancelClicked:)]) {
        [self.delegate searchBarDidCancelClicked:self];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([self.delegate respondsToSelector:@selector(searchBar:searchText:)]) {
        [self.delegate searchBar:self searchText:searchBar.text];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([self.delegate respondsToSelector:@selector(searchBar:searchText:)]) {
        [self.delegate searchBar:self searchText:searchBar.text];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self enableCancelButton];
}

- (void)enableCancelButton
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIButton *cancelBtn = [weakSelf.searchBar valueForKeyPath:@"cancelButton"];
        for (UIButton *view in cancelBtn.subviews) {
            if ([view isKindOfClass:UIButton.class]) {
                view.userInteractionEnabled = YES;
                view.enabled = YES;
            }
        }
        cancelBtn.enabled = YES;
        cancelBtn.userInteractionEnabled = YES;
    });
}


@end
