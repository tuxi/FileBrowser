source 'https://github.com/CocoaPods/Specs.git'
platform :ios, :deployment_target => '8.0'

xcodeproj 'FileBrowser.xcodeproj'

inhibit_all_warnings!
# fileBrowserPods 如果是 FileBrowserPods(大写字母开头pod install编译不过)
def fileBrowserPods
    pod 'MBProgressHUD', '~> 1.0.0'
    pod 'NODataPlaceholderView', '~> 1.0.5’
    pod 'OSFileManager', '~>0.0.4'
end

target 'FileBrowser' do
  
	fileBrowserPods
end

target 'FileBrowserLib' do
    fileBrowserPods
end
