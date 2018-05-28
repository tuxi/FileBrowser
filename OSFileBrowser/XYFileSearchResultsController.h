//
//  XYFileSearchResultsController.h
//  FileBrowser
//
//  Created by xiaoyuan on 2017/11/20.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XYFileAttributeItem;

@interface XYFileSearchResultsController : UICollectionViewController <UISearchResultsUpdating>

// 存放搜索列表中显示数据的数组
@property (nonatomic, strong) NSMutableArray<XYFileAttributeItem *> *arrayOfSeachResults;
@property (nonatomic, strong) NSArray<XYFileAttributeItem *> *files;
@property (nonatomic, weak) UISearchController *searchController;

- (instancetype)initWithCollectionViewLayout:(nullable UICollectionViewLayout *)layout;

@end

NS_ASSUME_NONNULL_END
