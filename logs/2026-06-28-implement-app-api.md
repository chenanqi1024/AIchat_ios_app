# 本次改动日志

日期：2026-06-28

## 本次新增文件

- `AIchat_ios/Models/RolePresentation.swift`
  - 为后端返回的 `ChatRole` 补充前端展示用的角色标签、问候语和空会话欢迎语。

- `logs/2026-06-28-implement-app-api.md`
  - 记录本次实现内容、涉及文件、验证结果和后续注意事项。

## 本次修改文件

- `AIchat_ios/ContentView.swift`
  - 移除强制深色模式，统一使用 Figma 设计稿的浅色紫粉视觉风格。

- `AIchat_ios/Views/AppRootView.swift`
  - 调整 onboarding 完成回调，支持把用户选中的角色带入首页并继续进入聊天流程。

- `AIchat_ios/Views/OnboardingView.swift`
  - 使用真实 `/roles` 接口加载角色。
  - 按 Figma Make 设计实现浅色渐变背景、角色轮播卡片、分页指示器和主按钮。
  - 未登录时弹出真实手机号验证码登录流程，登录成功后继续进入所选角色。

- `AIchat_ios/Views/HomeView.swift`
  - 使用真实角色数据实现问候区、推荐角色卡片、横向角色列表和快捷操作。
  - 支持保存当前选中角色，未登录进入聊天时弹出登录。

- `AIchat_ios/Views/ChatView.swift`
  - 接入角色背景图、角色头像导航标题、欢迎气泡、快捷话题、浅色输入栏和流式发送按钮。
  - 登录成功后自动重新加载聊天历史。
  - 保留清空聊天二次确认。

- `AIchat_ios/Views/LoginSheetView.swift`
  - 改为 Figma 风格浅色登录弹层。
  - 接入真实发送验证码和验证码登录接口。
  - 增加手机号、验证码输入的基础过滤。

- `AIchat_ios/Views/Components/AppTheme.swift`
  - 重建 App 主题色、浅色背景渐变、主按钮渐变、卡片样式和图片背景组件。

- `AIchat_ios/Views/Components/RemoteImageView.swift`
  - 调整 Nuke 图片加载占位和加载状态为浅色主题。

- `AIchat_ios/Views/Components/MessageBubbleView.swift`
  - 改为 Figma 风格的用户渐变气泡、AI 白色气泡，并使用角色头像。

- `AIchat_ios/Views/Components/RoleCardView.swift`
  - 同步角色卡片的浅色图片叠层和主按钮视觉。

- `AIchat_ios/ViewModels/ChatViewModel.swift`
  - 停止流式生成时补充“已停止回复”提示，避免残留空白思考气泡。

- `AIchat_ios/Services/APIClient.swift`
  - 保留 Alamofire 真实网络请求和 SSE 流式响应。
  - 增强非 2xx 响应的错误 envelope 解析，优先展示后端返回的中文错误信息。

## 本次完成功能

- 完成 onboarding、首页、登录弹层、聊天页的可运行 SwiftUI 实现。
- 接入后端 API：发送验证码、验证码登录、获取角色、读取历史、清空历史、SSE 流式聊天。
- 使用 Nuke 加载角色头像和背景图。
- 使用 Keychain 保存 JWT，登录过期或鉴权失败时回到登录流程。
- 根据 Figma Make 源码还原浅色紫粉蓝渐变、角色图片卡片、聊天气泡和输入区风格。

## 当前仍未完成内容

- 后端文档说明没有刷新 Token、注销账号服务端接口，本次仅实现本地退出登录。
- 后端当前没有“最近聊天列表”接口，首页未伪造最近聊天数据。
- 聊天图片输入接口字段已在文档中出现，但本次 App 只实现文字聊天。

## 验证结果

- 已执行 iPhone 17 模拟器编译：
  - `xcodebuild -project AIchat_ios.xcodeproj -scheme AIchat_ios -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /Users/chenanqi/Desktop/AIchat_ios/DerivedData build -quiet`
  - 结果：编译通过。

- 已安装并启动到 iPhone 17 模拟器：
  - Bundle ID：`aicode.qqq.AIchat-ios`
  - 启动结果：成功启动。

- 已截图检查首屏：
  - onboarding 正常显示。
  - `/roles` 角色数据与远程图片正常加载。
