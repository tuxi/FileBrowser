//
//  XYFilePreviewViewController.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <WebKit/WebKit.h>

@class XYFileAttributeItem;

@interface OSPreviewViewController : QLPreviewController

@end

@interface XYFilePreviewViewController : UIViewController {
    UITextView *_textView;
    WKWebView *_webView;
    XYFileAttributeItem *_fileItem;
}

@property (nonatomic, copy, readonly) XYFileAttributeItem *fileItem;

- (instancetype)initWithFileItem:(XYFileAttributeItem *)fileItem;
+ (BOOL)canOpenFile:(NSString *)filePath;

@end

