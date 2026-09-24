## Purpose

为 ChinaBuddy 实现站内信（Direct Messages）系统——用户间一对一私信，包含会话列表、消息历史、消息收发、用户搜索、屏蔽机制。通过 WebSocket 实时收发消息，支持消息乐观更新、发送失败重试、断线重连补发。

## ADDED Requirements

### Requirement: 会话数据模型
系统 SHALL 提供 `Conversation` JPA 实体和 `conversation_participants` 关联表。

#### Scenario: Conversation 实体字段
- **WHEN** 创建新会话
- **THEN** `Conversation` SHALL 包含 `id`（Long）、`user1Id`（Long）、`user2Id`（Long）、`lastMessageAt`（LocalDateTime）、`createdAt`（LocalDateTime）
- **AND** `user1Id` SHALL 小于 `user2Id`（唯一约束保证）

#### Scenario: conversation_participants 表
- **WHEN** 创建新会话
- **THEN** 系统 SHALL 在 `conversation_participants` 表中为该会话的两个参与者各创建一条记录
- **AND** 每条记录 SHALL 包含 `conversationId`、`userId`、`unreadCount`（默认 0）

#### Scenario: 会话唯一性
- **WHEN** 用户 A 和用户 B 之间已有会话
- **AND** 尝试再次创建 A-B 会话
- **THEN** 系统 SHALL 返回已有会话，不创建重复会话

### Requirement: 消息数据模型
系统 SHALL 提供 `Message` JPA 实体。

#### Scenario: Message 实体字段
- **WHEN** 创建新消息
- **THEN** `Message` SHALL 包含 `id`（Long）、`conversationId`（Long）、`senderId`（Long）、`content`（String，TEXT 类型）、`createdAt`（LocalDateTime）

### Requirement: 屏蔽数据模型
系统 SHALL 提供 `UserBlock` JPA 实体。

#### Scenario: UserBlock 实体字段
- **WHEN** 用户 A 屏蔽用户 B
- **THEN** `UserBlock` SHALL 包含 `id`（Long）、`blockerId`（Long）、`blockedId`（Long）、`createdAt`（LocalDateTime）
- **AND** `(blockerId, blockedId)` SHALL 有唯一约束

### Requirement: 会话列表 API
系统 SHALL 提供 `GET /api/conversations` 端点，分页返回当前用户的会话列表。

#### Scenario: 获取会话列表
- **WHEN** 登录用户请求 `GET /api/conversations?page=0&size=20`
- **THEN** 系统 SHALL 返回 HTTP 200，`data` 包含会话列表（按 `lastMessageAt` 倒序，最多 20 条）
- **AND** 每条会话 SHALL 包含 `conversationId`、`otherUserAvatar`、`otherUserNickname`、`lastMessageSnippet`（截断 40 字符）、`lastMessageTime`、`unreadCount`

#### Scenario: 未登录访问
- **WHEN** 未登录用户请求会话列表
- **THEN** 系统 SHALL 返回 HTTP 401

### Requirement: 创建会话 API
系统 SHALL 提供 `POST /api/conversations` 端点，创建新会话或返回已有会话。

#### Scenario: 创建新会话
- **WHEN** 登录用户请求 `POST /api/conversations` 指定 `otherUserId`
- **AND** 与该用户之间没有已有会话
- **THEN** 系统 SHALL 创建新会话并返回 HTTP 200，`data` 包含 `conversationId`

#### Scenario: 已有会话
- **WHEN** 登录用户请求创建会话，但与目标用户之间已有会话
- **THEN** 系统 SHALL 返回已有会话的 `conversationId`（不创建重复）

#### Scenario: 自己对自己
- **WHEN** 用户尝试与自己创建会话
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Cannot create conversation with yourself"

### Requirement: 消息发送 API
系统 SHALL 提供 `POST /api/conversations/{id}/messages` 端点，发送文字消息。

#### Scenario: 成功发送消息
- **WHEN** 登录用户发送消息（1-1000 字符纯文本）到有效会话
- **AND** 发送者未被对方屏蔽
- **AND** 发送频率未超过限制
- **THEN** 系统 SHALL 持久化消息，更新会话 `lastMessageAt`，增加对方 `unreadCount`
- **AND** 通过 WebSocket 实时推送消息到接收方
- **AND** 返回 HTTP 200，`data` 包含消息对象

#### Scenario: 消息内容校验——空消息
- **WHEN** 用户发送空消息或纯空白消息
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Message content cannot be empty"

#### Scenario: 消息内容校验——超长
- **WHEN** 用户发送超过 1000 字符的消息
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Message must be 1000 characters or less"

#### Scenario: 被对方屏蔽时发送
- **WHEN** 用户尝试向已屏蔽自己的用户发送消息
- **THEN** 系统 SHALL 返回 HTTP 403，错误信息 "You have been blocked by this user"

#### Scenario: 频率限制
- **WHEN** 用户在一分钟内已发送 20 条消息
- **AND** 尝试发送第 21 条
- **THEN** 系统 SHALL 返回 HTTP 429，错误信息 "Too many messages, please slow down"

#### Scenario: 会话不存在或无权限
- **WHEN** 用户尝试向不存在的会话或非参与者会话发送消息
- **THEN** 系统 SHALL 返回 HTTP 404

### Requirement: 消息历史 API
系统 SHALL 提供 `GET /api/conversations/{id}/messages` 端点，分页返回消息列表。

#### Scenario: 获取消息历史
- **WHEN** 登录用户请求 `GET /api/conversations/{id}/messages?page=0&size=50`
- **THEN** 系统 SHALL 返回 HTTP 200，`data` 包含消息列表（按 `createdAt` 正序，每次 50 条）
- **AND** 每条消息 SHALL 包含 `id`、`content`、`timestamp`、`isMine`

#### Scenario: 超过 30 天的消息
- **WHEN** 请求的消息页中所有消息均超过 30 天
- **THEN** 系统 SHALL 返回空列表

### Requirement: 标记会话已读 API
系统 SHALL 提供 `PUT /api/conversations/{id}/read` 端点。

#### Scenario: 成功标记已读
- **WHEN** 登录用户请求标记会话已读
- **THEN** 系统 SHALL 将该会话中当前用户的 `unreadCount` 设为 0 并返回 HTTP 200

### Requirement: 未读会话计数 API
系统 SHALL 提供 `GET /api/conversations/unread-count` 端点。

#### Scenario: 获取未读计数
- **WHEN** 登录用户请求未读会话计数
- **THEN** 系统 SHALL 返回 HTTP 200，`data` 包含 `count`

### Requirement: 用户搜索 API
系统 SHALL 提供 `GET /api/users/search?nickname={query}` 端点。

#### Scenario: 搜索用户
- **WHEN** 登录用户请求搜索，`nickname` 参数 ≥ 2 字符
- **THEN** 系统 SHALL 返回匹配用户列表（最多 10 条），按昵称模糊匹配
- **AND** 结果 SHALL 排除当前用户自己
- **AND** 每条结果 SHALL 包含 `id`、`nickname`、`avatarUrl`

#### Scenario: 搜索参数过短
- **WHEN** `nickname` 参数 < 2 字符
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Search query must be at least 2 characters"

### Requirement: 屏蔽 API
系统 SHALL 提供屏蔽/取消屏蔽/屏蔽列表 API。

#### Scenario: 屏蔽用户
- **WHEN** 登录用户请求 `POST /api/users/{id}/block`
- **THEN** 系统 SHALL 创建屏蔽记录并返回 HTTP 200

#### Scenario: 取消屏蔽
- **WHEN** 登录用户请求 `DELETE /api/users/{id}/block`
- **THEN** 系统 SHALL 删除屏蔽记录并返回 HTTP 200

#### Scenario: 获取屏蔽列表
- **WHEN** 登录用户请求 `GET /api/users/blocked`
- **THEN** 系统 SHALL 返回当前用户屏蔽的用户列表

### Requirement: WebSocket 消息实时推送
系统 SHALL 通过 WebSocket 端点 `/ws/messages` 实时推送新消息。

#### Scenario: 新消息推送
- **WHEN** 用户 A 向用户 B 发送消息
- **AND** 用户 B 有活跃的 WebSocket 连接
- **THEN** 系统 SHALL 通过 WebSocket 推送消息数据到用户 B
- **AND** 推送 SHALL 包含 `conversationId`、`messageId`、`content`、`senderId`、`timestamp`

### Requirement: 消息自动清理
系统 SHALL 通过定时任务自动清理超过 30 天的消息记录。

#### Scenario: 定时清理执行
- **WHEN** 定时任务触发（每日执行）
- **THEN** 系统 SHALL 删除所有 `createdAt` 早于 30 天前的消息记录

### Requirement: 前端 MessagesBell 组件
Header 右侧 SHALL 渲染 `MessagesBell` 组件，展示未读会话计数 badge，点击跳转到 `/messages`。

#### Scenario: 未登录不渲染
- **WHEN** 用户未登录
- **THEN** MessagesBell SHALL NOT 渲染

#### Scenario: 有未读会话
- **WHEN** `unreadCount > 0`
- **THEN** 图标右上角 SHALL 显示红色 badge（与 NotificationBell 样式一致）

#### Scenario: 点击图标
- **WHEN** 用户点击消息图标
- **THEN** 路由 SHALL 导航到 `/messages`

### Requirement: 前端会话列表页
前端 SHALL 提供 `/messages` 路由页面，展示会话列表。页面需覆盖 loading / error / empty / data 四个互斥状态。

#### Scenario: loading 状态
- **WHEN** 首次拉取会话列表
- **THEN** 页面 SHALL 显示 5 行 Skeleton 占位

#### Scenario: error 状态
- **WHEN** 拉取失败
- **THEN** 页面 SHALL 显示错误提示 + Retry 按钮

#### Scenario: empty 状态
- **WHEN** 无会话
- **THEN** 页面 SHALL 显示 MessageCircle 图标 + "No messages yet" + CTA 按钮

#### Scenario: data 状态
- **WHEN** 有会话数据
- **THEN** 页面 SHALL 渲染 ConversationItem 列表，每条展示头像+昵称+消息片段+时间+未读 badge

### Requirement: 前端会话详情页
前端 SHALL 提供 `/messages/{conversationId}` 路由页面，展示消息历史。页面需覆盖 loading / error / not-found / blocked-by-me / blocked-by-other / deleted-user / data 七个互斥状态。

#### Scenario: data 状态——消息渲染
- **WHEN** 正常会话数据
- **THEN** 消息 SHALL 按时间正序展示
- **AND** 自己的消息 SHALL 靠右（`bg-primary text-primary-foreground`）
- **AND** 对方消息 SHALL 靠左（`bg-muted text-foreground`）

#### Scenario: 消息发送——乐观更新
- **WHEN** 用户发送消息
- **THEN** 消息 SHALL 立即出现在列表底部（`opacity-60` 表示 sending）
- **AND** 发送确认后变为正常样式
- **AND** 发送失败变为 "Failed to send" + Retry 按钮

#### Scenario: blocked-by-other 状态
- **WHEN** 对方已屏蔽当前用户
- **THEN** 消息历史 SHALL 以只读模式展示
- **AND** 输入区域 SHALL 替换为 "You have been blocked by this user"

#### Scenario: 自动滚动
- **WHEN** 新消息到达且用户在底部
- **THEN** 页面 SHALL 自动滚动到底部
- **WHEN** 新消息到达且用户在上方浏览历史
- **THEN** 页面 SHALL 显示 "↓ New messages" 浮动按钮

### Requirement: 前端新建会话 Dialog
前端 SHALL 提供 NewConversationDialog，搜索用户并发起/打开会话。

#### Scenario: 搜索用户
- **WHEN** 用户输入 ≥ 2 字符
- **THEN** 300ms debounce 后 SHALL 触发搜索 API，显示结果列表（最多 10 条）

#### Scenario: 选择用户
- **WHEN** 用户点击搜索结果
- **THEN** Dialog SHALL 关闭，路由 SHALL 导航到对应会话详情页

#### Scenario: 响应式
- **WHEN** Mobile（< 768px）
- **THEN** Dialog SHALL 以底部 Sheet 形式呈现
- **WHEN** Desktop（≥ 768px）
- **THEN** Dialog SHALL 以居中弹窗形式呈现（`w-[400px]`）

### Requirement: Block User 确认
会话详情页 SHALL 提供 Block User 功能，需二次确认。

#### Scenario: 确认 Block
- **WHEN** 用户确认 Block
- **THEN** 系统 SHALL 调用屏蔽 API
- **AND** 会话 SHALL 从列表消失
- **AND** 显示 toast "User blocked"

#### Scenario: Block 失败
- **WHEN** 屏蔽 API 失败
- **THEN** Dialog SHALL 保持打开
- **AND** 显示 toast "Failed to block user"
