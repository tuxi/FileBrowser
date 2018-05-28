//
//  XYFileCollectionViewController.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYFileBrowserAppearanceConfigs.h"

@class XYFileAttributeItem, XYFileCollectionViewController, XYFileCollectionViewModel;

/// 操作文件的协议
@protocol XYFileCollectionViewControllerFileOptionDelegate <NSObject>

@optional
/// 即将操作文件时调用, 代理实现此方法，可以自定义跳转， 如果执行此方法则不执行desDirectorsForOption:selectedFiles:fileCollectionViewController:
/// @param fileCollectionViewController 当前控制器
/// @param selectedFiles 用户已选中的文件，需要移动的文件
/// @param mode 操作方式，mode 操作的模式，可能是移动或复制
- (void)fileCollectionViewController:(XYFileCollectionViewController *)fileCollectionViewController selectedFiles:(NSArray<XYFileAttributeItem *> *)selectedFiles optionMode:(XYFileCollectionViewControllerMode)mode;

/// 获取目录列表, 选中的文件操作时调用,
/// @param mode 操作的模式，可能是移动或复制
/// @param selectedFiles 已选中的文件
/// @param fileCollectionViewController 当前控制器，非即将跳转的控制器
/// @return 返回目标文件目录列表
- (NSArray<NSString *> *)desDirectorsForOption:(XYFileCollectionViewControllerMode)mode selectedFiles:(NSArray<XYFileAttributeItem *> *)selectedFiles fileCollectionViewController:(XYFileCollectionViewController *)fileCollectionViewController;

@end

@interface XYFileCollectionViewController : UIViewController

@property (nonatomic, strong) XYFileCollectionViewModel *collectionViewModel;
@property (nonatomic, assign) BOOL hideDisplayFiles;
/// 用于操作文件的全局代理，对整个类有效
@property (nonatomic, class) id<XYFileCollectionViewControllerFileOptionDelegate> fileOperationDelegate;
/// 是否是根目录，根目录下文件不可以编辑
@property (nonatomic, assign, getter=isRootDirectory) BOOL rootDirectory;

/// 通过文件目录路径，读取里面所有的文件并展示
- (instancetype)initWithDirectory:(NSString *)path;
/// 通过文件目录路径，读取里面所有的文件并展示, 传入当前控制器的模式
- (instancetype)initWithDirectory:(NSString *)path controllerMode:(XYFileCollectionViewControllerMode)mode;
/// 展示指定的文件目录
- (instancetype)initWithFilePathArray:(NSArray *)directoryArray;
- (instancetype)initWithFilePathArray:(NSArray *)directoryArray controllerMode:(XYFileCollectionViewControllerMode)mode;;

/// 拷贝文件到指定目录
- (void)copyFiles:(NSArray<XYFileAttributeItem *> *)fileItems
  toRootDirectory:(NSString *)rootPath
completionHandler:(void (^)(void))completion;

/// 重新加载本地文件，并刷新
- (void)reloadFilesWithCallBack:(void (^)(void))callBack;
- (void)reloadFiles;
/// 刷新已读取的文件
- (void)reloadCollectionData;

/// 通过当前控制器查看indexPath对应的子文件
/// @param viewController 展示文件的控制器对象
/// @param indexPath 当前目录下的子文件
- (void)showDetailController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath;
/// 根据indexPath获取当前文件目录中的子文件，并创建对象的控制器返回
- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath;
- (UIViewController *)previewControllerWithFilePath:(NSString *)filePath;
- (void)showDetailController:(UIViewController *)viewController parentPath:(NSString *)parentPath;
@end

