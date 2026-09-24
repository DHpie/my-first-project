## Context

当前 ChinaBuddy 用户模块正在实施个人中心（`user-profile`）和消息通知（`user-notifications`）。`user-notifications` 变更将引入 WebSocket 基础设施（`WebSocketConfig`、连接管理、前端 Hook 模式），站内信可直接复用这些基础设施。

产品需求与交互规格详见 `docs/user-module/prd-direct-messages.md` 和 `docs/user-module/interaction-direct-messages.md`。

## Goals / Non-Goals

**Goals:**
- 设计会话、消息、屏蔽数据模型
- 实现会话管理 REST API（列表、创建、详情、标记已读、未读计数）
- 实现消息收发 REST API（发送、分页加载历史）
- 实现用户搜索 API（按昵称搜索，排除自己）
- 实现屏蔽/取消屏蔽 API
- 复用 `user-notifications` 建立的 WebSocket 基础设施，实现消息实时推送
- 实现前端会话列表页（`/messages`）、会话详情页（`/messages/{id}`）、新建会话 Dialog
- 实现消息乐观更新 + 发送失败重试
- 实现 30 天消息自动清理
- 实现频率限制（每用户每分钟 20 条）

**Non-Goals:**
- 消息已读回执（PRD 已确认不实现）
- 图片/文件发送（PRD 已确认仅支持纯文本）
- 群组消息（PRD 已确认仅支持一对一）
- 消息编辑/撤回（本期不支持）
- 消息搜索（本期不支持全文搜索）
- 富文本/Markdown 消息（仅纯文本）

## Decisions

### 1. 数据模型：三表设计（Conversation + Message + UserBlock）

**决策:**
- `conversations` 表：`id`、`user1_id`、`user2_id`、`last_message_at`、`created_at`，唯一约束 `(user1_id, user2_id)` 且 `user1_id < user2_id`
- `messages` 表：`id`、`conversation_id`、`sender_id`、`content TEXT`、`created_at`
- `user_blocks` 表：`id`、`blocker_id`、`blocked_id`、`created_at`，唯一约束 `(blocker_id, blocked_id)`
- `conversation_participants` 表：`conversation_id`、`user_id`、`unread_count`

**理由:**
- `user1_id < user2_id` 约束确保两个用户之间只有一条会话
- `messages.content` 使用 `TEXT` 类型，因为消息最长 1000 字符
- `conversation_participants` 表管理每个用户的未读计数

**替代方案:** 单表 `messages` + 查询推导会话列表 — rejected，查询性能差。

### 2. WebSocket 复用：在现有 WebSocketConfig 中追加消息处理器

**决策:** 复用 `user-notifications` 创建的 `WebSocketConfig`，新增 `/ws/messages` 端点和 `MessageWebSocketHandler`。

**理由:**
- 两个 WebSocket 端点共享同一连接基础设施
- 前端 Hook 模式已在通知功能中验证，直接复用

**替代方案:** 消息发送仅通过 REST API — rejected，REST 发送 + WebSocket 接收会导致消息延迟不一致。

### 3. 消息发送：REST API + WebSocket 推送

**决策:** 消息发送通过 REST API `POST /api/conversations/{id}/messages` 进行，服务端持久化后通过 WebSocket 推送给接收方。前端采用乐观更新——消息发送后立即在 UI 中显示（`opacity-60`），收到服务端确认后变为 `sent`，发送失败变为 `failed` + Retry。

**理由:**
- REST API 发送更可靠（有明确的 HTTP 响应），乐观更新确保 UI 即时反馈
- WebSocket 仅用于推送给接收方，简化双向通信复杂度

**替代方案:** 纯 WebSocket 双向发送 — rejected，增加连接状态管理复杂度，REST + WebSocket 推送模式更稳健。

### 4. 屏蔽机制：发送时校验 + 会话只读

**决策:**
- 发送消息时，后端校验发送者是否被对方屏蔽。如果被屏蔽，返回错误
- 被屏蔽方的会话进入只读模式，输入区域替换为提示文案
- 屏蔽方自己的会话列表中，被屏蔽用户的会话消失

**理由:**
- 发送时校验是最可靠的拦截点
- PRD 已确认被屏蔽方需要明确提示

### 5. 频率限制：后端拦截器 + 内存滑动窗口

**决策:** 使用 Spring Boot `HandlerInterceptor` 实现频率限制，基于内存 `ConcurrentHashMap` 的滑动窗口计数器（每用户每分钟最多 20 条消息）。

**理由:**
- 拦截器模式与现有 `GlobalExceptionHandler` 一致
- MVP 使用内存计数器，单实例足够

**替代方案:** Redis 限流 — rejected，MVP 不引入 Redis 依赖。

### 6. 前端页面结构：会话列表 + 会话详情（两页面 + Dialog）

**决策:**
- `/messages` — 会话列表页（Client Component）
- `/messages/{conversationId}` — 会话详情页（Client Component）
- NewConversationDialog — 搜索用户并发起会话的浮层

**理由:**
- 两页面结构清晰
- Mobile 下 Dialog 降级为底部 Sheet

## Risks / Trade-offs

- **[消息数据量]** → 30 天保留策略限制数据量 → `messages` 表需要合理索引（`conversation_id` + `created_at`）。
- **[屏蔽状态实时同步]** → 用户 A 屏蔽用户 B 后，B 可能正在查看会话 → B 的下一次发送操作会被后端拦截并返回错误。
- **[多标签页状态同步]** → 未读计数通过 WebSocket 推送同步，消息只在一个标签页标记已读即可。
- **[user1_id < user2_id 约束]** → 创建会话时需要排序两个用户 ID → 后端 Service 层处理排序逻辑。
