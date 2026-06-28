# 本次改动日志

日期：2026-06-28

## 本次新增文件

- `logs/2026-06-28-figma-style-correction.md`
  - 记录本次针对 Figma Make 样式偏差的修正内容和验证结果。

## 本次修改文件

- `AIchat_ios/Views/HomeView.swift`
  - 重新贴近 Figma Make 首页结构：问候区、推荐角色卡、横向所有角色、三宫格快捷入口、最近聊天区域。
  - 隐藏系统导航栏，改成 Make 设计里的沉浸式首页。
  - 最近聊天区域改为通过真实 `/history` 接口生成预览，不再缺失该 UI 模块。

- `AIchat_ios/Views/ChatView.swift`
  - 聊天页改为 Figma Make 的自定义顶部栏结构：返回按钮、角色头像、角色信息、更多按钮。
  - 聊天背景改为直接使用角色 `backgroundUrl` 全屏铺底，保留对应花纹/图片质感。
  - 输入栏和快捷话题改为白色半透明区域，消息区不再被白色遮罩覆盖。

- `AIchat_ios/Views/LoginSheetView.swift`
  - 登录从系统 sheet 改为 Figma Make 的居中弹窗：黑色遮罩、白色圆角卡片、顶部浅紫粉渐变 header。
  - 保留真实短信验证码发送与登录接口。

- `AIchat_ios/Views/OnboardingView.swift`
  - 登录入口从底部 sheet 切换为全屏透明弹窗承载，保持与 Make modal 一致。

- `AIchat_ios/Views/Components/AppTheme.swift`
  - 首页背景图片显示强度调整为更接近 Figma Make。
  - 新增 `ChatPatternBackgroundView`，专门用于聊天页直接展示角色背景图。

- `AIchat_ios/ViewModels/RoleListViewModel.swift`
  - 新增 `RecentChatPreview` 和最近聊天加载逻辑。
  - 通过真实历史记录接口读取每个角色最近一条消息并格式化时间。

## 本次完成功能

- 修正首页进入后的 UI 结构，使其更贴近 Figma Make 生成稿。
- 修正登录弹窗展示方式，使其不再像系统底部 sheet。
- 修正聊天页背景图层级，确保角色背景花纹/图片在聊天消息区可见。
- 补回 Figma Make 中的最近聊天区域，并使用真实后端历史数据驱动。

## 当前仍未完成内容

- Figma Make 原型里的前端动效使用 `motion/react`，SwiftUI 版只保留基础过渡与系统交互，未逐帧复刻 Web 动效。
- 后端没有独立最近会话列表接口，本次通过遍历角色历史记录生成最近聊天预览。

## 验证结果

- 已执行 iPhone 17 模拟器编译：
  - `xcodebuild -project AIchat_ios.xcodeproj -scheme AIchat_ios -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /Users/chenanqi/Desktop/AIchat_ios/DerivedData build -quiet`
  - 结果：编译通过。

- 已安装并启动到 iPhone 17 模拟器：
  - Bundle ID：`aicode.qqq.AIchat-ios`
  - 启动结果：成功启动。

- 已截图检查首页：
  - 首页已显示 Figma Make 对应的推荐角色、所有角色、快捷入口、最近聊天。
  - 背景图片花纹/纹理已可见。
