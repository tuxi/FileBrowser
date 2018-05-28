//
//  XYFileMarkViewController.m
//  FileDownloader
//
//  Created by xiaoyuan on 2017/12/4.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "XYFileMarkViewController.h"
#import "XYFileCollectionViewModel.h"

@interface XYFileMarkViewController ()

@end

@implementation XYFileMarkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markupFileCompletion:) name:XYFileCollectionViewControllerDidMarkupFileNotification object:nil];
}

- (void)markupFileCompletion:(NSNotification *)notification {
   
    NSString *filePath = notification.object;
    if ([filePath isKindOfClass:[NSString class]]) {
        XYFileAttributeItem *file = [[XYFileAttributeItem alloc] initWithPath:filePath error:nil];
        if (file) {
            NSMutableArray *array = self.collectionViewModel.sectionItems.firstObject.items;
            [array insertObject:file atIndex:0];
            [self reloadCollectionData];
        }
    }
}

/// 重新父类方法
- (NSArray *)bottomHUDTitles {
    return @[
             @"全选",
             @"复制",
             @"移动",
             @"删除",
             ];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
