//
//  XYFileBrowserAppearanceConfigs.m
//  FileDownloader
//
//  Created by xiaoyuan on 04/12/2017.
//  Copyright © 2017 alpface. All rights reserved.
//

#import "XYFileBrowserAppearanceConfigs.h"

static NSString * const XYFileBrowserAppearanceConfigsSortType = @"XYFileBrowserAppearanceConfigsSortType";
NSNotificationName const XYFileBrowserAppearanceConfigsSortTypeDidChangeNotification = @"XYFileBrowserAppearanceConfigsSortTypeDidChangeNotification";
NSNotificationName const XYFileCollectionViewControllerOptionFileCompletionNotification = @"OptionFileCompletionNotification";
NSNotificationName const XYFileCollectionViewControllerOptionSelectedFileForCopyNotification = @"OptionSelectedFileForCopyNotification";
NSNotificationName const XYFileCollectionViewControllerOptionSelectedFileForMoveNotification = @"OptionSelectedFileForMoveNotification";
NSNotificationName const XYFileCollectionViewControllerDidMarkupFileNotification = @"XYFileCollectionViewControllerDidMarkupFileNotification";
NSNotificationName const XYFileCollectionViewControllerNeedOpenDownloadPageNotification = @"XYFileCollectionViewControllerNeedOpenDownloadPageNotification";

@implementation XYFileBrowserAppearanceConfigs

+ (XYFileBrowserSortType)fileSortType {
    NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:XYFileBrowserAppearanceConfigsSortType];
    if (!num) {
        return XYFileBrowserSortTypeOrderA_To_Z;
    }
    return (XYFileBrowserSortType)[num integerValue];
}

+ (void)setFileSortType:(XYFileBrowserSortType)fileSortType {
    if (fileSortType == [self fileSortType]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(fileSortType) forKey:XYFileBrowserAppearanceConfigsSortType];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:XYFileBrowserAppearanceConfigsSortTypeDidChangeNotification object:@(fileSortType)];
}

@end
