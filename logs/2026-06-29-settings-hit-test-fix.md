# 2026-06-29 Settings Hit Test Fix

## 新增文件

- `logs/2026-06-29-settings-hit-test-fix.md`
  - 记录本次设置入口仍无法点击进入设置页的排查与修复。

## 修改文件

- `AIchat_ios/Views/HomeView.swift`
  - 将首页根容器改为 `ZStack(alignment: .topTrailing)`。
  - 将设置入口从 `ScrollView` 内的欢迎区移出，放到首页最外层右上角 overlay。
  - 将设置入口从 `NavigationLink` 改回普通 `Button`，点击后通过 `fullScreenCover` 展示 `SettingsView`。
  - 为设置按钮保留 44pt 点击区域、圆形白色半透明背景、描边和阴影。
  - 欢迎区右侧增加预留空间，避免文字与右上角设置按钮视觉重叠。

## 完成功能

- 修复设置按钮受 `ScrollView`/自定义 `NavigationLink` 结构影响，点击后无法稳定进入设置页的问题。
- 设置按钮现在是首页顶层独立按钮，点击后直接弹出设置页。

## 未完成内容

- 无。

## 验证说明

- 已执行 Xcode 编译验证：
  - `xcodebuild -project AIchat_ios.xcodeproj -scheme AIchat_ios -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /Users/chenanqi/Desktop/AIchat_ios/DerivedData build`
- 编译结果：通过。
- 已确认本地 `simctl` 不提供直接点击坐标命令，因此本次未进行自动点击脚本验证。
