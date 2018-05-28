//
//  XYFileCollectionSection.m
//  FileBrowserLib
//
//  Created by xiaoyuan on 2018/2/20.
//  Copyright © 2018年 alpface. All rights reserved.
//

#import "XYFileCollectionSection.h"

@implementation XYFileCollectionSection

@synthesize items = _items;

- (instancetype)initWithItems:(NSArray *)items {
    if (self = [super init]) {
        _items = items.mutableCopy;
    }
    return self;
}

- (NSMutableArray<XYFileAttributeItem *> *)items {
    if (!_items) {
        _items = @[].mutableCopy;
    }
    return _items;
}

@end
