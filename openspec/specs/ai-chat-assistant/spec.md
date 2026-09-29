## Purpose

将 ChinaBuddy 首页右下角 AI Travel Assistant 从 Mock 一次性响应升级为真正的智能聊天系统。通过后端集成通义千问（Qwen-Plus）大模型、SSE 流式输出、MySQL 多轮对话上下文持久化，为用户提供逐字流式渲染的真实 AI 对话体验。

## In Scope

1. 后端 SSE 流式聊天接口（`POST /api/ai/chat/stream`）
2. 后端对话历史查询接口（`GET /api/ai/chat/history`）
3. 后端新建对话接口（`DELETE /api/ai/chat/conversation`）
4. Spring AI OpenAI-Compatible Client 集成通义千问（Qwen-Plus）
5. MySQL 对话上下文持久化（ai_conversation + ai_message 表）
6. 多轮对话上下文管理（最近 20 条消息作为上下文窗口）
7. 固定 System Prompt（中国旅游专家角色）
8. 前端 SSE 流式消费与逐字渲染
9. 前端会话历史恢复（打开对话窗时加载历史）
10. 前端流式错误处理与重试

## Requirements

### Requirement: SSE 流式聊天接口

系统 SHALL 提供 `POST /api/ai/chat/stream` 端点，接收用户消息并通过 Server-Sent Events 流式返回 AI 生成的响应。响应 SHALL 为 `text/event-stream` MIME 类型。

#### Scenario: 流式请求成功
- **WHEN** 前端发送 POST 请求，body 为 `{ "message": "What should I visit in Beijing?" }`
- **AND** 请求携带有效的 `X-User-Id` header
- **THEN** API SHALL 返回 HTTP 200，Content-Type 为 `text/event-stream`
- **AND** SHALL 逐 token 发送 SSE 事件，格式为 `data: {"content":"token文本"}\n\n`
- **AND** 流结束时 SHALL 发送 `data: {"content":"","done":true}\n\n`
- **AND** SHALL 将用户消息和完整 AI 回复持久化到 ai_message 表

#### Scenario: 首条消息自动创建会话
- **WHEN** 用户首次发送消息
- **AND** 该用户无活跃会话（ai_conversation 中 `archived_at IS NULL` 的记录不存在）
- **THEN** 系统 SHALL 自动创建一条 ai_conversation 记录（user_id = 当前用户，title = "AI Travel Assistant"）
- **AND** SHALL 在 SSE 结束事件中返回 `conversationId`

#### Scenario: 后续消息携带 conversationId
- **WHEN** 用户发送后续消息
- **AND** 请求 body 包含 `{ "message": "...", "conversationId": 123 }`
- **THEN** 系统 SHALL 将消息追加到该会话
- **AND** SHALL 加载该会话的历史上下文

#### Scenario: 非法输入 — 缺少字段
- **WHEN** 请求 body 缺少 `message` 字段
- **THEN** API SHALL 返回 HTTP 400 与 `{ "code": 400, "message": "Message field is required", "data": null }`

#### Scenario: 非法输入 — 超过最大长度
- **WHEN** `message` 字段超过 500 字符
- **THEN** API SHALL 返回 HTTP 400 与 `{ "code": 400, "message": "Message exceeds maximum length of 500 characters", "data": null }`

#### Scenario: AI 服务不可用
- **WHEN** 通义千问 API 调用失败（网络错误、限流、服务不可达）
- **THEN** API SHALL 发送 SSE 错误事件 `data: {"error":"AI service unavailable. Please try again."}\n\n`
- **AND** SHALL 关闭 SSE 连接
- **AND** SHALL NOT 持久化本次消息

#### Scenario: 请求中断（客户端断开）
- **WHEN** 客户端在流式传输过程中断开连接
- **THEN** 系统 SHALL 停止向通义千问 API 的请求
- **AND** SHALL 丢弃未完成的 AI 回复（不持久化）

### Requirement: 多轮对话上下文管理

系统 SHALL 维护每个用户的多轮对话上下文，使 AI 能够理解上下文相关的追问。

#### Scenario: 上下文窗口构建
- **WHEN** 用户发送新消息
- **AND** 该会话已有历史消息
- **THEN** 系统 SHALL 从 ai_message 表加载最近 20 条消息（按时间倒序）
- **AND** SHALL 按时间正序排列为 `[system_prompt, ...history_messages, new_user_message]`
- **AND** 消息数组 SHALL 按 role 交替：user → assistant → user → assistant...

#### Scenario: 上下文窗口截断
- **WHEN** 会话历史消息超过 20 条
- **THEN** 系统 SHALL 仅取最近 20 条作为上下文
- **AND** 更早的消息 SHALL 保留在数据库中，但不发送给 AI 模型

#### Scenario: System Prompt
- **WHEN** 构建发送给通义千问的 messages 数组
- **THEN** 第一条消息 SHALL 为 system role
- **AND** 内容 SHALL 为固定的 ChinaBuddy 旅游专家角色 prompt
- **AND** prompt 内容 SHALL 在配置文件中定义（`application.yml`），支持运行时修改

#### Scenario: 空会话上下文
- **WHEN** 用户发送首条消息（无历史消息）
- **THEN** 发送给 AI 的 messages SHALL 仅包含 `[system_prompt, user_message]`

### Requirement: 对话历史查询接口

系统 SHALL 提供 `GET /api/ai/chat/history` 端点，返回用户当前会话的历史消息列表。

#### Scenario: 有会话历史
- **WHEN** 用户已有活跃会话（`archived_at IS NULL`）
- **AND** 请求携带 `X-User-Id` header
- **THEN** API SHALL 返回 HTTP 200 与该会话的所有消息（按时间正序）
- **AND** 响应格式为 `{ "code": 200, "data": { "conversationId": 123, "messages": [...] } }`

#### Scenario: 无会话历史
- **WHEN** 用户无活跃会话
- **THEN** API SHALL 返回 HTTP 200 与 `{ "code": 200, "data": { "conversationId": null, "messages": [] } }`

#### Scenario: 消息数量上限
- **WHEN** 会话消息超过 100 条
- **THEN** API SHALL 仅返回最近 100 条消息
- **AND** SHALL 在响应中包含 `hasMore: true` 标志

### Requirement: 新建对话接口

系统 SHALL 提供 `DELETE /api/ai/chat/conversation` 端点，清除用户当前会话并开启新对话。

#### Scenario: 清除现有会话
- **WHEN** 用户请求新建对话
- **AND** 用户已有活跃会话
- **THEN** 系统 SHALL 将旧 ai_conversation 记录的 `archived_at` 字段设为当前时间（逻辑归档，非物理删除）
- **AND** SHALL 保留旧会话的 ai_message 记录不变
- **AND** 下次发送消息时 SHALL 自动创建新的 ai_conversation 记录

#### Scenario: 无现有会话
- **WHEN** 用户请求新建对话
- **AND** 用户无活跃会话（`archived_at IS NULL` 的记录不存在）
- **THEN** API SHALL 返回 HTTP 200 且不做任何操作

### Requirement: 前端 SSE 流式消费

前端 SHALL 使用 `fetch` + `ReadableStream` 消费 SSE 流式响应，逐 token 渲染 AI 回复。

#### Scenario: 流式渲染
- **WHEN** 用户发送消息
- **AND** SSE 流开始返回 token
- **THEN** AI 消息气泡 SHALL 随每个 token 到达逐步增长（逐字显示）
- **AND** 消息气泡末尾 SHALL 显示闪烁光标动画 `▊`
- **AND** 流结束后光标 SHALL 消失

#### Scenario: 流式期间输入禁用
- **WHEN** SSE 流式传输进行中
- **THEN** 发送按钮 SHALL 禁用
- **AND** 输入框 SHALL 禁用
- **AND** TypingIndicator SHALL 隐藏（流式输出本身就是"正在输入"的视觉反馈）

#### Scenario: 自动滚动
- **WHEN** 新 token 到达并追加到 AI 消息内容
- **THEN** 消息区 SHALL 自动滚动至底部以显示最新内容

#### Scenario: 会话 ID 维护
- **WHEN** SSE 结束事件包含 `conversationId`
- **THEN** 前端 SHALL 保存该 conversationId
- **AND** 后续消息 SHALL 携带此 conversationId

### Requirement: 前端会话历史恢复

前端 SHALL 在打开对话窗时自动加载用户的历史消息。

#### Scenario: 有历史消息时恢复
- **WHEN** 用户打开 AI 对话窗
- **AND** `GET /api/ai/chat/history` 返回非空消息列表
- **THEN** 对话窗 SHALL 显示所有历史消息（用户消息右对齐，AI 消息左对齐）
- **AND** SHALL 自动滚动至最新消息
- **AND** SHALL 保存返回的 conversationId

#### Scenario: 无历史消息时显示欢迎
- **WHEN** 用户打开 AI 对话窗
- **AND** 历史消息为空
- **THEN** 对话窗 SHALL 显示欢迎消息（与现有行为一致）

#### Scenario: 历史加载失败
- **WHEN** 历史消息 API 请求失败
- **THEN** 对话窗 SHALL 降级为显示欢迎消息
- **AND** SHALL NOT 显示错误提示（静默降级）

### Requirement: 新建对话（前端）

对话窗 header 区域 SHALL 提供"New Chat"按钮，允许用户清除历史开始新对话。

#### Scenario: 点击新建对话
- **WHEN** 用户点击 "New Chat" 按钮
- **THEN** 前端 SHALL 调用 `DELETE /api/ai/chat/conversation`
- **AND** SHALL 清空本地消息历史
- **AND** SHALL 重置 conversationId 为 null
- **AND** SHALL 显示欢迎消息

#### Scenario: 新建对话 API 失败
- **WHEN** 新建对话 API 请求失败
- **THEN** 前端 SHALL 仅在本地清空消息历史并重置状态
- **AND** SHALL NOT 显示错误提示

### Requirement: 通义千问模型集成

后端 SHALL 通过 Spring AI OpenAI-Compatible Client 集成通义千问（Qwen-Plus）模型。

#### Scenario: 模型配置
- **WHEN** 后端启动
- **THEN** Spring AI ChatClient SHALL 配置 base-url 为 `https://dashscope.aliyuncs.com/compatible-mode/v1`
- **AND** API Key SHALL 从 `application.yml` 的 `spring.ai.openai.api-key` 读取
- **AND** 模型名称 SHALL 配置为 `qwen-plus`
- **AND** temperature SHALL 配置为 `0.7`

#### Scenario: API Key 缺失
- **WHEN** `spring.ai.openai.api-key` 未配置或为空
- **THEN** 应用 SHALL 正常启动
- **AND** 聊天接口 SHALL 返回友好的错误提示 "AI service not configured"

#### Scenario: 模型调用超时
- **WHEN** 通义千问 API 在 30 秒内未返回首个 token
- **THEN** 系统 SHALL 中断请求
- **AND** SHALL 通过 SSE 发送错误事件

### Requirement: 数据库持久化

系统 SHALL 使用 MySQL 持久化 AI 对话数据，包含会话表和消息表。

#### Scenario: ai_conversation 表
- **WHEN** 系统创建新会话
- **THEN** SHALL 插入记录到 ai_conversation 表
- **AND** 字段包含：id（BIGINT PK）、user_id（BIGINT INDEX）、title（VARCHAR 100）、archived_at（DATETIME nullable）、created_at、updated_at

#### Scenario: ai_message 表
- **WHEN** 系统持久化消息
- **THEN** SHALL 插入记录到 ai_message 表
- **AND** 字段包含：id（BIGINT PK）、conversation_id（BIGINT FK）、role（VARCHAR 20）、content（TEXT）、created_at

#### Scenario: 会话索引与活跃唯一性
- **WHEN** 系统尝试为用户创建新会话
- **THEN** 系统 SHALL 检查是否存在 `archived_at IS NULL` 的活跃会话
- **AND** 若存在活跃会话 SHALL 复用该会话而非创建新记录
- **AND** ai_conversation 表 SHALL 在 (user_id) 上建索引，通过业务逻辑保证活跃会话唯一性

### Requirement: 响应式行为与无障碍

升级后的对话窗 SHALL 保持现有的响应式布局与无障碍特性。

#### Scenario: 移动端对话窗
- **WHEN** 视口宽度小于 480px
- **THEN** 对话窗 SHALL 保持 `w-[calc(100vw-2rem)] h-[70vh]` 尺寸

#### Scenario: 桌面端对话窗
- **WHEN** 视口宽度为 480px 及以上
- **THEN** 对话窗 SHALL 保持 360px × 480px 尺寸

#### Scenario: 无障碍保持
- **WHEN** 对话窗渲染
- **THEN** SHALL 保持 `role="dialog"` 与 `aria-label`
- **AND** SHALL 保持焦点限制与 Escape 键关闭行为
- **AND** "New Chat" 按钮 SHALL 具有 `aria-label="Start new chat"`

## Data Structures

### AiChatStreamRequest

```typescript
interface AiChatStreamRequest {
  /** 用户消息文本 */
  message: string; // 必填，1–500 字符，已 trim
  /** 会话 ID（首次消息为 null，后续携带） */
  conversationId: number | null;
}
```

### AiChatHistoryResponse

```typescript
interface AiChatHistoryResponse {
  /** 会话 ID（无会话时为 null） */
  conversationId: number | null;
  /** 历史消息列表（按时间正序） */
  messages: AiChatMessage[];
  /** 是否有更多消息未返回 */
  hasMore: boolean;
}
```

### AiChatMessage

```typescript
interface AiChatMessage {
  /** 消息唯一标识 */
  id: number;
  /** 消息发送方角色 */
  role: "user" | "assistant";
  /** 消息文本内容 */
  content: string;
  /** 消息创建时间 ISO 字符串 */
  createdAt: string;
}
```

### SSE Event Data

```typescript
/** SSE 流中的单个事件数据 */
interface SseChunkData {
  /** 本次 token 文本片段（空字符串表示流结束） */
  content: string;
  /** 是否为流结束事件 */
  done?: boolean;
  /** 会话 ID（仅在结束事件中返回） */
  conversationId?: number;
  /** 错误信息（仅在错误事件中返回） */
  error?: string;
}
```

### ChatMessage（前端组件，升级）

```typescript
interface ChatMessageData {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  timestamp: Date;
  /** 是否正在流式接收中 */
  streaming?: boolean;
}
```

### 后端 Entity

```java
// AiConversation
@Entity
@Table(name = "ai_conversation")
public class AiConversation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false)
    private Long userId; // 通过业务逻辑保证活跃会话唯一（archived_at IS NULL）
    
    @Column(nullable = false, length = 100)
    private String title;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime archivedAt; // null = 活跃会话, non-null = 已归档时间
}

// AiMessage
@Entity
@Table(name = "ai_message")
public class AiMessage {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "conversation_id", nullable = false)
    private Long conversationId;
    
    @Column(nullable = false, length = 20)
    private String role; // "user" | "assistant"
    
    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;
    
    private LocalDateTime createdAt;
}
```

## Acceptance Checklist

### 后端 SSE 接口
- [ ] `POST /api/ai/chat/stream` 返回 `text/event-stream`
- [ ] SSE 事件格式为 `data: {"content":"..."}\n\n`
- [ ] 流结束发送 `data: {"content":"","done":true,"conversationId":...}\n\n`
- [ ] 缺少 `message` 字段 → HTTP 400
- [ ] `message` > 500 字符 → HTTP 400
- [ ] AI 服务不可用 → SSE 错误事件
- [ ] 客户端断开 → 停止 AI 请求，不持久化
- [ ] 用户消息和 AI 回复持久化到 ai_message 表

### 多轮上下文
- [ ] 加载最近 20 条历史消息作为上下文
- [ ] 超过 20 条时截断，仅取最近 20 条
- [ ] System prompt 作为首条消息
- [ ] System prompt 在 application.yml 中配置
- [ ] 空会话仅发送 [system_prompt, user_message]

### 历史查询与新建
- [ ] `GET /api/ai/chat/history` 返回会话消息列表
- [ ] 无会话时返回 `{ conversationId: null, messages: [] }`
- [ ] 超过 100 条时 `hasMore: true`
- [ ] `DELETE /api/ai/chat/conversation` 清除当前会话
- [ ] 旧会话标记为 archived（非物理删除）

### 通义千问集成
- [ ] Spring AI base-url 指向 `https://dashscope.aliyuncs.com/compatible-mode/v1`
- [ ] 模型名称为 `qwen-plus`
- [ ] API Key 从 application.yml 读取
- [ ] temperature 配置为 0.7
- [ ] API Key 缺失时返回友好提示

### 数据库
- [ ] ai_conversation 表含 id, user_id(索引), title, archived_at, created_at, updated_at
- [ ] 活跃会话唯一性通过业务逻辑保证（archived_at IS NULL）
- [ ] ai_message 表含 id, conversation_id(FK), role, content(TEXT), created_at

### 前端流式渲染
- [ ] 使用 fetch + ReadableStream 消费 SSE
- [ ] AI 消息逐字增长（逐 token 追加）
- [ ] 流式期间显示闪烁光标 `▊`
- [ ] 流结束后光标消失
- [ ] 流式期间输入框和发送按钮禁用
- [ ] 新 token 到达时自动滚动至底部
- [ ] 保存 SSE 结束事件中的 conversationId

### 前端会话恢复
- [ ] 打开对话窗时调用 `GET /api/ai/chat/history`
- [ ] 有历史时显示所有消息并滚动到底部
- [ ] 无历史时显示欢迎消息
- [ ] 历史加载失败时静默降级为欢迎消息

### 新建对话
- [ ] Header 区域 "New Chat" 按钮
- [ ] 点击后调用 `DELETE /api/ai/chat/conversation`
- [ ] 清空本地消息历史，重置 conversationId
- [ ] 显示欢迎消息
- [ ] API 失败时仅本地重置

### 响应式与无障碍
- [ ] 移动端 < 480px：`w-[calc(100vw-2rem)] h-[70vh]`
- [ ] 桌面端 ≥ 480px：360px × 480px
- [ ] 保持 `role="dialog"` + `aria-label`
- [ ] 保持焦点限制与 Escape 关闭
- [ ] "New Chat" 按钮 `aria-label="Start new chat"`

### 错误处理
- [ ] SSE 连接中断 → 保留已接收内容 + 追加错误消息
- [ ] 超时（30s 无首 token）→ 中断请求，显示错误 + Retry
- [ ] 网络错误 → 显示错误消息 + Retry 按钮

## Out of Scope

- 多会话管理（侧边栏会话列表） — 当前仅支持单会话模式
- 聊天富媒体（图片、链接预览、Markdown 渲染）
- 会话导出或分享功能
- 语音输入或语音输出
- 对话消息的编辑、删除、搜索
- 消息分页加载（历史超过 100 条时的翻页 UI）
- AI 回复的用户评分（点赞/踩）
- Token 用量统计与计费面板
- 多语言 System Prompt 动态切换
- 对话上下文的手动管理（用户选择包含/排除特定消息）
- 向量数据库集成（RAG 检索增强）
