# 2026-06-29 Figma Make 源码样式还原

## 本次新增文件
- `logs/2026-06-29-figma-make-source-parity.md`
  - 记录本次按 Figma Make 源码还原 SwiftUI 样式、验证结果与注意事项。

## 本次修改文件
- `AIchat_ios/Models/RolePresentation.swift`
  - 新增 Figma Make 角色视觉映射，固定 `奶糖 / 晚晴 / 曜川 / 小芙` 的顺序、文案、头像和聊天背景图。
- `AIchat_ios/ViewModels/RoleListViewModel.swift`
  - 角色列表加载后按 Figma 顺序合并展示；接口异常时保留 Figma 四角色视觉 fallback。
- `AIchat_ios/Views/Components/AppTheme.swift`
  - 补齐 Figma/Tailwind 源码中的紫粉渐变、灰阶、浅色背景和卡片渐变 token。
- `AIchat_ios/Views/OnboardingView.swift`
  - 按 `Onboarding.tsx` 重做引导页：固定 480pt 卡片、160pt 圆形头像、背景图 30% 透明、分页点和底部渐变按钮。
- `AIchat_ios/Views/HomeView.swift`
  - 按 `Home.tsx` 收敛首页：背景图白色渐变遮罩、推荐角色卡、横向角色卡、快捷入口和最近聊天行。
- `AIchat_ios/Views/ChatView.swift`
  - 按 `Chat.tsx` 收敛聊天页：全屏角色背景图、半透明顶部栏、快捷话题、输入栏和发送按钮。
- `AIchat_ios/Views/Components/MessageBubbleView.swift`
  - 按源码调整消息气泡：用户气泡无头像、最大宽度约 75%、16pt 圆角和 4pt 尾角。
- `AIchat_ios/Views/LoginSheetView.swift`
  - 按 `LoginModal.tsx` 重做登录弹窗样式，移除测试账号提示，保留真实验证码 API 登录。
- `AIchat_ios/Views/Components/RoleCardView.swift`
  - 统一角色展示字段，避免后续复用时回退到 API 原始展示文案。

## 本次完成功能
- 以 Figma MCP 读取到的 Make 源码作为视觉依据，不使用截图反推样式。
- 四个核心页面的结构、间距、圆角、渐变、阴影、图片资源和主要状态已按源码还原到 SwiftUI。
- 保留 Nuke 网络图片加载、Alamofire 普通请求和流式响应实现，没有新增第三方依赖。
- 角色 UI 展示优先使用 Figma 源码固定配置，后端请求继续使用真实角色 `id/key`。

## 验证结果
- 已通过 iPhone 17 模拟器编译：
  - `xcodebuild -project AIchat_ios.xcodeproj -scheme AIchat_ios -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /Users/chenanqi/Desktop/AIchat_ios/DerivedData build`
- 已在 iPhone 17 模拟器安装并启动 App。
- 已截图检查首页和清空数据后的引导页，图片资源、主布局和渐变背景均正常显示。

## 当前仍未完成的内容
- 本轮未使用真实手机号完成验证码登录、流式聊天发送的完整端到端人工验证。
- 如果后端角色接口返回新增角色，新增角色会追加在 Figma 四角色之后，并使用 API 原始展示字段。

## 注意事项
- Figma Make 源码里的测试账号逻辑没有移植到 iOS App，登录必须走真实后端 API。
- 本次截图仅用于实现后 QA，不作为设计生成来源。
