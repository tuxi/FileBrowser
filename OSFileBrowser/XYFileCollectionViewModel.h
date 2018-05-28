//
//  XYFileCollectionViewModel.h
//  FileBrowserLib
//
//  Created by xiaoyuan on 2018/2/20.
//  Copyright © 2018年 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYFileCollectionSection.h"
#import "XYFileBrowserAppearanceConfigs.h"

@class XYFileCollectionViewModel;

@protocol XYFileCollectionViewModelDelegate <NSObject>

@optional
- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel needCopyFile:(XYFileAttributeItem *)fileItem;
- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel needDeleteFile:(XYFileAttributeItem *)fileItem;
- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel clickedSearchButton:(UIButton *)searchButton;
- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel sortTypeChanged:(UISegmentedControl *)sortControl currentSortType:(XYFileBrowserSortType)sortType;
- (void)reloadCollectionDataForCollectionViewModel:(XYFileCollectionViewModel *)collectionViewModel;

@end

@interface XYFileCollectionViewModel : NSObject

@property (nonatomic, assign) XYFileCollectionViewControllerMode mode;
@property (nonatomic, strong) NSMutableArray<XYFileAttributeItem *> *selectedFiles;
@property (nonatomic, strong) NSMutableArray<NSString *> *filePathArray;
@property (nonatomic, weak) id<XYFileCollectionViewModelDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray<XYFileCollectionSection *> *sectionItems;
@property (nonatomic, weak) UICollectionView *collectionView;

- (void)initDataSource:(NSArray<XYFileCollectionSection *> *(^)(void))dataSource completion:(void (^)(void))completion;

- (void)addSelectedFile:(XYFileAttributeItem *)item;

- (NSMutableArray<XYFileAttributeItem *> *)getItemsWithSection:(NSInteger)section;
- (NSMutableArray<XYFileAttributeItem *> *)getItemsWithSectionIdentifier:(NSString *)identifier;
- (XYFileCollectionSection *)getSectionWithIdentifier:(NSString *)identifier;
- (XYFileAttributeItem *)getItemByFilePath:(NSString *)path;
/// 根据完整路径创建一个新的XYFileAttributeItem，此方法适用于从本地获取新文件时使用，部分属性还是要使用oldItem中的，比如是否为选中、编辑状态
- (XYFileAttributeItem *)createNewItemWithNewPath:(NSString *)fullPath isHideDisplayFile:(BOOL)hideDisplayFile;

@end

