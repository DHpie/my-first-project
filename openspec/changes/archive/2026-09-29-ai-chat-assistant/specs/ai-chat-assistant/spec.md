## Purpose

为 ChinaBuddy 提供真正的 AI 智能聊天能力——后端集成通义千问（Qwen-Plus）大模型，通过 SSE 流式输出逐 token 推送 AI 回复，MySQL 持久化多轮对话上下文，使 AI 助手能理解上下文相关的追问并跨页面刷新恢复会话历史。

## ADDED Requirements

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
系统 SHALL 提供 `DELETE /api/ai/chat/conversation` 端点，归档用户当前会话。

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
