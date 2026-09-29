## MODIFIED Requirements

### Requirement: 迷你对话窗
迷你对话窗 SHALL 提供紧凑的会话界面，包含消息历史区、文本输入框与发送按钮。对话窗 header 区域 SHALL 包含 "New Chat" 按钮用于开启新对话。

#### Scenario: 对话窗尺寸
- **WHEN** 对话窗打开
- **THEN** 它 SHALL 显示为固定宽度 360px、高度 480px 的面板
- **AND** 面板 SHALL 位于悬浮按钮上方，间距 12px
- **NOTE** 对话窗 SHALL 包含一个关闭按钮（`X` 图标），提供除悬浮按钮和 Escape 之外的第三种关闭方式

#### Scenario: 对话窗无障碍
- **WHEN** 对话窗打开
- **THEN** 对话窗 SHALL 具有 `role="dialog"` 与 `aria-label="AI travel assistant chat"`
- **AND** 焦点 SHALL 被限制在对话窗内（Tab 仅在对话窗元素间循环）
- **AND** 聊天输入框 SHALL 具有 `aria-label="Type your message"`

#### Scenario: 初始状态 — 有历史消息
- **WHEN** 用户打开 AI 对话窗
- **AND** `GET /api/ai/chat/history` 返回非空消息列表
- **THEN** 对话窗 SHALL 显示所有历史消息（用户消息右对齐，AI 消息左对齐）
- **AND** SHALL 自动滚动至最新消息
- **AND** SHALL 保存返回的 conversationId

#### Scenario: 初始状态 — 无历史消息
- **WHEN** 用户打开 AI 对话窗
- **AND** 历史消息为空
- **THEN** 对话窗 SHALL 显示欢迎消息："Hi! I'm your AI travel assistant. Ask me anything about traveling in China!"
- **AND** 欢迎消息 SHALL 显示为 AI 消息（左对齐）

#### Scenario: 初始状态 — 历史加载失败
- **WHEN** 用户打开 AI 对话窗
- **AND** 历史消息 API 请求失败
- **THEN** 对话窗 SHALL 降级为显示欢迎消息
- **AND** SHALL NOT 显示错误提示（静默降级）

#### Scenario: 消息历史展示
- **WHEN** 用户已发送并接收消息
- **THEN** 所有消息 SHALL 按时间顺序显示（最早在顶部）
- **AND** 用户消息 SHALL 右对齐并使用独特的背景色
- **AND** AI 消息 SHALL 左对齐并使用不同的背景色

#### Scenario: 自动滚动至最新消息
- **WHEN** 新消息（用户或 AI）被加入聊天历史
- **WHEN** 新 token 到达并追加到 AI 消息内容
- **THEN** 消息区 SHALL 自动滚动以显示最新消息（`scrollIntoView({ behavior: "smooth" })`）

#### Scenario: Escape 键关闭对话窗
- **WHEN** 对话窗打开
- **AND** 用户按下 Escape 键
- **THEN** 对话窗 SHALL 关闭
- **AND** 焦点 SHALL 返回悬浮按钮

#### Scenario: 点击外部不关闭对话窗
- **WHEN** 对话窗打开
- **AND** 用户点击对话窗外部（页面背景）
- **THEN** 对话窗 SHALL 保持打开，防止意外丢失会话内容

#### Scenario: New Chat 按钮
- **WHEN** 对话窗打开
- **THEN** header 区域 SHALL 显示 "New Chat" 按钮
- **AND** 按钮 SHALL 具有 `aria-label="Start new chat"`

#### Scenario: 点击 New Chat
- **WHEN** 用户点击 "New Chat" 按钮
- **THEN** 前端 SHALL 调用 `DELETE /api/ai/chat/conversation`
- **AND** SHALL 清空本地消息历史
- **AND** SHALL 重置 conversationId 为 null
- **AND** SHALL 显示欢迎消息

#### Scenario: New Chat API 失败
- **WHEN** 新建对话 API 请求失败
- **THEN** 前端 SHALL 仅在本地清空消息历史并重置状态
- **AND** SHALL NOT 显示错误提示

### Requirement: 发送消息
用户 SHALL 能够使用 shadcn/ui `Input` 与 `Button` 组件输入并发送消息给 AI 助手。消息 SHALL 通过 SSE 流式接口发送，AI 回复逐字渲染。

#### Scenario: 消息发送成功（流式）
- **WHEN** 用户在输入框输入非空消息
- **AND** 用户点击发送按钮或按下 Enter
- **THEN** 系统 SHALL 携带消息文本和 conversationId 调用 `POST /api/ai/chat/stream`
- **AND** 用户消息 SHALL 立即出现在聊天历史中（乐观渲染）
- **AND** 发送后输入框 SHALL 被清空
- **AND** AI 回复 SHALL 随 SSE token 逐字增长

#### Scenario: 流式渲染
- **WHEN** SSE 流开始返回 token
- **THEN** AI 消息气泡 SHALL 随每个 token 到达逐步增长（逐字显示）
- **AND** 消息气泡末尾 SHALL 显示闪烁光标动画 `▊`
- **AND** 流结束后光标 SHALL 消失

#### Scenario: 流式期间输入禁用
- **WHEN** SSE 流式传输进行中
- **THEN** 发送按钮 SHALL 禁用
- **AND** 输入框 SHALL 禁用

#### Scenario: 会话 ID 维护
- **WHEN** SSE 结束事件包含 `conversationId`
- **THEN** 前端 SHALL 保存该 conversationId
- **AND** 后续消息 SHALL 携带此 conversationId

#### Scenario: 空消息
- **WHEN** 用户尝试发送空输入或纯空白输入
- **THEN** 系统 SHALL NOT 发送 API 请求
- **AND** SHALL 在输入框下方显示校验提示 "Please enter a message"

#### Scenario: 消息最大长度
- **WHEN** 用户输入或粘贴超过 500 字符的文本
- **THEN** 输入框 SHALL 拒绝超出 500 字符限制的字符

#### Scenario: 防止重复提交
- **WHEN** 流式传输进行中用户点击发送
- **THEN** 系统 SHALL 禁用发送按钮
- **AND** SHALL NOT 发送重复请求

### Requirement: 聊天 API
系统 SHALL 通过 `POST /api/ai/chat/stream` 端点以 SSE 流式方式与 AI 后端通信，替代原有的一次性 `POST /api/ai/chat` 端点。

#### Scenario: 流式请求成功
- **WHEN** 前端发送 POST 请求至 `/api/ai/chat/stream`
- **THEN** 响应 SHALL 为 `text/event-stream` MIME 类型
- **AND** SHALL 逐 token 接收 SSE 事件 `data: {"content":"..."}\n\n`
- **AND** 流结束 SHALL 接收 `data: {"content":"","done":true,"conversationId":...}\n\n`

#### Scenario: 网络失败
- **WHEN** SSE 连接因网络错误失败
- **THEN** 已接收的部分内容 SHALL 保留
- **AND** 对话窗 SHALL 以系统消息显示错误 "Sorry, something went wrong. Please try again."
- **AND** SHALL 显示 "Retry" 按钮以重发最后一条消息

#### Scenario: API 超时
- **WHEN** SSE 连接 30 秒内未收到首个 token
- **THEN** 系统 SHALL 中断请求
- **AND** SHALL 按网络失败处理（错误消息 + Retry 按钮）

#### Scenario: SSE 错误事件
- **WHEN** 后端发送 SSE 错误事件 `data: {"error":"..."}\n\n`
- **THEN** 对话窗 SHALL 以系统消息显示该错误内容
- **AND** SHALL 显示 "Retry" 按钮

## ADDED Requirements

### Requirement: 前端 SSE 流式消费
前端 SHALL 使用 `fetch` + `ReadableStream` 消费 SSE 流式响应，替代原有的 Axios 一次性请求。

#### Scenario: SSE 消费方式
- **WHEN** 用户发送消息
- **THEN** 前端 SHALL 使用 `fetch` API（非 Axios）发送 POST 请求至 `/api/ai/chat/stream`
- **AND** SHALL 通过 `ReadableStream` 逐 chunk 读取响应
- **AND** SHALL 解析 SSE `data:` 行提取 JSON 内容

#### Scenario: 错误事件处理
- **WHEN** SSE 流中包含 `error` 字段
- **THEN** SHALL 将错误内容作为系统消息显示
- **AND** SHALL 停止流式读取
