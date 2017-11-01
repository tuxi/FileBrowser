//
//  OSFileBottomHUD.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSFileBottomHUD, OSFileBottomHUDItem;

@protocol OSFileBottomHUDDelegate <NSObject>

@optional
- (void)fileBottomHUD:(OSFileBottomHUD *)hud didClickItem:(OSFileBottomHUDItem *)item;

@end

@interface OSFileBottomHUDItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign, readonly) NSInteger buttonIdx;
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image;

@end

@interface OSFileBottomHUD : UIView

@property (nonatomic, weak) id<OSFileBottomHUDDelegate> delegate;

- (instancetype)initWithItems:(NSArray<OSFileBottomHUDItem *> *)items toView:(UIView *)view;
- (void)hideHudCompletion:(void (^)(void))completion;
- (void)showHUDWithFrame:(CGRect)frame completion:(void (^)(void))completion;

@end

