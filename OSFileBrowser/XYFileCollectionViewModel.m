//
//  XYFileCollectionViewModel.m
//  FileBrowserLib
//
//  Created by xiaoyuan on 2018/2/20.
//  Copyright © 2018年 alpface. All rights reserved.
//

#import "XYFileCollectionViewModel.h"
#import "XYFileCollectionViewCell.h"
#import "XYFileCollectionHeaderView.h"

static NSString * const reuseIdentifier = @"XYFileCollectionViewCell";

@interface XYFileCollectionViewModel () <UICollectionViewDataSource, UICollectionViewDelegate, XYFileCollectionViewCellDelegate, XYFileCollectionHeaderViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSMutableArray<XYFileCollectionSection *> *sectionItems;

@end

@implementation XYFileCollectionViewModel

- (void)setCollectionView:(UICollectionView *)collectionView {
    if (_collectionView == collectionView) {
        return;
    }
    _collectionView = collectionView;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[XYFileCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [_collectionView registerClass:[XYFileCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:XYFileCollectionHeaderViewDefaultIdentifier];
}

- (void)initDataSource:(NSArray<XYFileCollectionSection *> *(^)(void))dataSource completion:(void (^)(void))completion {
    
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
    XYFileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    NSArray *files = self.sectionItems[indexPath.section].items;
    cell.fileModel = files[indexPath.row];
    if (cell.fileModel.status == XYFileAttributeItemStatusChecked) {
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
        XYFileCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:XYFileCollectionHeaderViewDefaultIdentifier forIndexPath:indexPath];
        headerView.delegate = self;
        return headerView;
    }
    
    return nil;
}


#pragma mark *** XYFileCollectionViewCellDelegate ***

- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell fileAttributeChangeWithOldFile:(XYFileAttributeItem *)oldFile newFile:(XYFileAttributeItem *)newFile {
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
    NSUInteger foudIdx = [files indexOfObjectPassingTest:^BOOL(XYFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [newFile.path isEqualToString:obj.path];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    if (files && foudIdx != NSNotFound) {
        XYFileAttributeItem *newItem = [files objectAtIndex:foudIdx];
        [files replaceObjectAtIndex:foudIdx withObject:newItem];
        
    }
    else {
        [files addObject:newFile];
    }
    [self reloadCollectionData];
}

- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell needCopyFile:(XYFileAttributeItem *)fileModel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:needCopyFile:)]) {
        [self.delegate collectionViewModel:self needCopyFile:fileModel];
    }
}

- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell needDeleteFile:(XYFileAttributeItem *)fileModel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:needDeleteFile:)]) {
        [self.delegate collectionViewModel:self needDeleteFile:fileModel];
    }
}

- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell didMarkupFile:(XYFileAttributeItem *)fileModel {
    [self didMarkOrCancelMarkFile:fileModel cancelMark:NO];
}

- (void)fileCollectionViewCell:(XYFileCollectionViewCell *)cell didCancelMarkupFile:(XYFileAttributeItem *)fileModel {
    [self didMarkOrCancelMarkFile:fileModel cancelMark:YES];
    
}

- (void)didMarkOrCancelMarkFile:(XYFileAttributeItem *)fileModel cancelMark:(BOOL)isCancelMark {
    [[NSNotificationCenter defaultCenter] postNotificationName:XYFileCollectionViewControllerDidMarkupFileNotification object:fileModel userInfo:@{@"isCancelMark": @(isCancelMark), @"file": fileModel.mutableCopy}];
    [self reloadCollectionData];
}

#pragma mark *** XYFileCollectionHeaderViewDelegate ***

- (void)fileCollectionHeaderView:(XYFileCollectionHeaderView *)headerView clickedSearchButton:(UIButton *)searchButton {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewModel:clickedSearchButton:)]) {
        [self.delegate collectionViewModel:self clickedSearchButton:searchButton];
    }
}

- (void)fileCollectionHeaderView:(XYFileCollectionHeaderView *)headerView
          didSelectedSortChanged:(UISegmentedControl *)sortControl
                 currentSortType:(XYFileBrowserSortType)sortType {
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

- (NSMutableArray<XYFileAttributeItem *> *)selectedFiles {
    if (!_selectedFiles) {
        _selectedFiles = @[].mutableCopy;
    }
    return _selectedFiles;
}



- (void)addSelectedFile:(XYFileAttributeItem *)item {
    if (![self.selectedFiles containsObject:item] && !item.isRootDirectory) {
        [self.selectedFiles addObject:item];
    }
}

- (NSMutableArray<XYFileAttributeItem *> *)getItemsWithSection:(NSInteger)section {
    if (self.sectionItems.count == 0) {
        return nil;
    }
    return self.sectionItems[section].items;
}

- (XYFileCollectionSection *)getSectionWithIdentifier:(NSString *)identifier {
    if (identifier == nil || self.sectionItems.count == 0) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    XYFileCollectionSection *sec = [self.sectionItems filteredArrayUsingPredicate:predicate][0];
    return sec;
    
}

- (NSMutableArray<XYFileAttributeItem *> *)getItemsWithSectionIdentifier:(NSString *)identifier {
    XYFileCollectionSection *sec = [self getSectionWithIdentifier:identifier];
    return sec.items;
}

- (XYFileAttributeItem *)getItemByFilePath:(NSString *)path {
    XYFileCollectionSection *sec = [self getSectionWithIdentifier:@"files"];
    NSUInteger foundIdx = [sec.items indexOfObjectPassingTest:^BOOL(XYFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj.path isEqualToString:path];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    
    XYFileAttributeItem *newItem = nil;
    if (sec && foundIdx != NSNotFound) {
        newItem = sec.items[foundIdx];
    }
    else {
        NSError *error = nil;
        newItem = [XYFileAttributeItem fileWithPath:path error:&error];
    }
    return newItem;
}

/// 根据完整路径创建一个新的XYFileAttributeItem，此方法适用于从本地获取新文件时使用，部分属性还是要使用oldItem中的，比如是否为选中、编辑状态
- (XYFileAttributeItem *)createNewItemWithNewPath:(NSString *)fullPath isHideDisplayFile:(BOOL)hideDisplayFile {
    XYFileCollectionSection *sec = [self getSectionWithIdentifier:@"files"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", fullPath];
    NSArray *filters = [sec.items filteredArrayUsingPredicate:predicate];
    XYFileAttributeItem *oldItem = filters.firstObject;
    //    if (oldItem) {
    //        return oldItem;
    //    }
    NSError *error = nil;
    XYFileAttributeItem *newItem = [XYFileAttributeItem fileWithPath:fullPath hideDisplayFiles:hideDisplayFile error:&error];
    if (newItem) {
        if (self.mode == XYFileCollectionViewControllerModeEdit) {
            newItem.status = XYFileAttributeItemStatusEdit;
        }
        if (oldItem) {
            newItem.status = oldItem.status;
            newItem.needReLoyoutItem = oldItem.needReLoyoutItem;
        }
    }
    return newItem;
}


@end

