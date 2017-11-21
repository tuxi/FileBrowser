//
//  OSFileSearchResultsController.m
//  FileBrowser
//
//  Created by Swae on 2017/11/20.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import "OSFileSearchResultsController.h"
#import "OSFileAttributeItem.h"
#import "NSString+OSContainsEeachCharacter.h"
#import "OSFileCollectionViewFlowLayout.h"
#import "OSFileCollectionViewCell.h"
#import "OSFilePreviewViewController.h"
#import "OSFileCollectionViewController.h"
#import "MBProgressHUD+BBHUD.h"

@interface OSFileSearchCollectionHeaderView : UICollectionReusableView

@end

@implementation OSFileSearchCollectionHeaderView

@end

static NSString * const kSearchCellIdentifier = @"OSFileSearchResultsController";

@interface OSFileSearchResultsController () <UICollectionViewDelegate, UICollectionViewDataSource, QLPreviewControllerDataSource, QLPreviewControllerDelegate>


@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) OSFileCollectionViewFlowLayout *flowLayout;

@end

@implementation OSFileSearchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
}

- (void)setupViews {
    
    [self.view addSubview:self.collectionView];
    [self makeCollectionViewConstr];
}




////////////////////////////////////////////////////////////////////////
#pragma mark - UISearchResultsUpdating
////////////////////////////////////////////////////////////////////////

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    //获取搜索框中用户输入的字符串
    NSString *searchString = [searchController.searchBar text];
    //指定过滤条件，SELF表示要查询集合中对象，contain[c]表示包含字符串，%@是字符串内容
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchString];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if ([evaluatedObject isKindOfClass:[NSString class]]) {
            //return [(NSString *)evaluatedObject containsString:searchString];
            return [(NSString *)evaluatedObject containsEachCharacter:searchString];
        } else if ([evaluatedObject isKindOfClass:[NSDictionary class]]) {
            //return [evaluatedObject[@"nick"] containsString:searchString];
            return [evaluatedObject[@"nick"] containsEachCharacter:searchString];
        } else if ([evaluatedObject isKindOfClass:[OSFileAttributeItem class]]) {
            //return [evaluatedObject[@"nick"] containsString:searchString];
            return [((OSFileAttributeItem*)evaluatedObject).displayName containsEachCharacter:searchString];
        }
        return [evaluatedObject containsObject:searchString];
    }];
    //如果搜索数组中存在对象，即上次搜索的结果，则清除这些对象
    if (self.arrOfSeachResults != nil) {
        [self.arrOfSeachResults removeAllObjects];
    }
    //通过过滤条件过滤数据
    self.arrOfSeachResults = [[self.files filteredArrayUsingPredicate:predicate] mutableCopy];
    //刷新表格
    [self.collectionView reloadData];
}

#pragma mark *** UICollectionViewDataSource ***

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.arrOfSeachResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OSFileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSearchCellIdentifier forIndexPath:indexPath];
    
    // 显示搜索结果
    OSFileAttributeItem *searchResult = self.arrOfSeachResults[indexPath.row];
    // 原始搜索结果字符串.
    NSString *originResult = searchResult.displayName;
    
    /*
     // 获取关键字的位置
     NSRange range = [originResult rangeOfString:self.searchController.searchBar.text];
     // 转换成可以操作的字符串类型.
     NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:originResult];
     
     // 添加属性(粗体)
     [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:range];
     // 关键字高亮
     [attribute addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
     */
    
    // 转换成可以操作的字符串类型.
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:originResult];
    for (NSValue *rangeValue in [originResult rangeArrayOfEachCharacter:self.searchController.searchBar.text]) {
        // 获取关键字的位置
        NSRange range;
        [rangeValue getValue:&range];
        
        // 添加属性(粗体)
        [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:range];
        // 关键字高亮
        [attribute addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
    }
    
    // 将带属性的字符串添加到cell.textLabel上.
    cell.fileModel.displayNameAttributedText = attribute;

    cell.fileModel = self.files[indexPath.row];
    
    if (cell.fileModel.status == OSFileAttributeItemStatusChecked) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    else {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    [self showDetailController:vc atIndexPath:indexPath];
    if ([vc isKindOfClass:[OSPreviewViewController class]]) {
        OSPreviewViewController *pvc = (OSPreviewViewController *)vc;
        pvc.currentPreviewItemIndex = indexPath.item;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        OSFileSearchCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"OSFileSearchCollectionHeaderView" forIndexPath:indexPath];
        UISearchBar *searchBar = self.searchController.searchBar;
        if (searchBar) {
            [headerView addSubview:searchBar];
            searchBar.frame = headerView.bounds;
//            searchBar.translatesAutoresizingMaskIntoConstraints = NO;
//            NSArray *constraints = @[[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchBar]|" options:kNilOptions metrics:nil views:@{@"searchBar": searchBar}],
//                                     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar]|" options:kNilOptions metrics:nil views:@{@"searchBar": searchBar}]];
//            [NSLayoutConstraint activateConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
        }
       
        return headerView;
    }
    return nil;
}

#pragma mark *** QLPreviewControllerDataSource ***

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    
    return YES;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.files.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger) index {
    NSString *newPath = self.files[index].path;
    
    return [NSURL fileURLWithPath:newPath];
}

#pragma mark *** QLPreviewControllerDelegate ***

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView * _Nullable * __nonnull)view {
    return self.view.frame;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || !self.files.count) {
        return nil;
    }
    OSFileAttributeItem *newItem = self.files[indexPath.row];
    return [self previewControllerWithFileItem:newItem];
}

- (UIViewController *)previewControllerWithFileItem:(OSFileAttributeItem *)newItem {
    if (newItem) {
        BOOL isDirectory;
        BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newItem.path isDirectory:&isDirectory];
        UIViewController *vc = nil;
        if (fileExists) {
            if (newItem.isDirectory) {
                vc = [[OSFileCollectionViewController alloc] initWithRootDirectory:newItem.path controllerMode:OSFileCollectionViewControllerModeDefault];
                
            }
            else if ([OSFilePreviewViewController canOpenFile:newItem.path]) {
                vc = [[OSFilePreviewViewController alloc] initWithFileItem:newItem];
            }
            else if ([OSPreviewViewController canPreviewItem:[NSURL fileURLWithPath:newItem.path]]) {
                OSPreviewViewController *preview= [[OSPreviewViewController alloc] init];
                preview.dataSource = self;
                preview.delegate = self;
                vc = preview;
            }
            else {
                [self.view bb_showMessage:@"无法识别的文件"];
            }
        }
        return vc;
    }
    return nil;
}

- (void)showDetailController:(UIViewController *)viewController parentPath:(NSString *)parentPath {
    if (!viewController) {
        return;
    }
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
    UINavigationController *nac = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self showDetailViewController:nac sender:self];

}

- (void)showDetailController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath {
    NSString *newPath = self.files[indexPath.row].path;
    if (!newPath.length) {
        return;
    }
    [self showDetailController:viewController parentPath:newPath];
}

- (void)backButtonClick {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - lazy
////////////////////////////////////////////////////////////////////////


- (OSFileCollectionViewFlowLayout *)flowLayout {
    
    if (_flowLayout == nil) {
        
        OSFileCollectionViewFlowLayout *layout = [OSFileCollectionViewFlowLayout new];
        _flowLayout = layout;
        [self updateCollectionViewFlowLayout:_flowLayout];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionsStartOnNewLine = NO;
        layout.headerSize = CGSizeMake(self.view.bounds.size.width, 44.0);
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        [collectionView registerClass:[OSFileCollectionViewCell class] forCellWithReuseIdentifier:kSearchCellIdentifier];
        [collectionView registerClass:[OSFileSearchCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"OSFileSearchCollectionHeaderView"];
        _collectionView = collectionView;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 20.0, 0);
        _collectionView.keyboardDismissMode = YES;
        
    }
    return _collectionView;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
- (void)updateCollectionViewFlowLayout:(OSFileCollectionViewFlowLayout *)flowLayout {
    if ([OSFileCollectionViewFlowLayout collectionLayoutStyle] == YES) {
        flowLayout.itemSpacing = 10.0;
        flowLayout.lineSpacing = 10.0;
        flowLayout.lineItemCount = 1;
        flowLayout.lineMultiplier = 0.12;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.left = 0.0;
        contentInset.right = 0.0;
        _collectionView.contentInset = contentInset;
    }
    else {
        flowLayout.itemSpacing = 20.0;
        flowLayout.lineSpacing = 20.0;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.left = 20.0;
        contentInset.right = 20.0;
        _collectionView.contentInset = contentInset;
        flowLayout.lineMultiplier = 1.19;
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                flowLayout.lineItemCount = 10;
            }
            else {
                flowLayout.lineItemCount = 5;
            }
            
        }
        else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                flowLayout.lineItemCount = 6;
            }
            else {
                flowLayout.lineItemCount = 3;
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Layout
////////////////////////////////////////////////////////////////////////
- (void)makeCollectionViewConstr {
    
//    if (@available(iOS 11.0, *)) {
//        NSLayoutConstraint *top = [self.collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
//        NSLayoutConstraint *left = [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
//        NSLayoutConstraint *right = [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
//        NSLayoutConstraint *bottom = [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
//        [NSLayoutConstraint activateConstraints:@[top, left, right, bottom]];
//    } else {
        NSDictionary *views = NSDictionaryOfVariableBindings(_collectionView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_collectionView]|" options:0 metrics:nil views:views]];
//    }
}

@end
