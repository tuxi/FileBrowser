//
//  OSFileCollectionViewModel.h
//  FileBrowserLib
//
//  Created by xiaoyuan on 2018/2/20.
//  Copyright © 2018年 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSFileCollectionSection.h"
#import "OSFileBrowserAppearanceConfigs.h"

@class OSFileCollectionViewModel;

@protocol OSFileCollectionViewModelDelegate <NSObject>

@optional
- (void)collectionViewModel:(OSFileCollectionViewModel *)collectionViewModel didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionViewModel:(OSFileCollectionViewModel *)collectionViewModel didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionViewModel:(OSFileCollectionViewModel *)collectionViewModel needCopyFile:(OSFileAttributeItem *)fileItem;
- (void)collectionViewModel:(OSFileCollectionViewModel *)collectionViewModel needDeleteFile:(OSFileAttributeItem *)fileItem;
- (void)collectionViewModel:(OSFileCollectionViewModel *)collectionViewModel clickedSearchButton:(UIButton *)searchButton;
- (void)collectionViewModel:(OSFileCollectionViewModel *)collectionViewModel sortTypeChanged:(UISegmentedControl *)sortControl currentSortType:(OSFileBrowserSortType)sortType;
- (void)reloadCollectionDataForCollectionViewModel:(OSFileCollectionViewModel *)collectionViewModel;

@end

@interface OSFileCollectionViewModel : NSObject

@property (nonatomic, assign) OSFileCollectionViewControllerMode mode;
@property (nonatomic, strong) NSMutableArray<OSFileAttributeItem *> *selectedFiles;
@property (nonatomic, strong) NSMutableArray<NSString *> *filePathArray;
@property (nonatomic, weak) id<OSFileCollectionViewModelDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray<OSFileCollectionSection *> *sectionItems;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

- (void)initDataSource:(NSArray<OSFileCollectionSection *> *(^)(void))dataSource completion:(void (^)(void))completion;

- (void)addSelectedFile:(OSFileAttributeItem *)item;

- (NSMutableArray<OSFileAttributeItem *> *)getItemsWithSection:(NSInteger)section;
- (NSMutableArray<OSFileAttributeItem *> *)getItemsWithSectionIdentifier:(NSString *)identifier;
- (OSFileCollectionSection *)getSectionWithIdentifier:(NSString *)identifier;
- (OSFileAttributeItem *)getItemByFilePath:(NSString *)path;
/// 根据完整路径创建一个新的OSFileAttributeItem，此方法适用于从本地获取新文件时使用，部分属性还是要使用oldItem中的，比如是否为选中、编辑状态
- (OSFileAttributeItem *)createNewItemWithNewPath:(NSString *)fullPath isHideDisplayFile:(BOOL)hideDisplayFile;

@end
