//
//  OSFileSearchResultsController.h
//  FileBrowser
//
//  Created by Swae on 2017/11/20.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSFileAttributeItem;

@interface OSFileSearchResultsController : UIViewController <UISearchResultsUpdating>

// 存放搜索列表中显示数据的数组
@property (nonatomic, strong) NSMutableArray<OSFileAttributeItem *> *arrOfSeachResults;
@property (nonatomic, strong) NSArray<OSFileAttributeItem *> *files;
@property (nonatomic, weak) UISearchController *searchController;

@end
