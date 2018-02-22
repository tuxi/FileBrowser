# FileBrowser


[![Version](https://img.shields.io/cocoapods/v/OSFileBrowser.svg?style=flat)](http://cocoapods.org/pods/OSFileBrowser)
[![Platform](https://img.shields.io/cocoapods/p/OSFileBrowser.svg?style=flat)](http://cocoapods.org/pods/OSFileBrowser)
[![License](https://img.shields.io/cocoapods/l/OSFileBrowser.svg?style=flat)](http://cocoapods.org/pods/OSFileBrowser)

<img src = "https://github.com/alpface/FileBrowser/blob/master/2018-02-23%2000_40_58.gif?raw=true" width = "375" height = "667" alt = "Screenshot1.png"/>

用于iOS设备查看沙盒文件的工具

## Installation
### CocoaPods:

Add the next string in your project's Podfile:

```sh
pod 'OSFileBrowser', '0.1.6'
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
