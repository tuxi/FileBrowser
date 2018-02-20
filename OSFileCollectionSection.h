//
//  OSFileCollectionSection.h
//  FileBrowserLib
//
//  Created by xiaoyuan on 2018/2/20.
//  Copyright © 2018年 alpface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSFileAttributeItem.h"

@interface OSFileCollectionSection : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<OSFileAttributeItem *> *items;
@property (nonatomic, copy) NSString *identifier;
- (instancetype)initWithItems:(NSArray *)items;

@end
