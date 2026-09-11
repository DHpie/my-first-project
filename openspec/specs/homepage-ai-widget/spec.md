## Purpose

为 ChinaBuddy 首页提供悬浮 AI 助手入口——右下角固定按钮，点击打开迷你对话窗。让有特定目标的用户无需离开首页即可快速与 AI 助手交互（US-H3）。本组件 SHALL 实现为 Client Component（`"use client"`，状态管理、API 调用与用户交互所需）。

## In Scope

1. 悬浮操作按钮（右下角 fixed 定位）
2. 迷你对话窗（开关切换）
3. 消息输入与发送
4. 聊天消息历史展示（用户 + AI 消息）
5. `POST /api/ai/chat` API 集成与错误处理
6. 等待 AI 响应时的打字指示器
7. 对话窗响应式尺寸
8. 键盘无障碍（Escape 关闭、Enter 发送）

## Requirements

### Requirement: 悬浮按钮
系统 SHALL 在视口右下角始终显示一个 fixed 定位的悬浮按钮。

#### Scenario: 按钮可见性
- **WHEN** 首页被渲染
- **THEN** 右下角 SHALL 可见一个圆形悬浮按钮（直径 56px）
- **AND** 按钮 SHALL 距离右、下边缘 24px（`fixed bottom-6 right-6`）

#### Scenario: 按钮外观
- **WHEN** 悬浮按钮被渲染
- **THEN** 它 SHALL 显示 lucide-react 的 `Bot` 图标
- **AND** 按钮 SHALL 具有 `aria-label="Open AI assistant"` 以支持屏幕阅读器

#### Scenario: 点击按钮打开对话窗
- **WHEN** 用户点击悬浮按钮
- **AND** 对话窗当前关闭
- **THEN** 迷你对话窗 SHALL 在按钮上方展开
- **AND** 焦点 SHALL 移至聊天输入框

#### Scenario: 点击按钮关闭对话窗
- **WHEN** 对话窗打开且用户点击悬浮按钮
- **THEN** 对话窗 SHALL 收起
- **AND** 焦点 SHALL 返回悬浮按钮

### Requirement: 迷你对话窗
迷你对话窗 SHALL 提供紧凑的会话界面，包含消息历史区、文本输入框与发送按钮。

#### Scenario: 对话窗尺寸
- **WHEN** 对话窗打开
- **THEN** 它 SHALL 显示为固定宽度 360px、高度 480px 的面板
- **AND** 面板 SHALL 位于悬浮按钮上方，间距 12px

#### Scenario: 对话窗无障碍
- **WHEN** 对话窗打开
- **THEN** 对话窗 SHALL 具有 `role="dialog"` 与 `aria-label="AI travel assistant chat"`
- **AND** 焦点 SHALL 被限制在对话窗内（Tab 仅在对话窗元素间循环）
- **AND** 聊天输入框 SHALL 具有 `aria-label="Type your message"`

#### Scenario: 初始状态
- **WHEN** 对话窗首次打开
- **THEN** 它 SHALL 显示欢迎消息："Hi! I'm your AI travel assistant. Ask me anything about traveling in China!"
- **AND** 欢迎消息 SHALL 显示为 AI 消息（左对齐）

#### Scenario: 消息历史展示
- **WHEN** 用户已发送并接收消息
- **THEN** 所有消息 SHALL 按时间顺序显示（最早在顶部）
- **AND** 用户消息 SHALL 右对齐并使用独特的背景色
- **AND** AI 消息 SHALL 左对齐并使用不同的背景色

#### Scenario: 自动滚动至最新消息
- **WHEN** 新消息（用户或 AI）被加入聊天历史
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

### Requirement: 发送消息
用户 SHALL 能够使用 shadcn/ui `Input` 与 `Button` 组件输入并发送消息给 AI 助手。

#### Scenario: 消息发送成功
- **WHEN** 用户在输入框输入非空消息
- **AND** 用户点击发送按钮或按下 Enter
- **THEN** 系统 SHALL 携带消息文本调用 `POST /api/ai/chat`
- **AND** 用户消息 SHALL 立即出现在聊天历史中（乐观渲染）
- **AND** 发送后输入框 SHALL 被清空

#### Scenario: 打字指示器
- **WHEN** 用户消息已发送
- **AND** API 响应尚未返回
- **THEN** 用户消息下方 SHALL 显示打字指示器（三个跳动圆点）
- **AND** 此状态下发送按钮 SHALL 禁用

#### Scenario: 收到 AI 响应
- **WHEN** API 返回成功响应
- **THEN** 打字指示器 SHALL 被移除
- **AND** AI 回复 SHALL 追加至聊天历史

#### Scenario: 空消息
- **WHEN** 用户尝试发送空输入或纯空白输入
- **THEN** 系统 SHALL NOT 发送 API 请求
- **AND** SHALL 在输入框下方显示校验提示 "Please enter a message"

#### Scenario: 消息最大长度
- **WHEN** 用户输入或粘贴超过 500 字符的文本
- **THEN** 输入框 SHALL 拒绝超出 500 字符限制的字符

#### Scenario: 防止重复提交
- **WHEN** 请求进行中用户点击发送
- **THEN** 系统 SHALL 禁用发送按钮
- **AND** SHALL NOT 发送重复请求

### Requirement: 聊天 API
系统 SHALL 提供 REST API 端点 `POST /api/ai/chat`，接收用户消息并返回 AI 生成的响应。响应 SHALL 遵循项目统一的 `Result<T>` 信封格式。

#### Scenario: 请求成功
- **WHEN** 前端发送 POST 请求，body 为 `{ "message": "What should I visit in Beijing?" }`
- **THEN** API SHALL 返回 HTTP 200 与 `{ "code": 200, "message": "success", "data": { "reply": "..." } }`

#### Scenario: 非法输入 — 缺少字段
- **WHEN** 请求 body 缺少 `message` 字段
- **THEN** API SHALL 返回 HTTP 400 与 `{ "code": 400, "message": "Message field is required", "data": null }`

#### Scenario: 非法输入 — 超过最大长度
- **WHEN** `message` 字段超过 500 字符
- **THEN** API SHALL 返回 HTTP 400 与 `{ "code": 400, "message": "Message exceeds maximum length of 500 characters", "data": null }`

#### Scenario: 网络失败
- **WHEN** API 请求因网络错误失败
- **THEN** 打字指示器 SHALL 被移除
- **AND** 对话窗 SHALL 以系统消息显示错误 "Sorry, something went wrong. Please try again."
- **AND** SHALL 显示 "Retry" 按钮以重发最后一条消息

#### Scenario: API 超时
- **WHEN** API 请求 15 秒内未收到响应
- **THEN** 系统 SHALL 将其视为网络失败
- **AND** SHALL 显示相同的错误消息与 Retry 按钮

### Requirement: 响应式行为
悬浮按钮与对话窗 SHALL 使用 Tailwind CSS mobile-first 断点前缀适配不同视口尺寸。

#### Scenario: 移动端对话窗
- **WHEN** 视口宽度小于 480px
- **AND** 对话窗打开
- **THEN** 对话窗 SHALL 扩展至全宽减 32px 边距（`w-[calc(100vw-2rem)]`）
- **AND** 对话窗高度 SHALL 为 70vh（`h-[70vh]`）

#### Scenario: 桌面端对话窗
- **WHEN** 视口宽度为 480px 及以上
- **THEN** 对话窗 SHALL 使用固定 360px × 480px 尺寸

### Requirement: 消息历史上限
对话窗 SHALL 强制消息历史上限，防止内存无界增长（MVP：仅内存存储）。

#### Scenario: 消息数超限
- **WHEN** 消息总数（用户 + AI）超过 50 条
- **THEN** 最早的消息 SHALL 被移除，仅保留最新 50 条
- **AND** 欢迎消息 SHALL 始终作为首条消息保留

## Data Structures

### ChatMessage

```typescript
interface ChatMessage {
  /** 消息唯一标识 */
  id: string; // UUID 或基于时间戳
  /** 消息发送方角色 */
  role: "user" | "assistant" | "system";
  /** 消息文本内容 */
  content: string; // 用户消息最大 500 字符；assistant 消息不限
  /** 消息创建时间戳。MVP 阶段不作为 UI 展示项，保留供未来扩展 */
  timestamp: Date;
}
```

### ChatRequest

```typescript
interface ChatRequest {
  /** 用户消息文本 */
  message: string; // 必填，1–500 字符，已 trim
}
```

### ChatResponse

```typescript
interface ChatResponse {
  /** AI 生成的回复文本 */
  reply: string;
}
```

### AIWidgetProps

```typescript
interface AIWidgetProps {
  /** 无需 props — 状态在组件内部管理 */
}
```

### API 响应（参考）

```typescript
// POST /api/ai/chat → Result<ChatResponse>
interface ApiChatResponse {
  code: number;
  message: string;
  data: ChatResponse;
}
```

## Acceptance Checklist

### 悬浮按钮
- [ ] 56px 圆形按钮 fixed 于 `bottom-6 right-6`
- [ ] 显示 lucide-react 的 `Bot` 图标
- [ ] 具有 `aria-label="Open AI assistant"`
- [ ] 点击切换对话窗开关
- [ ] 打开时焦点移至输入框；关闭时焦点返回按钮

### 对话窗
- [ ] 360px × 480px 面板位于悬浮按钮上方
- [ ] 具有 `role="dialog"` 与 `aria-label="AI travel assistant chat"`
- [ ] 打开时焦点限制在对话窗内
- [ ] 首次打开显示欢迎消息
- [ ] 用户消息右对齐；AI 消息左对齐
- [ ] 新消息到达时自动滚动至最新消息

### 关闭行为
- [ ] 点击悬浮按钮 → 关闭对话窗
- [ ] 按下 Escape → 关闭对话窗，焦点返回按钮
- [ ] 点击外部 → 对话窗保持打开

### 发送消息
- [ ] 非空消息 + Enter/点击 → 调用 `POST /api/ai/chat`
- [ ] 用户消息立即显示（乐观渲染）
- [ ] 发送后输入框清空
- [ ] 等待期间显示打字指示器（3 个跳动圆点）
- [ ] 空/纯空白输入 → 显示 "Please enter a message" 校验提示
- [ ] 输入框拒绝超过 500 字符的字符
- [ ] 请求进行中发送按钮禁用

### API
- [ ] `POST /api/ai/chat` 响应遵循 `Result<T>` 信封格式
- [ ] 缺少 `message` 字段 → HTTP 400
- [ ] `message` > 500 字符 → HTTP 400
- [ ] 网络失败 → 错误消息 + Retry 按钮
- [ ] 超时（> 15s）→ 按网络失败处理

### 响应式
- [ ] 移动端（< 480px）：`w-[calc(100vw-2rem)] h-[70vh]`
- [ ] 桌面端（≥ 480px）：固定 360px × 480px

### 消息历史
- [ ] 最多保留 50 条消息；超出时移除最早的
- [ ] 欢迎消息始终保留

### 无障碍
- [ ] 悬浮按钮具有 `aria-label`
- [ ] 对话窗具有 `role="dialog"` + `aria-label`
- [ ] 聊天输入框具有 `aria-label="Type your message"`
- [ ] 焦点限制于对话窗；Escape 使焦点返回按钮

## Out of Scope

- 全屏聊天体验 — 首页仅提供迷你对话窗
- 页面刷新后的会话历史持久化（MVP：仅内存存储）
- 聊天会话的用户认证
- 流式 AI 响应（MVP：一次性返回完整响应）
- 聊天富媒体（图片、链接、Markdown 渲染）
- 多轮上下文记忆（MVP：每条消息相互独立）
- 会话导出或分享功能
- 语音输入或语音输出
