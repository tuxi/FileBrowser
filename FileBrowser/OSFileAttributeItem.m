//
//  OSFileAttributeItem.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFileAttributeItem.h"

@implementation OSFileAttributeItem

- (instancetype)initWithPath:(NSString *)filePath hideDisplayFiles:(BOOL)hideDisplayFiles error:(NSError *__autoreleasing *)error {
    if (self = [super initWithPath:filePath hideDisplayFiles:hideDisplayFiles error:error]) {
        _path = filePath;
        self.status = OSFileAttributeItemStatusDefault;
    }
    return self;
}

@end

