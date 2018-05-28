//
//  XYFileCollectionViewCell.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XYFileAttributeItem, XYFileCollectionViewCell;

@protocol XYFileCollectionViewCellDelegate <NSObject>

@optional
- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell fileAttributeChangeWithOldFile:(XYFileAttributeItem *)oldFile newFile:(XYFileAttributeItem  *)newFile;
- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell needCopyFile:(XYFileAttributeItem *)fileModel;
- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell needDeleteFile:(XYFileAttributeItem *)fileModel;
- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell didMarkupFile:(XYFileAttributeItem *)fileModel;
- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell didCancelMarkupFile:(XYFileAttributeItem *)fileModel;

@end

@interface XYFileCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) XYFileAttributeItem *fileModel;
@property (nonatomic, weak) id<XYFileCollectionViewCellDelegate> delegate;

/// 重新布局
- (void)invalidateConstraints;

@end

