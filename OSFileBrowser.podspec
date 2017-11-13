#
#  Be sure to run `pod spec lint OSFileBrowser.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "OSFileBrowser"
  s.version      = "0.1.6"
  s.summary      = "一个很实用的文件浏览器."
  s.description  = "使用此示例你可以很方便的：查看文件、管理文件、操作文件."

  s.homepage     = "https://github.com/Ossey/FileBrowser"
  s.license      = "MIT"

  s.author             = { "Ossey" => "xiaoyuan1314@me.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Ossey/FileBrowser.git", :tag => "#{s.version}" }

  s.source_files  = "FileBrowser", "OSFileBrowser/*.{h,m}"
  s.resource     = 'OSFileBrowser/OSFileBrowser.bundle'
  s.requires_arc = true
  s.frameworks = 'UIKit'
  s.dependency 'MBProgressHUD', '~> 1.0.0'
  s.dependency 'NODataPlaceholderView', '~> 1.0.2'
  s.dependency 'OSFileManager', '~> 0.0.2'
end
