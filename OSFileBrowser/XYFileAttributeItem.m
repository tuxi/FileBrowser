//
//  XYFileAttributeItem.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "XYFileAttributeItem.h"
#import "NSString+XYFile.h"
#import "UIImage+XYImage.h"

@implementation XYFileAttributeItem

- (instancetype)initWithPath:(NSString *)filePath hideDisplayFiles:(BOOL)hideDisplayFiles error:(NSError *__autoreleasing *)error {
    if (self = [super initWithPath:filePath hideDisplayFiles:hideDisplayFiles error:error]) {
        _path = filePath;
        self.status = XYFileAttributeItemStatusDefault;
        self.needReLoyoutItem = NO;
    }
    return self;
}

- (NSString *)displayName {
    if ([self.path isEqualToString:[NSString getDocumentPath]]) {
        return @"iTunes文件";
    }
    else if ([self isDownloadBrowser]) {
        return @"缓存";
    }
    else if ([self.path isEqualToString:[NSString getICloudCacheFolder]]) {
        return @"iCloud Drive";
    }
    return [super displayName];
}

- (UIImage *)icon {
    if ([self.path isEqualToString:[NSString getICloudCacheFolder]]) {
        return [UIImage XYFileBrowserImageNamed:@"table-folder-icloud"];
    }
    else if ([self.path isEqualToString:[NSString getDocumentPath]]) {
        return [UIImage XYFileBrowserImageNamed:@"table-folder-itunes-files-sharing"];
    }
    return [super icon];
}

- (BOOL)isRootDirectory {
    if ([self.path isEqualToString:[NSString getDocumentPath]]) {
        return YES;
    }
    else if ([self.path isEqualToString:[NSString getRootPath]]) {
        return YES;
    }
    else if ([self.path isEqualToString:[NSString getICloudCacheFolder]]) {
        return YES;
    }
    return _isRootDirectory;
}

- (BOOL)isDownloadBrowser {
    return [self.path isEqualToString:[NSString getDownloadDisplayFolderPath]];
}

- (BOOL)isICloudDrive {
    return [self.path isEqualToString:[NSString getICloudCacheFolder]];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    XYFileAttributeItem *file = [super mutableCopyWithZone:zone];
    file.status = self.status;
    file.isRootDirectory = self.isRootDirectory;
    file.needReLoyoutItem = self.needReLoyoutItem;
    file.displayNameAttributedText = self.displayNameAttributedText;
    return file;
}

@end

