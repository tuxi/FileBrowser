# OSFileBrowser


[![Version](https://img.shields.io/cocoapods/v/OSFileBrowser.svg?style=flat)](http://cocoapods.org/pods/OSFileBrowser)
[![Platform](https://img.shields.io/cocoapods/p/OSFileBrowser.svg?style=flat)](http://cocoapods.org/pods/OSFileBrowser)
[![License](https://img.shields.io/cocoapods/l/OSFileBrowser.svg?style=flat)](http://cocoapods.org/pods/OSFileBrowser)

一个iOS设备浏览本地文件的工具

## Installation
### CocoaPods:

Add the next string in your project's Podfile:

```sh
pod 'OSFileBrowser', '0.1.3'
```

then run in Terminal:

```ruby
pod install
```

## Usage

Objective C:
```objective-c
#import <OSFileBrowser.h>

OSFileCollectionViewController *vc = [[OSFileCollectionViewController alloc]
initWithDirectoryArray:@[                                                                                                            [NSString getRootPath],[NSString getDocumentPath]]

controllerMode:OSFileCollectionViewControllerModeDefault];

UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
[self.navigationController pushViewController:vc animated:YES];
```

## License

MIT
