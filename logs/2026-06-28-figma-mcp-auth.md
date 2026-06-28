# Figma MCP Auth Fix

## 新增文件

- `scripts/figma_mcp_auth.sh`
  - 用于检测本地 Figma MCP 授权相关配置。
  - 支持备份并修复 `~/.codex/config.toml` 中的 `figma` MCP 配置。
  - 支持通过 `codex mcp login figma` 弹出 Figma OAuth 授权页。

## 修改文件

- 无 Swift 业务代码修改。
- 脚本运行时已备份并更新全局 Codex 配置：
  - 备份文件：`/Users/chenanqi/.codex/config.toml.backup.20260628233526`
  - 当前配置已添加：`oauth_resource = "https://mcp.figma.com/mcp"`

## 完成功能

- 检测到普通 `figma` MCP 缺少 `oauth_resource`，且环境中没有 `FIGMA_OAUTH_TOKEN`。
- 通过脚本执行 `--repair-and-login` 后，Figma OAuth 授权流程已成功完成。
- `@figma` 插件通道已通过 `whoami` 验证，可识别当前账号 `Anqi Chen`。

## 当前仍未完成的内容

- 当前正在运行的 Codex 会话仍可能沿用授权前初始化的 MCP client，因此直接读取普通 `figma` server resource 仍可能显示 `Auth required`。
- 需要重启 Codex 或重新打开线程后，普通 `figma` server 才会加载新的 OAuth 授权状态。

## 注意事项

- 本次只新增授权诊断脚本，没有改动 App SwiftUI 页面或 API 接入代码。
- 本次未重新执行 iOS 编译，因为 Swift 工程代码没有变化。
