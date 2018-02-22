//
//  OSFileCollectionViewModel.m
//  FileBrowserLib
//
//  Created by xiaoyuan on 2018/2/20.
//  Copyright © 2018年 alpface. All rights reserved.
//

#import "OSFileCollectionViewModel.h"
#import "OSFileCollectionViewCell.h"
#import "OSFileCollectionHeaderView.h"

static NSString * const reuseIdentifier = @"OSFileCollectionViewCell";

@interface OSFileCollectionViewModel () <UICollectionViewDataSource, UICollectionViewDelegate, OSFileCollectionViewCellDelegate, OSFileCollectionHeaderViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSMutableArray<OSFileCollectionSection *> *sectionItems;

@end

@implementation OSFileCollectionViewModel

- (void)setCollectionView:(UICollectionView *)collectionView {
    if (_collectionView == collectionView) {
        return;
    }
    _collectionView = collectionView;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[OSFileCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [_collectionView registerClass:[OSFileCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:OSFileCollectionHeaderViewDefaultIdentifier];
}

- (void)initDataSource:(NSArray<OSFileCollectionSection *> *(^)(void))dataSource completion:(void (^)(void))completion {
    
    self.sectionItems = dataSource().mutableCopy;
    if (completion) {
        completion();
    }
}

#pragma mark *** UICollectionViewDataSource ***

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sectionItems.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sectionItems[section].items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OSFileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    NSArray *files = self.sectionItems[indexPath.section].items;
    cell.fileModel = files[indexPath.row];
    if (cell.fileModel.status == OSFileAttributeItemStatusChecked) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    else {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:didSelectItemAtIndexPath:)]) {
        [self.delegate collectionViewModel:self didSelectItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:didSelectItemAtIndexPath:)]) {
        [self.delegate collectionViewModel:self didDeselectItemAtIndexPath:indexPath];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        OSFileCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:OSFileCollectionHeaderViewDefaultIdentifier forIndexPath:indexPath];
        headerView.delegate = self;
        return headerView;
    }
    
    return nil;
}


#pragma mark *** OSFileCollectionViewCellDelegate ***

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell fileAttributeChangeWithOldFile:(OSFileAttributeItem *)oldFile newFile:(OSFileAttributeItem *)newFile {
    NSUInteger foundFileIdxFromFilePathArray = [self.filePathArray indexOfObjectPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [oldFile.path isEqualToString:obj];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    NSMutableArray *files = self.sectionItems.firstObject.items;
    if (self.filePathArray && foundFileIdxFromFilePathArray != NSNotFound) {
        [self.filePathArray replaceObjectAtIndex:foundFileIdxFromFilePathArray withObject:newFile.path];
    }
    NSUInteger foudIdx = [files indexOfObjectPassingTest:^BOOL(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [newFile.path isEqualToString:obj.path];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    if (files && foudIdx != NSNotFound) {
        OSFileAttributeItem *newItem = [files objectAtIndex:foudIdx];
        [files replaceObjectAtIndex:foudIdx withObject:newItem];
        
    }
    else {
        [files addObject:newFile];
    }
    [self reloadCollectionData];
}

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell needCopyFile:(OSFileAttributeItem *)fileModel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:needCopyFile:)]) {
        [self.delegate collectionViewModel:self needCopyFile:fileModel];
    }
}

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell needDeleteFile:(OSFileAttributeItem *)fileModel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:needDeleteFile:)]) {
        [self.delegate collectionViewModel:self needDeleteFile:fileModel];
    }
}

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell didMarkupFile:(OSFileAttributeItem *)fileModel {
    [self didMarkOrCancelMarkFile:fileModel cancelMark:NO];
}

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell didCancelMarkupFile:(OSFileAttributeItem *)fileModel {
    [self didMarkOrCancelMarkFile:fileModel cancelMark:YES];
    
}

- (void)didMarkOrCancelMarkFile:(OSFileAttributeItem *)fileModel cancelMark:(BOOL)isCancelMark {
    [[NSNotificationCenter defaultCenter] postNotificationName:OSFileCollectionViewControllerDidMarkupFileNotification object:fileModel userInfo:@{@"isCancelMark": @(isCancelMark), @"file": fileModel.mutableCopy}];
    [self reloadCollectionData];
}

#pragma mark *** OSFileCollectionHeaderViewDelegate ***

- (void)fileCollectionHeaderView:(OSFileCollectionHeaderView *)headerView clickedSearchButton:(UIButton *)searchButton {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:clickedSearchButton:)]) {
        [self.delegate collectionViewModel:self clickedSearchButton:searchButton];
    }
}

- (void)fileCollectionHeaderView:(OSFileCollectionHeaderView *)headerView
          didSelectedSortChanged:(UISegmentedControl *)sortControl
                 currentSortType:(OSFileBrowserSortType)sortType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:sortTypeChanged:currentSortType:)]) {
        [self.delegate collectionViewModel:self sortTypeChanged:sortControl currentSortType:sortType];
    }
}

- (void)reloadCollectionData {
    if (self.delegate && [self.delegate respondsToSelector:@selector(reloadCollectionDataForCollectionViewModel:)]) {
        [self.delegate reloadCollectionDataForCollectionViewModel:self];
    }
}



////////////////////////////////////////////////////////////////////////
#pragma mark - Lazy
////////////////////////////////////////////////////////////////////////

- (NSMutableArray<OSFileAttributeItem *> *)selectedFiles {
    if (!_selectedFiles) {
        _selectedFiles = @[].mutableCopy;
    }
    return _selectedFiles;
}



- (void)addSelectedFile:(OSFileAttributeItem *)item {
    if (![self.selectedFiles containsObject:item] && !item.isRootDirectory) {
        [self.selectedFiles addObject:item];
    }
}

- (NSMutableArray<OSFileAttributeItem *> *)getItemsWithSection:(NSInteger)section {
    if (self.sectionItems.count == 0) {
        return nil;
    }
    return self.sectionItems[section].items;
}

- (OSFileCollectionSection *)getSectionWithIdentifier:(NSString *)identifier {
    if (identifier == nil || self.sectionItems.count == 0) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    OSFileCollectionSection *sec = [self.sectionItems filteredArrayUsingPredicate:predicate][0];
    return sec;
    
}

- (NSMutableArray<OSFileAttributeItem *> *)getItemsWithSectionIdentifier:(NSString *)identifier {
    OSFileCollectionSection *sec = [self getSectionWithIdentifier:identifier];
    return sec.items;
}

- (OSFileAttributeItem *)getItemByFilePath:(NSString *)path {
    OSFileCollectionSection *sec = [self getSectionWithIdentifier:@"files"];
    NSUInteger foundIdx = [sec.items indexOfObjectPassingTest:^BOOL(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj.path isEqualToString:path];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    
    OSFileAttributeItem *newItem = nil;
    if (sec && foundIdx != NSNotFound) {
        newItem = sec.items[foundIdx];
    }
    else {
        NSError *error = nil;
        newItem = [OSFileAttributeItem fileWithPath:path error:&error];
    }
    return newItem;
}

/// 根据完整路径创建一个新的OSFileAttributeItem，此方法适用于从本地获取新文件时使用，部分属性还是要使用oldItem中的，比如是否为选中、编辑状态
- (OSFileAttributeItem *)createNewItemWithNewPath:(NSString *)fullPath isHideDisplayFile:(BOOL)hideDisplayFile {
    OSFileCollectionSection *sec = [self getSectionWithIdentifier:@"files"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", fullPath];
    NSArray *filters = [sec.items filteredArrayUsingPredicate:predicate];
    OSFileAttributeItem *oldItem = filters.firstObject;
    //    if (oldItem) {
    //        return oldItem;
    //    }
    NSError *error = nil;
    OSFileAttributeItem *newItem = [OSFileAttributeItem fileWithPath:fullPath hideDisplayFiles:hideDisplayFile error:&error];
    if (newItem) {
        if (self.mode == OSFileCollectionViewControllerModeEdit) {
            newItem.status = OSFileAttributeItemStatusEdit;
        }
        if (oldItem) {
            newItem.status = oldItem.status;
            newItem.needReLoyoutItem = oldItem.needReLoyoutItem;
        }
    }
    return newItem;
}


@end

