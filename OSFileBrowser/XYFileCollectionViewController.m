//
//  XYFileCollectionViewController.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "XYFileCollectionViewController.h"
#import "XYFileCollectionViewCell.h"
#import "XYFileCollectionViewFlowLayout.h"
#import "DirectoryWatcher.h"
#import "OSFileManager.h"
#import "XYFileAttributeItem.h"
#import "UIScrollView+NoDataExtend.h"
#import "XYFileBottomHUD.h"
#import "NSString+XYFile.h"
#import "UIViewController+XYExtensions.h"
#import "UIImage+XYImage.h"
#import "MBProgressHUD+XYHUD.h"
#import "XYFileCollectionHeaderView.h"
#import "XYFileSearchResultsController.h"
#import "UIScrollView+RollView.h"
#import "XYFileHelper.h"
#import "XYFilePreviewViewController.h"
#import "XYFileCollectionViewModel.h"


typedef NS_ENUM(NSInteger, XYFileLoadType) {
    XYFileLoadTypeCurrentDirectory,
    XYFileLoadTypeSubDirectory,
};


static const CGFloat windowHeight = 49.0;

#ifdef __IPHONE_9_0
@interface XYFileCollectionViewController () <UIViewControllerPreviewingDelegate, NoDataPlaceholderDelegate, XYFileBottomHUDDelegate, UISearchBarDelegate, UISearchControllerDelegate, XYRollViewScrollDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, XYFileCollectionViewModelDelegate>
#else
@interface XYFileCollectionViewController () <NoDataPlaceholderDelegate, XYFileBottomHUDDelegate, UISearchBarDelegate, UISearchControllerDelegate>
#endif

{
    NSString *_newFolderName;
}

@property (nonatomic, strong) XYFileCollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSOperationQueue *loadFileQueue;
@property (nonatomic, strong) OSFileManager *fileManager;
@property (nonatomic, assign) XYFileLoadType fileLoadType;
@property (nonatomic, strong) XYFileBottomHUD *bottomHUD;
@property (nonatomic, weak) UIButton *bottomTipButton;
@property (nonatomic, strong) XYFileAttributeItem *parentDirectoryItem;
@property (nonatomic, strong) NSMutableArray<DirectoryWatcher *> *directoryWatcherArray;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation XYFileCollectionViewController

#pragma mark *** Initializer ***

- (instancetype)initWithDirectory:(NSString *)path {
    return [self initWithDirectory:path controllerMode:XYFileCollectionViewControllerModeDefault];
}

- (instancetype)initWithDirectory:(NSString *)path controllerMode:(XYFileCollectionViewControllerMode)mode {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.fileLoadType = XYFileLoadTypeSubDirectory;
        self.collectionViewModel.mode = mode;
        _hideDisplayFiles = YES;
        self.parentDirectoryItem = [XYFileAttributeItem fileWithPath:path hideDisplayFiles:_hideDisplayFiles error:nil];
        [self commonInit];
        
    }
    return self;
}

- (instancetype)initWithFilePathArray:(NSArray *)filePathArray {
    return [self initWithFilePathArray:filePathArray controllerMode:XYFileCollectionViewControllerModeDefault];
}

- (instancetype)initWithFilePathArray:(NSArray *)filePathArray controllerMode:(XYFileCollectionViewControllerMode)mode {
    return [self initWithFilePathArray:filePathArray parentItem:nil controllerMode:mode];
}

- (instancetype)initWithFilePathArray:(NSArray *)filePathArray parentItem:(XYFileAttributeItem *)parentItem controllerMode:(XYFileCollectionViewControllerMode)mode {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.fileLoadType = XYFileLoadTypeCurrentDirectory;
        self.collectionViewModel.mode = mode;
        _hideDisplayFiles = YES;
        self.collectionViewModel.filePathArray = filePathArray.mutableCopy;
        self.parentDirectoryItem = parentItem;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _fileManager = [OSFileManager defaultManager];
    _loadFileQueue = [NSOperationQueue new];
    _directoryWatcherArray = [NSMutableArray array];
    
    [self initWatcherFolder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateToInterfaceOrientation) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionFileCompletion:) name:XYFileCollectionViewControllerOptionFileCompletionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionReLayoutStyle) name:XYFileCollectionLayoutStyleDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markupFileCompletion:) name:XYFileCollectionViewControllerDidMarkupFileNotification object:nil];
    
}


/// 初始化需要监听的目录
- (void)initWatcherFolder {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *needWatchPathArray = [NSMutableArray array];
    
    if (self.parentDirectoryItem.path.length) {
        [needWatchPathArray addObject:self.parentDirectoryItem.path];
    }
    
    NSString *documentPath = [NSString getDocumentPath];
    if (![self.parentDirectoryItem.path isEqualToString:documentPath]) {
        [needWatchPathArray addObject:documentPath];
    }
    
    for (NSString *path in self.collectionViewModel.filePathArray) {
        NSUInteger foundIdx = [needWatchPathArray indexOfObjectPassingTest:^BOOL(NSString *  _Nonnull needWatchPath, NSUInteger idx, BOOL * _Nonnull stop) {
            return [path isEqualToString:needWatchPath];
        }];
        if (foundIdx == NSNotFound) {
            [needWatchPathArray addObject:path];
        }
    }
    
    for (NSString *path in needWatchPathArray) {
        DirectoryWatcher *watcher = [DirectoryWatcher watchFolderWithPath:path directoryDidChange:^(DirectoryWatcher *folderWatcher) {
            [weakSelf reloadFiles];
        }];
        if (watcher) {
            [self.directoryWatcherArray addObject:watcher];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
    
    __weak typeof(self) weakSelf = self;
    [self reloadFilesWithCallBack:^{
        [weakSelf showBottomTip];
    }];
    
    self.collectionView.rollingDelegate = self;
    self.collectionView.autoRollCellSpeed = 20;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self check3DTouch];
    
    if ((self.collectionViewModel.mode == XYFileCollectionViewControllerModeCopy ||
         self.collectionViewModel.mode == XYFileCollectionViewControllerModeMove) &&
        self.parentDirectoryItem) {
        [self bottomTipButton].hidden = NO;
    }
    else {
        [self bottomTipButton].hidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.bottomHUD hideHudCompletion:^(XYFileBottomHUD *hud) {
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        _bottomHUD = nil;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.bottom = 20.0;
        self.collectionView.contentInset = contentInset;
    }];
    if (self.collectionViewModel.mode == XYFileCollectionViewControllerModeEdit) {
        [self rightBarButtonClick];
    }
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self bottomTipButton].hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.collectionView.indexPathsForVisibleItems.count) {
            [self reloadCollectionData];
        }
    });
    
}

- (void)dealloc {
    self.bottomHUD = nil;
    [_bottomTipButton removeFromSuperview];
    _bottomTipButton = nil;
    self.collectionViewModel.filePathArray = nil;
    for (DirectoryWatcher *watcher in self.directoryWatcherArray) {
        [watcher invalidate];
    }
    self.directoryWatcherArray = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupViews {
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    
    [self.view addSubview:self.collectionView];
    [self makeCollectionViewConstr];
    [self setupNodataView];
    [self setupSearchController];
    [self setupNavigationBar];
}

/// 搜索功能暂时只支持iOS11
- (void)setupSearchController {
    
    if (@available(iOS 11.0, *)) {
        XYFileSearchResultsController *resultsController = [[XYFileSearchResultsController alloc] initWithCollectionViewLayout:nil];
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:resultsController];
        //设置搜索时，背景变暗色
        self.searchController.dimsBackgroundDuringPresentation = NO;
        // 设置搜索时，背景变模糊
        if (@available(iOS 9.1, *)) {
            self.searchController.obscuresBackgroundDuringPresentation = NO;
        }
        resultsController.searchController = self.searchController;
        self.searchController.searchResultsUpdater = resultsController;
        self.searchController.searchBar.showsCancelButton = YES;
        self.searchController.searchBar.delegate = self;
        self.searchController.delegate = self;
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
        self.navigationItem.searchController = self.searchController;
        
        //        self.searchController.searchBar.tintColor = [UIColor whiteColor];
        //        self.searchController.searchBar.clipsToBounds = YES;
        //        [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTintColor:[UIColor whiteColor]];
        //        [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitle:@"取消"];
        
    }
    
}

- (void)setupNodataView {
    __weak typeof(self) weakSelf = self;
    
    self.collectionView.noDataPlaceholderDelegate = self;
    
    if ([self.parentDirectoryItem isDownloadBrowser]) {
        self.collectionView.noDataDetailTextLabelBlock = ^(UILabel * _Nonnull detailTextLabel) {
            NSAttributedString *string = [weakSelf noDataDetailLabelAttributedString];
            if (!string.length) {
                return;
            }
            detailTextLabel.backgroundColor = [UIColor clearColor];
            detailTextLabel.font = [UIFont systemFontOfSize:17.0];
            detailTextLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
            detailTextLabel.textAlignment = NSTextAlignmentCenter;
            detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            detailTextLabel.numberOfLines = 0;
            detailTextLabel.attributedText = string;
        };
        self.collectionView.noDataImageViewBlock = ^(UIImageView * _Nonnull imageView) {
            imageView.backgroundColor = [UIColor clearColor];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.userInteractionEnabled = NO;
            imageView.image = [weakSelf noDataImageViewImage];
            
        };
        
        self.collectionView.noDataReloadButtonBlock = ^(UIButton * _Nonnull reloadButton) {
            reloadButton.backgroundColor = [UIColor clearColor];
            reloadButton.layer.borderWidth = 0.5;
            reloadButton.layer.borderColor = [UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0].CGColor;
            reloadButton.layer.cornerRadius = 2.0;
            [reloadButton.layer setMasksToBounds:YES];
            [reloadButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [reloadButton setAttributedTitle:[weakSelf noDataReloadButtonAttributedStringWithState:UIControlStateNormal] forState:UIControlStateNormal];
        };
        
        self.collectionView.noDataButtonEdgeInsets = UIEdgeInsetsMake(20, 100, 11, 100);
    }
    self.collectionView.noDataTextLabelBlock = ^(UILabel * _Nonnull textLabel) {
        NSAttributedString *string = [weakSelf noDataTextLabelAttributedString];
        if (!string.length) {
            return;
        }
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = [UIFont systemFontOfSize:27.0];
        textLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        textLabel.numberOfLines = 0;
        textLabel.attributedText = string;
    };
    
    self.collectionView.noDataTextEdgeInsets = UIEdgeInsetsMake(20, 0, 20, 0);
    
    
}

#pragma mark *** NavigationBar ***

- (void)setupNavigationBar {
    
    if (self.parentDirectoryItem) {
        self.navigationItem.title = self.parentDirectoryItem.displayName;
    }
    else {
        self.navigationItem.title = @"文件浏览";
    }
    
    if (!self.isRootDirectory) {
        if (@available(iOS 11.0, *)) {
            // 导航大标题, 上滑到顶部时动态切换大小标题样式 (导航栏高度UINavigationBar = 44/96)
            self.navigationController.navigationBar.prefersLargeTitles = YES;
            // 自动模式,依赖于上一个item的设置; 上一个item设置为自动并且当前导航栏prefersLargeTitles=YES,则显示大标题样式;
            self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
            // prefersLargeTitles=YES,滚动到顶部时,当前总是显示大标题样式
            //        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
            // prefersLargeTitles=YES,滚动到顶部时,当前也总不会显示大标题样式
            //        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        }
        
        
    }
    
    // 如果数组中只有下载文件夹和iTunes文件夹，就不能显示编辑
    BOOL displayEdit = YES;
    if (self.isRootDirectory) {
        displayEdit = NO;
        if ( self.collectionViewModel.mode == XYFileCollectionViewControllerModeCopy ||
            self.collectionViewModel.mode == XYFileCollectionViewControllerModeMove) {
            displayEdit = YES;
        }
    }
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    if (displayEdit && sec.items.count) {
        if (!self.navigationItem.rightBarButtonItem) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonClick)];
        }
        else {
            self.navigationItem.rightBarButtonItem.title = @"编辑";
        }
        
        switch (self.collectionViewModel.mode) {
            case XYFileCollectionViewControllerModeDefault: {
                self.navigationItem.rightBarButtonItem.title = @"编辑";
                break;
            }
            case XYFileCollectionViewControllerModeEdit: {
                self.navigationItem.rightBarButtonItem.title = @"完成";
                break;
            }
            case XYFileCollectionViewControllerModeCopy:
            case XYFileCollectionViewControllerModeMove: {
                self.navigationItem.rightBarButtonItem.title = @"取消";
                break;
            }
            default:
                break;
        }
    }
}

- (void)rightBarButtonClick {
    [self updateMode];
    switch (self.collectionViewModel.mode) {
        case XYFileCollectionViewControllerModeEdit: {
            [self leaveEditModeAction];
            break;
        }
        case XYFileCollectionViewControllerModeDefault: {
            [self enterEditModeAction];
            break;
        }
        case XYFileCollectionViewControllerModeCopy: {
            [self copyModeAction];
            break;
        }
        case XYFileCollectionViewControllerModeMove: {
            [self moveModeAction];
            break;
        }
        default:
            break;
    }
    
}

- (void)updateMode {
    self.collectionView.allowsMultipleSelection = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.collectionViewModel.mode == XYFileCollectionViewControllerModeDefault)  {
        self.collectionViewModel.mode = XYFileCollectionViewControllerModeEdit;
    }
    else if (self.collectionViewModel.mode == XYFileCollectionViewControllerModeEdit) {
        self.collectionViewModel.mode = XYFileCollectionViewControllerModeDefault;
    }
    
    
}

- (void)enterEditModeAction {
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    for (XYFileAttributeItem *item in sec.items) {
        item.status = XYFileAttributeItemStatusDefault;
    }
    [self.collectionView reloadData];
    self.navigationItem.rightBarButtonItem.title = @"编辑";
    
    [self.bottomHUD hideHudCompletion:^(XYFileBottomHUD *hud) {
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        _bottomHUD = nil;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.bottom = 20.0;
        self.collectionView.contentInset = contentInset;
    }];
}

- (void)leaveEditModeAction {
    self.collectionView.allowsMultipleSelection = YES;
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    for (XYFileAttributeItem *item in sec.items) {
        item.status = XYFileAttributeItemStatusEdit;
    }
    [self.collectionView reloadData];
    self.navigationItem.rightBarButtonItem.title = @"完成";
    
    [self.bottomHUD showHUDWithFrame:CGRectMake(0, self.view.frame.size.height - windowHeight, self.view.frame.size.width, windowHeight) completion:^(XYFileBottomHUD *hud) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.bottom = contentInset.bottom + hud.frame.size.height;
        self.collectionView.contentInset = contentInset;
    }];
}

- (void)copyModeAction {
    [self backButtonClick];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)moveModeAction {
    [self backButtonClick];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark *** Load file ***

- (void)loadFileWithFilePathArray:(NSArray<NSString *> *)filePathArray completion:(void (^)(NSArray *fileItems))completion {
    [self.loadFileQueue cancelAllOperations];
    __weak typeof(&*self) weakSelf = self;
    [self.loadFileQueue addOperationWithBlock:^{
        __strong typeof(&*weakSelf) self = weakSelf;
        NSMutableArray *array = @[].mutableCopy;
        [filePathArray enumerateObjectsUsingBlock:^(NSString * _Nonnull fullPath, NSUInteger idx, BOOL * _Nonnull stop) {
            XYFileAttributeItem *newItem = [self.collectionViewModel createNewItemWithNewPath:fullPath isHideDisplayFile:_hideDisplayFiles];
            if (newItem) {
                [array addObject:newItem];
            }
        }];
        
        array = [self sortFilesWithArray:array];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array);
            });
        }
        
    }];
    
    
}

- (void)loadFileWithDirectoryItem:(XYFileAttributeItem *)directoryItem completion:(void (^)(NSArray *fileItems))completion {
    [_loadFileQueue cancelAllOperations];
    __weak typeof(&*self) weakSelf = self;
    [_loadFileQueue addOperationWithBlock:^{
        __strong typeof(&*weakSelf) self = weakSelf;
        NSMutableArray *array = @[].mutableCopy;
        [directoryItem.nameOfSubFiles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *fullPath = [directoryItem.path stringByAppendingPathComponent:obj];
            XYFileAttributeItem *newItem = [self.collectionViewModel createNewItemWithNewPath:fullPath isHideDisplayFile:_hideDisplayFiles];
            if (newItem) {
                [array addObject:newItem];
            }
        }];
        
        array = [self sortFilesWithArray:array];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array);
            });
        }
    }];
}


- (NSMutableArray<XYFileAttributeItem *> *)sortFilesWithArray:(NSArray<XYFileAttributeItem *> *)array {
    XYFileBrowserSortType sortType = [XYFileBrowserAppearanceConfigs fileSortType];
    switch (sortType) {
        case XYFileBrowserSortTypeOrderA_To_Z: {
            array = [XYFileHelper sortByPinYinWithArray:array].mutableCopy;
            break;
        }
        case XYFileBrowserSortTypeOrderLatestTime: {
            array = [XYFileHelper sortByCreateDateWithArray:array].mutableCopy;
            break;
        }
        default:
            break;
    }
    return (NSMutableArray *)array;
}

- (void)reloadFiles {
    [self reloadFilesWithCallBack:nil];
}

- (void)reloadFilesWithCallBack:(void (^)(void))callBack {
    [self.collectionView xy_beginLoading];
    __weak typeof(self) weakSelf = self;
    void (^ reloadCallBack)(NSArray *fileItems) = ^ (NSArray *fileItems){
        XYFileCollectionSection *fileSec = [[XYFileCollectionSection alloc] initWithItems:fileItems];
        fileSec.identifier = @"files";
        [weakSelf.collectionViewModel initDataSource:^NSArray<XYFileCollectionSection *> *{
            return @[fileSec];
        } completion:^{
            [weakSelf reloadCollectionData];
            if (callBack) {
                callBack();
            }
            [self.collectionView xy_endLoading];
        }];
        
    };
    
    switch (self.fileLoadType) {
        case XYFileLoadTypeCurrentDirectory: {
            [self loadFileWithFilePathArray:self.collectionViewModel.filePathArray completion:reloadCallBack];
            break;
        }
        case XYFileLoadTypeSubDirectory: {
            NSError *error = nil;
            [self.parentDirectoryItem reloadFileWithError:&error];
            [self loadFileWithDirectoryItem:self.parentDirectoryItem completion:reloadCallBack];
            break;
        }
        default:
            break;
    }
    
}

- (void)reloadCollectionData {
    // 获取排好序的文件数组
    [self.collectionViewModel.filePathArray removeAllObjects];
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    for (XYFileAttributeItem *item in sec.items) {
        NSParameterAssert(item.path.length);
        [self.collectionViewModel.filePathArray addObject:item.path];
    }
    [self.collectionView reloadData];
    [self setupNavigationBar];
}

#pragma mark *** check3DTouch ***

- (void)check3DTouch {
    /// 检测是否有3d touch 功能
    if (@available(iOS 9.0, *)) {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
            // 支持3D Touch
            if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
                [self registerForPreviewingWithDelegate:self sourceView:self.view];
            }
        }
    }
}
#pragma mark *** 3D Touch Delegate ***

#ifdef __IPHONE_9_0
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    // 需要将location在self.view上的坐标转换到tableView上，才能从tableView上获取到当前indexPath
    CGPoint targetLocation = [self.view convertPoint:location toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:targetLocation];
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    if ([vc isKindOfClass:[OSPreviewViewController class]]) {
        OSPreviewViewController *pvc = (OSPreviewViewController *)vc;
        pvc.currentPreviewItemIndex = indexPath.row;
    }
    // 预览区域大小(可不设置)
    vc.preferredContentSize = CGSizeMake(0, 320);
    return vc;
}



- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self showViewController:viewControllerToCommit sender:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    
    [self check3DTouch];
}

#endif


#pragma mark *** Show detail controller ***

- (void)showDetailController:(UIViewController *)viewController parentPath:(NSString *)parentPath {
    if (!viewController) {
        return;
    }
    //    if ([viewController isKindOfClass:[XYFileCollectionViewController class]]) {
    //        XYFileCollectionViewController *vc = (XYFileCollectionViewController *)viewController;
    //        [self.navigationController showViewController:vc sender:self];
    //    }
    //    else {
    //
    //        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
    //        [self.navigationController showViewController:viewController sender:self];
    //    }
    [self.navigationController showViewController:viewController sender:self];
}

- (void)showDetailController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath {
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    NSString *newPath = sec.items[indexPath.row].path;
    if (!newPath.length) {
        return;
    }
    [self showDetailController:viewController parentPath:newPath];
}

- (void)backButtonClick {
    UINavigationController *nac = [UIViewController xy_currentNavigationController];
    if (self.presentedViewController || nac.topViewController.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UIViewController *)previewControllerWithFilePath:(NSString *)filePath {
    XYFileAttributeItem *newItem = [self.collectionViewModel getItemByFilePath:filePath];
    return [self previewControllerWithFileItem:newItem];
}

- (UIViewController *)previewControllerWithFileItem:(XYFileAttributeItem *)newItem {
    if (newItem) {
        BOOL isDirectory;
        BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newItem.path isDirectory:&isDirectory];
        UIViewController *vc = nil;
        if (fileExists) {
            if (newItem.isDirectory) {
                /// 如果当前界面是XYFileCollectionViewControllerModeCopy，那么下一个界面也要是同样的模式
                XYFileCollectionViewControllerMode mode = XYFileCollectionViewControllerModeDefault;
                if (self.collectionViewModel.mode == XYFileCollectionViewControllerModeCopy ||
                    self.collectionViewModel.mode == XYFileCollectionViewControllerModeMove) {
                    mode = self.collectionViewModel.mode;
                }
                vc = [[XYFileCollectionViewController alloc] initWithFilePathArray:newItem.pathOfSubFiles parentItem:newItem controllerMode:mode];
                
                if (self.collectionViewModel.mode == XYFileCollectionViewControllerModeCopy ||
                    self.collectionViewModel.mode == XYFileCollectionViewControllerModeMove) {
                    XYFileCollectionViewController *viewController = (XYFileCollectionViewController *)vc;
                    viewController.collectionViewModel.selectedFiles = self.collectionViewModel.selectedFiles.mutableCopy;
                }
                
            }
            else if ([XYFilePreviewViewController canOpenFile:newItem.path]) {
                vc = [[XYFilePreviewViewController alloc] initWithFileItem:newItem];
            }
            else if ([OSPreviewViewController canPreviewItem:[NSURL fileURLWithPath:newItem.path]]) {
                OSPreviewViewController *preview= [[OSPreviewViewController alloc] init];
                preview.dataSource = self;
                preview.delegate = self;
                vc = preview;
            }
            else {
                [self.view xy_showMessage:@"无法识别的文件"];
            }
        }
        return vc;
    }
    return nil;
}

- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath {
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    if (!indexPath || !sec.items.count) {
        return nil;
    }
    XYFileAttributeItem *newItem = sec.items[indexPath.row];
    return [self previewControllerWithFileItem:newItem];
}

#pragma mark *** UISeacrhControllerDelegate ***

- (void)didPresentSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchController.searchBar becomeFirstResponder];
    });
    
    //    UITextField *searchField = [self.searchController.searchBar valueForKey:@"_searchField"];
    //    searchField.textColor = [UIColor whiteColor];
    
}

- (void)willPresentSearchController:(UISearchController *)aSearchController {
    XYFileSearchResultsController *resultsVc = (XYFileSearchResultsController *)self.searchController.searchResultsController;
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    resultsVc.files = sec.items;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UISearchBarDelegate
////////////////////////////////////////////////////////////////////////
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.collectionView reloadData];
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark *** QLPreviewControllerDataSource ***

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    
    return YES;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    return sec.items.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger) index {
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    NSString *newPath = sec.items[index].path;
    
    return [NSURL fileURLWithPath:newPath];
}

#pragma mark *** QLPreviewControllerDelegate ***

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView * _Nullable * __nonnull)view {
    return self.view.frame;
}

#pragma mark *** XYRollViewScrollDelegate ***

- (BOOL)rollView:(UIScrollView *)scrollView shouldNeedExchangeDataSourceFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    return NO;
}

- (void)rollView:(UIScrollView *)scrollView didRollingWithBeginIndexPath:(NSIndexPath *)beginRollIndexPath lastRollIndexPath:(NSIndexPath *)lastRollIndexPath fingerIndexPath:(NSIndexPath *)fingerIndexPath {
    
}

- (void)rollView:(UIScrollView *)scrollView stopRollingWithBeginIndexPath:(NSIndexPath *)beginRollIndexPath lastRollIndexPath:(NSIndexPath *)lastRollIndexPath fingerIndexPath:(NSIndexPath *)fingerIndexPath waitingDuration:(NSTimeInterval)waitingDuration {
    
    
}

- (void)rollView:(UIScrollView *)scrollView didRollingWithBeginIndexPath:(NSIndexPath *)beginRollIndexPath inSameIndexPath:(NSIndexPath *)fingerIndexPath waitingDuration:(NSTimeInterval)waitingDuration {
    
    [self.view xy_showMessage:@(waitingDuration).stringValue];
}

#pragma mark *** Layout ***

- (void)makeCollectionViewConstr {
    
    if (@available(iOS 11.0, *)) {
        NSLayoutConstraint *top = [self.collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
        NSLayoutConstraint *left = [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
        NSLayoutConstraint *right = [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
        NSLayoutConstraint *bottom = [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
        [NSLayoutConstraint activateConstraints:@[top, left, right, bottom]];
    } else {
        NSDictionary *views = NSDictionaryOfVariableBindings(_collectionView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_collectionView]|" options:0 metrics:nil views:views]];
    }
}

#pragma mark *** Setter getter ***

- (void)setHideDisplayFiles:(BOOL)hideDisplayFiles {
    if (_hideDisplayFiles == hideDisplayFiles) {
        return;
    }
    _hideDisplayFiles = hideDisplayFiles;
    [self reloadFiles];
    
}


- (XYFileBottomHUD *)bottomHUD {
    if (!_bottomHUD) {
        NSMutableArray *items = @[].mutableCopy;
        for (NSString *title in [self bottomHUDTitles]) {
            [items addObject:[[XYFileBottomHUDItem alloc] initWithTitle:title image:nil]];
        }
        _bottomHUD = [[XYFileBottomHUD alloc] initWithItems:items toView:self.view];
        _bottomHUD.delegate = self;
        _bottomHUD.backgroundColor = kFileViewerGlobleColor;
    }
    return _bottomHUD;
}

- (NSArray *)bottomHUDTitles {
    return @[
             @"全选",
             @"复制",
             @"移动",
             @"删除",
             @"文件夹"
             ];
}


- (XYFileCollectionViewFlowLayout *)flowLayout {
    
    if (_flowLayout == nil) {
        
        XYFileCollectionViewFlowLayout *layout = [XYFileCollectionViewFlowLayout new];
        _flowLayout = layout;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionsStartOnNewLine = NO;
        layout.headerSize = CGSizeMake(self.view.bounds.size.width, 44.0);
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        collectionView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        _collectionView = collectionView;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        if ([XYFileCollectionViewFlowLayout collectionLayoutStyle] == NO) {
            UIEdgeInsets inset = _collectionView.contentInset;
            inset.left = 20.0;
            inset.right = 20.0;
            inset.bottom = 20.0;
            _collectionView.contentInset = inset;
        }
        else {
            _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 20.0, 0);
        }
        [self updateCollectionViewFlowLayout:_flowLayout];
        self.collectionViewModel.collectionView = collectionView;
        _collectionView.keyboardDismissMode = YES;
        
    }
    return _collectionView;
}

- (XYFileCollectionViewModel *)collectionViewModel {
    if (!_collectionViewModel) {
        _collectionViewModel = [[XYFileCollectionViewModel alloc] init];
        _collectionViewModel.delegate = self;
    }
    return _collectionViewModel;
}


- (UIButton *)bottomTipButton {
    if (!_bottomTipButton) {
        UIButton *bottomTipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _bottomTipButton = bottomTipButton;
        [self.view addSubview:bottomTipButton];
        bottomTipButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[bottomTipButton]|" options:kNilOptions metrics:nil views:@{@"bottomTipButton": bottomTipButton}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomTipButton(==49.0)]|" options:kNilOptions metrics:nil views:@{@"bottomTipButton": bottomTipButton}]];
        _bottomTipButton.backgroundColor = kFileViewerGlobleColor;
        [bottomTipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        bottomTipButton.titleLabel.numberOfLines = 3;
        bottomTipButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        bottomTipButton.titleLabel.minimumScaleFactor = 0.5;
        bottomTipButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_bottomTipButton addTarget:self action:@selector(chooseCompletion) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _bottomTipButton;
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)showBottomTip {
    if ((self.collectionViewModel.mode != XYFileCollectionViewControllerModeCopy &&
         self.collectionViewModel.mode != XYFileCollectionViewControllerModeMove) ||
        !self.parentDirectoryItem) {
        _bottomTipButton.hidden = YES;
        return;
    }
    
    _bottomTipButton.hidden = NO;
    NSString *string = @"复制";
    if (self.collectionViewModel.mode == XYFileCollectionViewControllerModeMove) {
        string = @"移动";
    }
    [_bottomTipButton setTitle:[NSString stringWithFormat:@"【%@到(%@)目录】", string, self.parentDirectoryItem.displayName] forState:UIControlStateNormal];
    /// 检测已选择的文件是否在当前文件中，如果在就提示用户
    NSMutableArray *containFileArray = @[].mutableCopy;
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    if (sec.items) {
        [self.collectionViewModel.selectedFiles enumerateObjectsUsingBlock:^(XYFileAttributeItem * _Nonnull seleFile, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger foundIdx = [sec.items indexOfObjectPassingTest:^BOOL(XYFileAttributeItem * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL res = NO;
                if ([seleFile.path isEqualToString:file.path]) {
                    res = YES;
                    *stop = YES;
                }
                return res;
            }];
            if (foundIdx != NSNotFound) {
                [containFileArray addObject:seleFile.displayName];
            }
        }];
        
        if (containFileArray.count) {
            string = [containFileArray componentsJoinedByString:@","];
            string = [NSString stringWithFormat:@"请确认：已存在的文件会被替换:(%@)", string];
            [_bottomTipButton setTitle:string forState:UIControlStateNormal];
        }
    }
    
    [self.view bringSubviewToFront:_bottomTipButton];
}

/// 将选择的文件拷贝到目标目录中
- (void)chooseCompletion {
    __weak typeof(&*self) weakSelf = self;
    [self copyFiles:self.collectionViewModel.selectedFiles toRootDirectory:self.parentDirectoryItem.path completionHandler:^(void) {
        __strong typeof(&*weakSelf) self = weakSelf;
        [self.collectionViewModel.selectedFiles removeAllObjects];
        [[NSNotificationCenter defaultCenter] postNotificationName:XYFileCollectionViewControllerOptionFileCompletionNotification object:nil userInfo:@{@"XYFileCollectionViewControllerMode": @(self.collectionViewModel.mode)}];
        [self backButtonClick];
    }];
    
}
#pragma mark *** XYFileBottomHUDDelegate ***

- (void)fileBottomHUD:(XYFileBottomHUD *)hud didClickItem:(XYFileBottomHUDItem *)item {
    switch (item.buttonIdx) {
        case 0: { // 全选
            [self selectAllFilesWithHUDItem:item];
            break;
        }
        case 1: { // 复制
            if (!self.collectionViewModel.selectedFiles.count) {
                [self.view xy_showMessage:@"请选择需要复制的文件"];
            }
            else {
                [self copySelectedDirectory];
            }
            
            break;
        }
        case 2: { // 移动
            if (!self.collectionViewModel.selectedFiles.count) {
                [self.view xy_showMessage:@"请选择需要移动的文件"];
            }
            else {
                [self moveSelectedDirectory];
            }
            break;
        }
        case 3: { // 删除
            if (!self.collectionViewModel.selectedFiles.count) {
                [self.view xy_showMessage:@"请选择需要删除的文件"];
            }
            else {
                [self deleteSelectFiles];
            }
            break;
        }
        case 4: { // 新建文件夹
            [self createNewFolderPath];
            break;
        }
        default:
            break;
    }
}

- (void)alertViewTextFieldtextChange:(UITextField *)tf {
    _newFolderName = tf.text;
}

- (void)createNewFolderPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入文件夹名称";
        [textField addTarget:self action:@selector(alertViewTextFieldtextChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([_newFolderName containsString:@"/"]) {
            [self.view xy_showMessage:@"名称中包含不符合的字符"];
            return;
        }
        
        NSString *currentDirectory = self.parentDirectoryItem.path;
        NSString *newPath = [currentDirectory stringByAppendingPathComponent:_newFolderName];
        BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:newPath];
        if (res) {
            [self.view xy_showMessage:@"存在同名的文件"];
            return;
        }
        NSError *moveError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&moveError];
        if (!moveError) {
            if (self.collectionViewModel.selectedFiles.count) {
                // 将选中的文件移动到创建的目录中
                __weak typeof(&*self) weakSelf = self;
                [self copyFiles:self.collectionViewModel.selectedFiles toRootDirectory:newPath completionHandler:^(void) {
                    __strong typeof(&*weakSelf) self = weakSelf;
                    [self.collectionViewModel.selectedFiles removeAllObjects];
                    [[NSNotificationCenter defaultCenter] postNotificationName:XYFileCollectionViewControllerOptionFileCompletionNotification object:nil userInfo:@{@"XYFileCollectionViewControllerMode": @(self.collectionViewModel.mode)}];
                    [self reloadFiles];
                }];
            }
            else {
                XYFileAttributeItem *newItem = [self.collectionViewModel createNewItemWithNewPath:newPath isHideDisplayFile:_hideDisplayFiles];
                if (newItem) {
                    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
                    [sec.items addObject:newItem];
                    if (self.fileLoadType == XYFileLoadTypeCurrentDirectory) {
                        [self.collectionViewModel.filePathArray addObject:newPath];
                    }
                    [self reloadCollectionData];
                }
            }
            
        } else {
            NSLog(@"%@", moveError.localizedDescription);
        }
        _newFolderName = nil;
    }]];
    [[UIViewController xy_topViewController] presentViewController:alert animated:true completion:nil];
}

/// 选择文件最终复制的目标目录
- (void)copySelectedDirectory {
    [self optionSelectedFiles:XYFileCollectionViewControllerModeCopy];
}

- (void)moveSelectedDirectory {
    [self optionSelectedFiles:XYFileCollectionViewControllerModeMove];
}

- (void)optionSelectedFiles:(XYFileCollectionViewControllerMode)mode {
    switch (mode) {
        case XYFileCollectionViewControllerModeMove:
            [[NSNotificationCenter defaultCenter] postNotificationName:XYFileCollectionViewControllerOptionSelectedFileForMoveNotification object:self userInfo:@{@"OSSelectedFilesKey": self.collectionViewModel.selectedFiles?:@[]}];
            break;
        case XYFileCollectionViewControllerModeCopy:
            [[NSNotificationCenter defaultCenter] postNotificationName:XYFileCollectionViewControllerOptionSelectedFileForCopyNotification object:self userInfo:@{@"OSSelectedFilesKey": self.collectionViewModel.selectedFiles?:@[]}];
            break;
        default:
            break;
    }
    
    if (self.class.fileOperationDelegate && [self.class.fileOperationDelegate respondsToSelector:@selector(fileCollectionViewController:selectedFiles:optionMode:)]) {
        [self.class.fileOperationDelegate fileCollectionViewController:self selectedFiles:self.collectionViewModel.selectedFiles optionMode:mode];
    }
    else {
        NSArray *desDirectors = nil;
        if (self.class.fileOperationDelegate && [self.class.fileOperationDelegate respondsToSelector:@selector(desDirectorsForOption:selectedFiles:fileCollectionViewController:)]) {
            desDirectors = [self.class.fileOperationDelegate desDirectorsForOption:mode selectedFiles:self.collectionViewModel.selectedFiles fileCollectionViewController:self];
        }
        if (!desDirectors.count) {
            desDirectors = @[
#if DEBUG
                             [NSString getICloudCacheFolder],
#endif
                             [NSString getDocumentPath]];
        }
        XYFileCollectionViewController *vc = [[XYFileCollectionViewController alloc] initWithFilePathArray:desDirectors controllerMode:mode];
        UINavigationController *nac = [[[self.navigationController class] alloc] initWithRootViewController:vc];
        vc.collectionViewModel.selectedFiles = self.collectionViewModel.selectedFiles.mutableCopy;
        [self showDetailViewController:nac sender:self];
    }
}


- (void)deleteSelectFiles {
    if (!self.collectionViewModel.selectedFiles.count) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定删除吗" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        for (XYFileAttributeItem *item in self.collectionViewModel.selectedFiles ) {
            NSString *currentPath = item.path;
            NSError *error = nil;
            BOOL isSuccess = [[NSFileManager defaultManager] removeItemAtPath:currentPath error:&error];
            if (!isSuccess && error) {
                [[[UIAlertView alloc] initWithTitle:@"Remove error" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
            }
        }
        [self.collectionViewModel.selectedFiles removeAllObjects];
        [self reloadFiles];
        
    }]];
    [[UIViewController xy_topViewController] presentViewController:alert animated:true completion:nil];
}

- (void)selectAllFilesWithHUDItem:(XYFileBottomHUDItem *)item {
    BOOL selectedAll = YES;
    if ([[item titleForState:UIControlStateNormal] isEqualToString:@"全选"]) {
        [item setTitle:@"取消全选" state:UIControlStateNormal];
        [self.collectionViewModel.selectedFiles removeAllObjects];
        XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
        for (XYFileAttributeItem *item in sec.items) {
            [self.collectionViewModel addSelectedFile:item];
        }
        selectedAll = YES;
    }
    else {
        [item setTitle:@"全选" state:UIControlStateNormal];
        [self.collectionViewModel.selectedFiles removeAllObjects];
        selectedAll = NO;
    }
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    [sec.items enumerateObjectsUsingBlock:^(XYFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!selectedAll) {
            obj.status = XYFileAttributeItemStatusEdit;
        }
        else {
            obj.status = XYFileAttributeItemStatusChecked;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        if (obj.status == XYFileAttributeItemStatusChecked) {
            [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
        else {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        
    }];
    [self reloadCollectionData];
}


#pragma mark *** Notification ***
/// 文件操作文件，比如复制、移动文件完成
- (void)optionFileCompletion:(NSNotification *)notification {
    [self.collectionViewModel.selectedFiles removeAllObjects];
    self.collectionViewModel.mode = XYFileCollectionViewControllerModeDefault;
    [self reloadFiles];
}

- (void)rotateToInterfaceOrientation {
    [self updateCollectionViewFlowLayout:self.flowLayout];
    /// 屏幕旋转时重新布局item
    [self.collectionView.collectionViewLayout invalidateLayout];
}


- (void)collectionReLayoutStyle {
    
    [self updateCollectionViewFlowLayout:_flowLayout];
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    [sec.items enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(XYFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.needReLoyoutItem = YES;
    }];
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof XYFileCollectionViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        [cell invalidateConstraints];
        //        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        //            [cell.contentView layoutIfNeeded];
        //        } completion:^(BOOL finished) {
        //
        //        }];
    }];
    [self.flowLayout invalidateLayout];
    //    [self reloadCollectionData];
}

- (void)markupFileCompletion:(NSNotification *)notification {
    [self reloadCollectionData];
}

#pragma mark *** XYFileCollectionViewModelDelegate ***

- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionViewModel.mode == XYFileCollectionViewControllerModeEdit) {
        NSArray *files = collectionViewModel.sectionItems[indexPath.section].items;
        XYFileAttributeItem *item = files[indexPath.row];
        item.status = XYFileAttributeItemStatusChecked;
        [collectionViewModel addSelectedFile:item];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        });
    } else {
        UIViewController *vc = [self previewControllerByIndexPath:indexPath];
        [self showDetailController:vc atIndexPath:indexPath];
        if ([vc isKindOfClass:[OSPreviewViewController class]]) {
            OSPreviewViewController *pvc = (OSPreviewViewController *)vc;
            pvc.currentPreviewItemIndex = indexPath.item;
        }
    }
}

- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionViewModel.mode == XYFileCollectionViewControllerModeEdit) {
        NSArray *files = collectionViewModel.sectionItems[indexPath.section].items;
        XYFileAttributeItem *item = files[indexPath.row];
        item.status = XYFileAttributeItemStatusEdit;
        [collectionViewModel.selectedFiles removeObject:item];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        });
    }
}

- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel needCopyFile:(XYFileAttributeItem *)fileModel {
    [collectionViewModel.selectedFiles removeAllObjects];
    [collectionViewModel addSelectedFile:fileModel];
    [self copySelectedDirectory];
}

- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel needDeleteFile:(XYFileAttributeItem *)fileModel {
    NSError *error = nil;
    BOOL res = [[NSFileManager defaultManager] removeItemAtPath:fileModel.path error:&error];
    if (!res || error) {
        [self.view xy_showMessage:[NSString stringWithFormat:@"删除出错%@", error.localizedDescription]];
        return;
    }
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    [sec.items removeObject:fileModel];
    NSUInteger foundFileIdxFromFilePathArray = [collectionViewModel.filePathArray indexOfObjectPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [fileModel.path isEqualToString:obj];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    if (self.collectionViewModel.filePathArray && foundFileIdxFromFilePathArray != NSNotFound) {
        [self.collectionViewModel.filePathArray removeObjectAtIndex:foundFileIdxFromFilePathArray];
    }
    [self.parentDirectoryItem reloadFile];
    [self reloadCollectionData];
}

- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel clickedSearchButton:(UIButton *)searchButton {
    if (!self.searchController.active) {
        // 弹出搜索控制器
        self.searchController.active = YES;
    }
    else {
        [self.searchController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)collectionViewModel:(XYFileCollectionViewModel *)collectionViewModel sortTypeChanged:(UISegmentedControl *)sortControl currentSortType:(XYFileBrowserSortType)sortType {
    XYFileCollectionSection *sec = [self.collectionViewModel getSectionWithIdentifier:@"files"];
    NSArray *files = [self sortFilesWithArray:sec.items];
    XYFileCollectionSection *fileSec = [[XYFileCollectionSection alloc] initWithItems:files];
    fileSec.identifier = @"files";
    [self.collectionViewModel initDataSource:^NSArray<XYFileCollectionSection *> *{
        return @[fileSec];
    } completion:^{
        [self reloadCollectionData];
    }];
    
}

- (void)reloadCollectionDataForCollectionViewModel:(XYFileCollectionViewModel *)collectionViewModel {
    [self reloadCollectionData];
}

#pragma mark *** File operation ***

/// copy 文件
- (void)copyFiles:(NSArray<XYFileAttributeItem *> *)fileItems
  toRootDirectory:(NSString *)rootPath
completionHandler:(void (^)(void))completion {
    if (!fileItems.count) {
        return;
    }
    
    UIView *view = (UIView *)[UIApplication sharedApplication].delegate.window;
    __weak typeof(&*self) weakSelf = self;
    [view xy_showProgressWithActionCallBack:^(MBProgressHUD *hud) {
        __strong typeof(&*weakSelf) self = weakSelf;
        [self.fileManager cancelAllOperation];
        hud.label.text = @"已取消";
        if (completion) {
            completion();
        }
    }];
    
    [fileItems enumerateObjectsUsingBlock:^(XYFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *desPath = [rootPath stringByAppendingPathComponent:[obj.path lastPathComponent]];
        if ([desPath isEqualToString:obj.path]) {
            NSLog(@"路径相同");
            dispatch_main_safe_async(^{
                view.xy_hud.label.text = @"路径相同";
                if (completion) {
                    completion();
                }
            });
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:desPath]) {
            dispatch_main_safe_async(^{
                view.xy_hud.label.text = @"存在相同文件，正在移除原文件";
            });
            NSError *removeError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:desPath error:&removeError];
            if (removeError) {
                NSLog(@"Error: %@", removeError.localizedDescription);
            }
        }
    }];
    
    NSMutableArray *hudDetailTextArray = @[].mutableCopy;
    
    void (^hudDetailTextCallBack)(NSString *detailText, NSInteger index) = ^(NSString *detailText, NSInteger index){
        @synchronized (hudDetailTextArray) {
            [hudDetailTextArray replaceObjectAtIndex:index withObject:detailText];
        }
    };
    
    
    /// 当completionCopyNum为0 时 全部拷贝完成
    __block NSInteger completionCopyNum = fileItems.count;
    [fileItems enumerateObjectsUsingBlock:^(XYFileAttributeItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [hudDetailTextArray addObject:@(idx).stringValue];
        NSString *desPath = [rootPath stringByAppendingPathComponent:[obj.path lastPathComponent]];
        NSURL *desURL = [NSURL fileURLWithPath:desPath];
        
        void (^ progressBlock)(NSProgress *progress) = ^ (NSProgress *progress) {
            NSString *completionSize = [NSString transformedFileSizeValue:@(progress.completedUnitCount)];
            NSString *totalSize = [NSString transformedFileSizeValue:@(progress.totalUnitCount)];
            NSString *prcent = [NSString percentageString:progress.fractionCompleted];
            NSString *detailText = [NSString stringWithFormat:@"%@  %@/%@", prcent, completionSize, totalSize];
            dispatch_main_safe_async(^{
                hudDetailTextCallBack(detailText, idx);
            });
        };
        
        void (^ completionHandler)(id<OSFileOperation> fileOperation, NSError *error) = ^(id<OSFileOperation> fileOperation, NSError *error) {
            completionCopyNum--;
            NSLog(@"剩余文件个数%ld", completionCopyNum);
        };
        NSURL *orgURL = [NSURL fileURLWithPath:obj.path];
        if (self.collectionViewModel.mode == XYFileCollectionViewControllerModeCopy) {
            [_fileManager copyItemAtURL:orgURL
                                  toURL:desURL
                               progress:progressBlock
                      completionHandler:completionHandler];
        }
        else {
            [_fileManager moveItemAtURL:orgURL
                                  toURL:desURL
                               progress:progressBlock
                      completionHandler:completionHandler];
        }
        
    }];
    
    
    _fileManager.totalProgressBlock = ^(NSProgress *progress) {
        view.xy_hud.label.text = [NSString stringWithFormat:@"total:%@  %lld/%lld", [NSString percentageString:progress.fractionCompleted], progress.completedUnitCount, progress.totalUnitCount];
        view.xy_hud.progress = progress.fractionCompleted;
        @synchronized (hudDetailTextArray) {
            NSString *detailStr = [hudDetailTextArray componentsJoinedByString:@",\n"];
            view.xy_hud.detailsLabel.text = detailStr;
        }
    };
    
    [_fileManager setCurrentOperationsFinishedBlock:^{
        if (completion) {
            completion();
        }
        view.xy_hud.label.text = @"完成";
        [view.xy_hud hideAnimated:YES afterDelay:2.0];
    }];
    
}

#pragma mark *** FileOperationDelegate ***
__weak id _fileOperationDelegate;

+ (id<XYFileCollectionViewControllerFileOptionDelegate>)fileOperationDelegate {
    return _fileOperationDelegate;
}

+ (void)setFileOperationDelegate:(id<XYFileCollectionViewControllerFileOptionDelegate>)fileOperationDelegate {
    _fileOperationDelegate = fileOperationDelegate;
}

#pragma mark *** NoDataPlaceholderDelegate ***

- (BOOL)noDataPlaceholderShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (CGPoint)contentOffsetForNoDataPlaceholder:(UIScrollView *)scrollView {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        return CGPointMake(0, 120.0);
    }
    return CGPointMake(0, 80.0);
}

- (void)noDataPlaceholderWillAppear:(UIScrollView *)scrollView {
    
}

- (void)noDataPlaceholderDidDisappear:(UIScrollView *)scrollView {
    
}

- (BOOL)noDataPlaceholderShouldFadeInOnDisplay:(UIScrollView *)scrollView {
    return YES;
}


- (NSAttributedString *)noDataDetailLabelAttributedString {
    return nil;
}

- (UIImage *)noDataImageViewImage {
    
    return [UIImage XYFileBrowserImageNamed:@"file_noData"];
}


- (NSAttributedString *)noDataReloadButtonAttributedStringWithState:(UIControlState)state {
    return [self attributedStringWithText:@"查看缓存页" color:[UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0] fontSize:15.0];
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button {
    if ([self.parentDirectoryItem isDownloadBrowser]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:XYFileCollectionViewControllerNeedOpenDownloadPageNotification object:nil];
        //        self.navigationController.viewControllers = @[self.navigationController.viewControllers.firstObject];
    }
}


- (NSAttributedString *)noDataTextLabelAttributedString {
    NSString *string = nil;
    if ([self.parentDirectoryItem isDownloadBrowser]) {
        string = @"缓存完成的文件在这显示";
    }
    else if ([self.parentDirectoryItem isICloudDrive]) {
        string = @"将文件移动到此处，即可从iPhone、iPad、Mac访问";
    }
    else {
        string = @"没有文件";
    }
    return [self attributedStringWithText:string color:[UIColor grayColor] fontSize:16];;
}

- (NSAttributedString *)attributedStringWithText:(NSString *)string color:(UIColor *)color fontSize:(CGFloat)fontSize {
    NSString *text = string;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIColor *textColor = color;
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary new];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    style.lineSpacing = 4.0;
    [attributeDict setObject:font forKey:NSFontAttributeName];
    [attributeDict setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributeDict setObject:style forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributeDict];
    
    return attributedString;
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)updateCollectionViewFlowLayout:(XYFileCollectionViewFlowLayout *)flowLayout {
    if ([XYFileCollectionViewFlowLayout collectionLayoutStyle] == XYFileCollectionLayoutStyleSingleItemOnLine) {
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
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                flowLayout.lineItemCount = 6;
            }
            else {
                flowLayout.lineItemCount = 3;
            }
            
        }
        else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                flowLayout.lineItemCount = 10;
            }
            else {
                flowLayout.lineItemCount = 5;
            }
        }
    }
}


@end

