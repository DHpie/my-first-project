## Context

当前首页 \rontend/src/app/layout.tsx\ 仅包含 RootLayout（html/body/children），尚未挂载 AI Widget。\homepage-shell\ 变更已实现页面骨架，但 AI Widget 为 fixed 定位悬浮层，挂载于 layout 级别而非 page 级别，对 shell 零依赖。后端已有 Spring Boot 项目结构，包含 User CRUD 的完整分层。本区域需要新增 \POST /api/ai/chat\ API 端点，MVP 阶段使用规则式 mock 响应。

## Goals / Non-Goals

**Goals:**
- 在 \layout.tsx\ 中全局挂载 AI Widget 组件
- 实现悬浮按钮（fixed bottom-6 right-6）+ 迷你对话窗
- 实现消息收发、乐观渲染、打字指示器、错误处理与 Retry
- 新增后端 API 端点返回规则式 mock 响应
- 实现键盘无障碍（Escape 关闭、Enter 发送、焦点管理）

**Non-Goals:**
- 全屏聊天体验（首页仅提供迷你对话窗）
- 会话历史持久化（MVP：仅内存存储）
- 流式 AI 响应（MVP：一次性返回完整响应）
- 聊天富媒体（图片、链接、Markdown 渲染）
- 多轮上下文记忆（MVP：每条消息相互独立）

## Decisions

### 1. 挂载位置：layout.tsx 而非 page.tsx

**决策:** AI Widget 挂载于 \rontend/src/app/layout.tsx\ 的 \<body>\ 末尾，而非 \page.tsx\。

**理由:**
- AI Widget 为 fixed 定位悬浮层，需要在所有页面可见（包括未来的子页面）
- 挂载于 layout 级别确保跨路由一致性
- 不占用 page.tsx 的 section slot 序列

**替代方案:** 挂载于 \page.tsx\ — rejected，仅首页可见，不符合悬浮助手的全局性需求。

### 2. 组件结构：单一 Client Component 内聚

**决策:** AI Widget 实现为单一 Client Component（\i-widget.tsx\），内部包含悬浮按钮、对话窗、消息列表、输入框。辅助组件 \chat-message.tsx\ 和 \	yping-indicator.tsx\ 为纯展示子组件。

**理由:**
- 状态管理（isOpen、messages、isLoading、error）集中在一个组件，避免 prop drilling
- 对话窗与按钮的开关切换逻辑内聚
- 纯展示子组件可独立测试

### 3. 后端 API：规则式 mock 响应

**决策:** \AiChatController\ 实现关键词匹配规则，返回预设响应。例如：包含 "Beijing" → 北京旅游建议；包含 "food" → 美食推荐；默认 → 通用旅行建议。

**理由:**
- MVP 阶段无需接入真实 AI 服务（如 OpenAI API）
- 规则式响应可验证前端集成流程
- 后续接入真实 AI 服务时仅需替换 Controller 内部逻辑，接口不变

**替代方案:** 接入 OpenAI API — rejected，MVP 阶段需要 API key、计费、速率限制等额外复杂度。

### 4. 焦点管理：useRef + useEffect

**决策:** 使用 \useRef\ 引用输入框和按钮元素，通过 \useEffect\ 在对话窗开关时管理焦点。Escape 键通过 \useEffect\ 监听 \keydown\ 事件。

**理由:**
- React 标准焦点管理模式
- \useEffect\ 清理函数确保事件监听器不泄漏

### 5. 消息历史限制

**决策:** 每次添加新消息后检查总数，超过 50 条时移除最早的非欢迎消息。欢迎消息始终保留。

**理由:**
- 防止内存无界增长
- 欢迎消息作为对话起点，始终保留

## Risks / Trade-offs

- **[API 端点尚未实现]** → 前端开发阶段可使用 mock 数据或 \/api/ai/chat\ 返回 404，按错误状态处理
- **[规则式 mock 响应局限性]** → 用户体验受限，但 MVP 阶段可接受，后续接入真实 AI 服务
- **[焦点限制实现复杂度]** → 完整焦点限制（Tab 循环）需要额外的 \keydown\ 监听，MVP 阶段可简化为 Escape 关闭 + 输入框自动聚焦
- **[layout.tsx 修改影响]** → 修改 layout 可能影响所有页面，需验证 AI Widget 不干扰其他页面的布局与交互
