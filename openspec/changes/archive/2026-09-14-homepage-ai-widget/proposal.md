## Why

当前首页 \rontend/src/app/page.tsx\ 尚未实现 AI 助手悬浮入口。\homepage-ai-widget\ spec 已定义了完整的悬浮 AI 助手需求——右下角 fixed 按钮、迷你对话窗、消息收发、\POST /api/ai/chat\ API 集成、打字指示器、错误处理与键盘无障碍——但代码层面尚未落地。本变更将 spec 落地为可运行的 AI 助手悬浮组件，让有特定目标的用户无需离开首页即可快速与 AI 助手交互。

## What Changes

- 新增 AI 助手悬浮组件（\rontend/src/components/ai-widget/ai-widget.tsx\），含悬浮按钮 + 迷你对话窗
- 新增聊天消息组件（\rontend/src/components/ai-widget/chat-message.tsx\）与打字指示器组件
- 新增后端 API 端点 \POST /api/ai/chat\，MVP 阶段返回规则式 mock 响应
- 在 \layout.tsx\ 中全局挂载 AI Widget（fixed 定位，不占用 section slot）
- 实现消息收发、乐观渲染、打字指示器、错误处理与 Retry
- 实现键盘无障碍（Escape 关闭、Enter 发送、焦点管理）
- 响应式尺寸：移动端全宽减边距，桌面端固定 360px x 480px

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- \homepage-ai-widget\：从空实现变为完整 AI 助手悬浮组件——覆盖悬浮按钮、对话窗、消息收发、API 集成、打字指示器、错误处理、响应式、无障碍的全部 spec 要求

## Impact

**前端代码**：
- \rontend/src/app/layout.tsx\：全局挂载 AI Widget 组件（fixed 定位，不影响页面布局流）
- \rontend/src/components/ai-widget/ai-widget.tsx\：新增（Client Component，悬浮按钮 + 对话窗 + 状态管理）
- \rontend/src/components/ai-widget/chat-message.tsx\：新增（消息气泡组件）
- \rontend/src/components/ai-widget/typing-indicator.tsx\：新增（打字指示器组件）
- \rontend/src/api/ai.ts\：新增（\chat\ API 调用封装）

**后端代码**：
- \ackend/src/main/java/com/example/myfirst/controller/AiChatController.java\：新增（\POST /api/ai/chat\）
- \ackend/src/main/java/com/example/myfirst/dto/request/ChatRequest.java\：新增（请求 DTO）
- \ackend/src/main/java/com/example/myfirst/dto/response/ChatResponse.java\：新增（响应 DTO）
- MVP 阶段：Controller 内实现规则式 mock 响应（关键词匹配），覆盖无效输入/网络失败模拟

**依赖**：无新增依赖。\lucide-react\、shadcn/ui \Input\/\Button\ 已在 \introduce-frontend-styling-infra\ 变更中安装。

**前置依赖**：
- \introduce-frontend-styling-infra\ 变更（Tailwind CSS + shadcn/ui + lucide-react 已安装并验证构建管线）

**独立性**：
- 本变更对 \homepage-shell\ 零依赖（AI Widget 为 fixed 定位悬浮层，挂载于 layout 级别，不占用 section slot 序列）
- 可与 \homepage-hero\、\homepage-navigation\、\homepage-destinations\、\homepage-community\ 并行实施
