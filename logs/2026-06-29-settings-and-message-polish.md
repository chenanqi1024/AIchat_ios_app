# 2026-06-29 Settings And Message Polish

## 新增文件

- `AIchat_ios/Views/SettingsView.swift`
  - 新增设置页面，包含自定义顶部栏、账号状态卡片、设置项分组、登录入口和退出登录操作。

- `logs/2026-06-29-settings-and-message-polish.md`
  - 记录本次首页设置入口、设置页和聊天消息样式优化的实现内容与验证结果。

## 修改文件

- `AIchat_ios/Views/HomeView.swift`
  - 在首页右上角新增美观的圆形设置按钮。
  - 通过 `NavigationStack` 推入设置页面，保持现有首页视觉风格与边距。

- `AIchat_ios/Views/Components/MessageBubbleView.swift`
  - 优化聊天气泡宽度：短文本按内容收缩，长文本达到上限后自动换行。
  - 优化带图片消息的展示形式：图片使用独立缩略卡片，文字保留独立聊天气泡，避免图片和文字挤在同一个渐变气泡里。

## 完成功能

- 首页右上角已增加设置 icon。
- 设置页已支持查看登录状态、展示手机号、登录账号和退出登录。
- 退出登录复用现有 `AuthStore.clear()`，会清除本地 token 和用户信息。
- 图片加文字的消息展示已改为图片卡片加文字气泡的组合样式。
- 聊天气泡已支持根据文本长度自适应宽度。

## 未完成内容

- 设置项中的“消息通知”“隐私与安全”“关于陪伴世界”目前为静态展示项，后续可按实际产品需求继续接入具体页面。

## 验证说明

- 已执行 Xcode 编译验证：
  - `xcodebuild -project AIchat_ios.xcodeproj -scheme AIchat_ios -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /Users/chenanqi/Desktop/AIchat_ios/DerivedData build`
- 编译结果：通过。
- 按用户要求，本次未启动模拟器运行 App。
