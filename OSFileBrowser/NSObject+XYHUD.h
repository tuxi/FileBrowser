//
//  NSObject+XYHUD.h
//  MiaoLive
//
//  Created by mofeini on 16/11/16.
//  Copyright © 2016年 MiaoLive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

typedef void(^HUDActionCallBack)(MBProgressHUD *hud);

@interface NSObject (XYHUD)

@property (nonatomic, readonly) MBProgressHUD *xy_hud;

- (void)xy_showMessage:(NSString *)meeeage;
- (void)xy_showHudToView:(UIView *)view message:(NSString *)message;
- (void)xy_showHudToView:(UIView *)view message:(NSString *)message offsetY:(CGFloat)offsetY;
- (void)xy_showHudWithMessage:(NSString *)message
               actionCallBack:(HUDActionCallBack)callBack;
- (void)xy_showActivityWithActionCallBack:(HUDActionCallBack)callBack;
- (void)xy_hideHud;
+ (void)xy_hideHUD;
- (void)xy_hideHUDWithMessage:(NSString *)message
                    hideAfter:(NSTimeInterval)afterSecond;
@end
