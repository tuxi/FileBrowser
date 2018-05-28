//
//  XYFileBottomHUD.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XYFileBottomHUD, XYFileBottomHUDItem;

@protocol XYFileBottomHUDDelegate <NSObject>

@optional
- (void)fileBottomHUD:(XYFileBottomHUD *)hud didClickItem:(XYFileBottomHUDItem *)item;

@end

@interface XYFileBottomHUDItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign, readonly) NSInteger buttonIdx;
@property (nonatomic, weak, readonly) UIButton *button;
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image;
- (NSString *)titleForState:(UIControlState)state;
- (NSString *)imageForState:(UIControlState)state;
- (void)setImage:(UIImage *)image state:(UIControlState)state;
- (void)setTitle:(NSString *)title state:(UIControlState)state;

@end

@interface XYFileBottomHUD : UIView

@property (nonatomic, weak) id<XYFileBottomHUDDelegate> delegate;

- (instancetype)initWithItems:(NSArray<XYFileBottomHUDItem *> *)items toView:(UIView *)view;
- (void)hideHudCompletion:(void (^)(XYFileBottomHUD *hud))completion;
- (void)showHUDWithFrame:(CGRect)frame completion:(void (^)(XYFileBottomHUD *hud))completion;
- (void)setItemTitle:(NSString *)title index:(NSInteger)index state:(UIControlState)state;
- (void)setItemImage:(UIImage *)image index:(NSInteger)index state:(UIControlState)state;

@end

