//
//  XYFileHelper.h
//  FileDownloader
//
//  Created by xiaoyuan on 2017/12/4.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XYFile;

@interface XYFileHelper : NSObject

/// 根据文件名称按照字母A-Z升序排序
/// @param array 需要排序的数组，数组中应该是文件名称
/// @return 返回排序好的数组
+ (NSArray<XYFile *> *)sortByPinYinWithArray:(NSArray<XYFile *> *)array;

/// 根据文件路径，获取文件创建时间，按照时间升序排序
/// @param array 需要排序的数组，数组中应该是文件完整路径
/// @return 返回排序好的数组
+ (NSArray<XYFile *> *)sortByCreateDateWithArray:(NSArray<XYFile *> *)array;

@end
