//
//  OSFileBrowserAppearanceConfigs.h
//  FileBrowser
//
//  Created by xiaoyuan on 20/11/2017.
//  Copyright © 2017 xiaoyuan. All rights reserved.
//

#ifndef OSFileBrowserAppearanceConfigs_h
#define OSFileBrowserAppearanceConfigs_h

#define OSSwizzleInstanceMethod(class, originalSEL, swizzleSEL) {\
Method originalMethod = class_getInstanceMethod(class, originalSEL);\
Method swizzleMethod = class_getInstanceMethod(class, swizzleSEL);\
BOOL didAddMethod = class_addMethod(class, originalSEL, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));\
if (didAddMethod) {\
class_replaceMethod(class, swizzleSEL, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));\
}\
else {\
method_exchangeImplementations(originalMethod, swizzleMethod);\
}\
}


#endif /* OSFileBrowserAppearanceConfigs_h */
