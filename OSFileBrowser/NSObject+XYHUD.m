//
//  NSObject+XYHUD.m
//  MiaoLive
//
//  Created by mofeini on 16/11/16.
//  Copyright © 2016年 MiaoLive. All rights reserved.
//

#import "NSObject+XYHUD.h"
#import <objc/runtime.h>
#import "UIViewController+XYExtensions.h"

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static const void *hudKey = &hudKey;

@implementation NSObject (XYHUD)

- (void)setXy_hud:(MBProgressHUD *)xy_hud {
    
    objc_setAssociatedObject(self, hudKey, xy_hud, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setXy_hudCancelOption:(HUDActionCallBack)cancelOption {
    objc_setAssociatedObject(self, @selector(xy_hudCancelOption), cancelOption, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HUDActionCallBack)xy_hudCancelOption {
    return objc_getAssociatedObject(self, _cmd);
}

- (MBProgressHUD *)xy_hud {
    
    return objc_getAssociatedObject(self, hudKey);
}

- (void)xy_showMessage:(NSString *)meeeage {
    
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    [self xy_showHudToView:window message:meeeage];
    self.xy_hud.mode = MBProgressHUDModeText;
    [self.xy_hud hideAnimated:YES afterDelay:2.0];
    self.xy_hud = nil;
}

- (void)xy_showHudToView:(UIView *)view message:(NSString *)message {
    
    [self xy_showHudToView:view message:message offsetY:0];
    
}

- (void)xy_showHudToView:(UIView *)view message:(NSString *)message offsetY:(CGFloat)offsetY {
    if (!self.xy_hud) {
        self.xy_hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    };
    [self.xy_hud.label setText:message];
    [self xy_commonInit];
    self.xy_hud.label.numberOfLines = 0;
    self.xy_hud.margin = 10.0f;
    [self.xy_hud setOffset:CGPointMake(self.xy_hud.offset.x, offsetY)];
}

- (void)xy_showActivityWithActionCallBack:(HUDActionCallBack)callBack {
    [self xy_showHudWithMessage:nil actionCallBack:callBack];
}

- (void)xy_showHudWithMessage:(NSString *)message
               actionCallBack:(HUDActionCallBack)callBack {
    if (!self.xy_hud) {
        self.xy_hud = [MBProgressHUD showHUDAddedTo:[UIViewController xy_topViewController].view animated:YES];
    }
    
    self.xy_hud.mode = MBProgressHUDModeIndeterminate;
    self.xy_hud.label.text = message;
    [self xy_commonInit];
    self.xy_hudCancelOption = callBack;
    [self.xy_hud.button setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.xy_hud.button removeTarget:self action:@selector(xy_cancelOperation:) forControlEvents:UIControlEventTouchUpInside];
    [self.xy_hud.button addTarget:self action:@selector(xy_cancelOperation:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)xy_commonInit {
    self.xy_hud.backgroundView.color = [UIColor colorWithWhite:0.0 alpha:0.6];
}

- (void)xy_cancelOperation:(id)sender {
    if (self.xy_hudCancelOption) {
        self.xy_hudCancelOption(sender);
    }
    [self.xy_hud hideAnimated:YES afterDelay:0.5];
    self.xy_hud = nil;
}

- (void)xy_hideHUDWithMessage:(NSString *)message
                    hideAfter:(NSTimeInterval)afterSecond {
    self.xy_hud.label.text = message;
    [self.xy_hud hideAnimated:YES afterDelay:afterSecond];
    self.xy_hud = nil;
}

- (void)xy_hideHud {
    [self.xy_hud hideAnimated:YES];
    self.xy_hud = nil;
}

+ (void)xy_hideHUD {
    [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    [MBProgressHUD HUDForView:[UIViewController xy_topViewController].view];
}

@end
