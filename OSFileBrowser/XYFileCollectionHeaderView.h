//
//  XYFileCollectionHeaderView.h
//  FileDownloader
//
//  Created by xiaoyuan on 2017/11/19.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYFileCollectionViewFlowLayout.h"
#import "XYFileBrowserAppearanceConfigs.h"

FOUNDATION_EXPORT NSString * const XYFileCollectionHeaderViewDefaultIdentifier;

@class XYFileCollectionHeaderView, XYFileCollectionViewFlowLayout;

@protocol XYFileCollectionHeaderViewDelegate <NSObject>

@optional
- (void)fileCollectionHeaderView:(XYFileCollectionHeaderView *)headerView
                   reLayoutStyle:(XYFileCollectionLayoutStyle)style;
- (void)fileCollectionHeaderView:(XYFileCollectionHeaderView *)headerView
             clickedSearchButton:(UIButton *)searchButton;
- (void)fileCollectionHeaderView:(XYFileCollectionHeaderView *)headerView
          didSelectedSortChanged:(UISegmentedControl *)sortControl currentSortType:(XYFileBrowserSortType)sortType;

@end

@interface XYFileCollectionHeaderView : UICollectionReusableView

@property (nonatomic, weak) id<XYFileCollectionHeaderViewDelegate> delegate;


@end
