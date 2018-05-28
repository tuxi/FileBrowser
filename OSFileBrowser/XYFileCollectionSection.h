//
//  XYFileCollectionSection.h
//  FileBrowserLib
//
//  Created by xiaoyuan on 2018/2/20.
//  Copyright © 2018年 alpface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYFileAttributeItem.h"

@interface XYFileCollectionSection : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<XYFileAttributeItem *> *items;
@property (nonatomic, copy) NSString *identifier;
- (instancetype)initWithItems:(NSArray *)items;

@end
