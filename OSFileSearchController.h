//
//  OSFileSearchController.h
//  FileBrowser
//
//  Created by Swae on 2017/11/20.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSFileAttributeItem;

@interface OSFileSearchController : UIViewController

// 存放原始数据的数组
@property (nonatomic, strong) NSArray<OSFileAttributeItem *> *files;

@end
