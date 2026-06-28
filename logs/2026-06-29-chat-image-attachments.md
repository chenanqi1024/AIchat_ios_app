# 2026-06-29 Chat Image Attachments

## 新增文件

- `logs/2026-06-29-chat-image-attachments.md`
  - 记录本次聊天页边距、清空按钮图标、图片消息发送能力的实现内容与验证结果。

## 修改文件

- `AIchat_ios/Models/APIModels.swift`
  - 为 `ChatMessage` 增加本地图片数据字段，用于当前会话内展示用户刚发送的图片。

- `AIchat_ios/Services/APIClient.swift`
  - 扩展流式聊天请求参数，支持向后端 `/chat` 接口传入 Base64 Data URL 图片。

- `AIchat_ios/ViewModels/ChatViewModel.swift`
  - 支持纯文本、纯图片、文本加图片三种发送方式。
  - 发送图片时继续使用真实后端流式聊天接口。
  - 保留本地图片数据，避免流式响应更新时丢失用户图片预览。

- `AIchat_ios/Views/ChatView.swift`
  - 聊天页左右边距统一调整为更舒适的 24pt。
  - 右上角清空聊天记录按钮补充垃圾桶图标，并保留确认弹窗。
  - 输入栏增加图片选择入口、图片预览、删除已选图片与处理状态。
  - 图片上传前进行压缩：长边限制为 1440，短边等比缩放，并转为 JPEG Base64 Data URL。
  - 图片体积按后端默认限制控制在 6MB 以内，超限时展示错误提示。

- `AIchat_ios/Views/Components/MessageBubbleView.swift`
  - 支持在用户聊天气泡中展示本地发送的图片缩略图。

## 完成功能

- 清空聊天记录按钮已显示明确的垃圾桶 icon。
- 聊天页顶部、消息区、快捷话题和输入栏的左右边距已统一优化。
- 聊天输入框支持添加图片。
- 选择图片后会自动压缩到长边 1440 以内，短边等比缩放。
- 图片以 `data:image/jpeg;base64,...` 形式传给后端真实聊天接口。
- 支持仅发送图片，或同时发送文字和图片。

## 未完成内容

- 无。

## 验证说明

- 已执行 Xcode 编译验证：
  - `xcodebuild -project AIchat_ios.xcodeproj -scheme AIchat_ios -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /Users/chenanqi/Desktop/AIchat_ios/DerivedData build`
- 编译结果：通过。
- 按用户要求，本次未启动模拟器运行 App。
