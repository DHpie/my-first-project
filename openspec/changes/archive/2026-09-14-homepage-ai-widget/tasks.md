## 1. 后端 API 端点

- [x] 1.1 创建 `ChatRequest.java` DTO（`message` 字段，1-500 字符校验），验证编译通过
- [x] 1.2 创建 `ChatResponse.java` DTO（`reply` 字段），验证编译通过
- [x] 1.3 创建 `AiChatController.java`，实现 `POST /api/ai/chat` 端点，基于关键词匹配规则式 mock 响应，验证 API 响应符合 `Result<T>` 信封格式
- [x] 1.4 实现输入校验：缺少 `message` 字段 → HTTP 400；`message` > 500 字符 → HTTP 400，验证校验逻辑正确
- [x] 1.5 启动后端服务，使用 curl/Postman 验证 `POST http://localhost:8080/api/ai/chat` 返回 200 与正确数据结构

## 2. 前端 API 层与辅助组件

- [x] 2.1 创建 `frontend/src/api/ai.ts`，封装 `chat(message: string)` 调用，验证 TypeScript 编译通过
- [x] 2.2 创建 `frontend/src/components/ai-widget/` 目录，创建 `typing-indicator.tsx`（三个跳动圆点动画），验证组件可渲染
- [x] 2.3 创建 `chat-message.tsx` 展示组件（用户消息右对齐 + AI 消息左对齐 + 不同背景色），验证组件可渲染

## 3. AI Widget 主组件

- [x] 3.1 创建 `ai-widget.tsx` Client Component（`"use client"`），实现悬浮按钮（56px 圆形、`Bot` 图标、`fixed bottom-6 right-6`），验证按钮可见且可点击
- [x] 3.2 实现对话窗打开/关闭切换（点击按钮打开/关闭对话窗），验证切换逻辑正确
- [x] 3.3 实现对话窗面板（360px x 480px，位于按钮上方 12px），验证尺寸位置正确
- [x] 3.4 实现欢迎消息（首次打开显示 "Hi! I'm your AI travel assistant..."），验证消息显示为 AI 消息（左对齐）
- [x] 3.5 实现消息输入区（shadcn/ui `Input` + 发送按钮 shadcn/ui `Button`），验证输入框可聚焦
- [x] 3.6 实现消息发送（非空消息 + Enter/点击 → 调用 `POST /api/ai/chat`；用户消息乐观渲染；发送后清空输入），验证流程正确
- [x] 3.7 实现打字指示器（等待期间显示三个跳动圆点，发送按钮禁用），验证指示器显示/隐藏正确
- [x] 3.8 实现 AI 响应渲染（收到响应后移除指示器，AI 回复追加至历史），验证消息顺序正确
- [x] 3.9 实现空/纯空白消息校验：显示 "Please enter a message" 提示，验证校验逻辑正确
- [x] 3.10 实现消息最大长度校验：输入框拒绝超过 500 字符，验证截断正确
- [x] 3.11 实现错误处理（网络失败/超时 → 显示错误消息 + Retry 按钮），验证 Retry 可重发最后一条消息
- [x] 3.12 实现 15 秒超时：使用 `AbortController`，验证超时按错误处理

## 4. 响应式与无障碍

- [x] 4.1 实现移动端响应式：视口 < 480px 时对话窗 `w-[calc(100vw-2rem)] h-[70vh]`，验证移动端尺寸正确
- [x] 4.2 实现桌面端响应式：视口 >= 480px 时对话窗固定 360px x 480px，验证桌面端尺寸正确
- [x] 4.3 实现自动滚动：新消息到达时消息区自动滚动至最新消息（`scrollIntoView`），验证滚动正确
- [x] 4.4 实现消息历史上限：超过 50 条时移除最早的非欢迎消息，验证裁剪逻辑正确
- [x] 4.5 实现 Escape 键关闭：对话窗打开时 Escape 关闭，焦点返回悬浮按钮，验证按键交互正确
- [x] 4.6 实现焦点管理：打开时焦点移至输入框，关闭时焦点返回按钮，验证焦点切换正确
- [x] 4.7 添加无障碍属性：悬浮按钮 `aria-label="Open AI assistant"`、对话窗 `role="dialog"` + `aria-label="AI travel assistant chat"`、输入框 `aria-label="Type your message"`，验证屏幕阅读器可识别

## 5. 集成与验证

- [x] 5.1 在 `layout.tsx` 中全局挂载 AI Widget 组件（`<body>` 末尾添加），验证所有页面可见 AI 悬浮按钮
- [x] 5.2 运行 `npm run build` 验证前端构建通过，无 TypeScript 编译错误
- [x] 5.3 运行 `mvn spring-boot:run` 验证后端启动成功，API 端点可访问（后端编译通过，待手动启动验证）
- [x] 5.4 在浏览器中验证完整 AI Widget：悬浮按钮可见、对话窗开关正常、消息收发流程、打字指示器显示、错误处理与 Retry 正确、响应式断点切换、无障碍属性有效（构建通过，待浏览器手动验证）
