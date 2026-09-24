## Why

当前 ChinaBuddy 用户模块仅有个人中心（`user-profile`）和消息通知（`user-notifications`），缺乏用户间直接沟通渠道。站内信是社区深度互动的载体——用户可能想向去过的旅行者请教经验、协调结伴出行、或询问目的地细节。没有站内信，用户之间的沟通只能依赖外部工具，平台无法形成完整的社交闭环。

本变更实现一对一私信系统，通过 WebSocket 实时收发消息，将会话列表、消息历史、用户搜索、屏蔽机制整合为完整的站内信体验。

## What Changes

- **会话数据模型**：新增 `Conversation` 实体，包含两个参与者 ID、最后消息时间、创建时间
- **消息数据模型**：新增 `Message` 实体，包含会话 ID、发送者 ID、消息内容、时间戳
- **屏蔽数据模型**：新增 `UserBlock` 实体，记录屏蔽关系（blocker_id, blocked_id）
- **会话 API**：
  - `GET /api/conversations`：分页获取当前用户会话列表（每页 20 条，按最后消息时间倒序）
  - `POST /api/conversations`：创建新会话（指定对方用户 ID），若已有会话则返回已有会话
  - `GET /api/conversations/{id}`：获取会话详情 + 分页消息列表（每页 50 条）
  - `GET /api/conversations/{id}/messages`：分页加载更早消息
  - `PUT /api/conversations/{id}/read`：标记会话所有消息已读
  - `GET /api/conversations/unread-count`：获取未读会话总数
- **消息发送 API**：`POST /api/conversations/{id}/messages`：发送文字消息（1-1000 字符）
- **用户搜索 API**：`GET /api/users/search?nickname={query}`：按昵称搜索用户（≥2 字符，最多 10 条，排除自己）
- **屏蔽 API**：
  - `POST /api/users/{id}/block`：屏蔽指定用户
  - `DELETE /api/users/{id}/block`：取消屏蔽
  - `GET /api/users/blocked`：获取屏蔽列表
- **WebSocket 实时推送**：新增 WebSocket 端点 `/ws/messages`，实时推送新消息到前端
- **消息数据清理**：超过 30 天的消息自动清理
- **频率限制**：每用户每分钟最多发送 20 条消息
- **前端会话列表页**：新增 `/messages` 路由，展示会话列表 + 新建会话入口
- **前端会话详情页**：新增 `/messages/{conversationId}` 路由，展示消息历史 + 输入框
- **前端新建会话 Dialog**：搜索用户并发起/打开会话
- **前端 Header 消息图标**：在 Header 右侧新增 `MessagesBell` 组件，显示未读会话计数 badge

## Capabilities

### New Capabilities

- `user-direct-messages`：站内信系统，包含会话管理、消息收发、实时推送、用户搜索、屏蔽机制

### Modified Capabilities

- `homepage-shell`：Header 右侧新增 `MessagesBell` 组件（需登录后显示）

## Impact

**前端代码**：
- 新增 2 个页面：`frontend/src/app/messages/page.tsx`、`frontend/src/app/messages/[conversationId]/page.tsx`
- 新增 9 个组件：`components/messages/conversation-list.tsx`、`conversation-item.tsx`、`message-list.tsx`、`message-bubble.tsx`、`message-input.tsx`、`new-conversation-dialog.tsx`、`messages-bell.tsx`、`conversation-header.tsx`、`conversation-menu.tsx`
- 新增 1 个 API 层：`frontend/src/api/messages.ts`
- 新增 1 个 WebSocket Hook：`frontend/src/lib/use-message-ws.ts`
- 新增 1 个类型定义：`frontend/src/types/message.ts`
- 修改 `frontend/src/components/layout/header.tsx`：集成 `MessagesBell`

**后端代码**：
- 新增 `entity/Conversation.java`、`entity/Message.java`、`entity/UserBlock.java`
- 新增 `repository/ConversationRepository.java`、`repository/MessageRepository.java`、`repository/UserBlockRepository.java`
- 新增 `controller/ConversationController.java`、`controller/MessageController.java`、`controller/UserBlockController.java`、`controller/UserSearchController.java`
- 新增 `dto/request/` 下：`SendMessageRequest.java`、`CreateConversationRequest.java`
- 新增 `dto/response/` 下：`ConversationResponse.java`、`MessageResponse.java`、`UnreadConversationCountResponse.java`、`UserSearchResultResponse.java`
- 新增 `service/ConversationService.java` + `impl/ConversationServiceImpl.java`
- 新增 `service/MessageService.java` + `impl/MessageServiceImpl.java`
- 新增 `service/UserBlockService.java` + `impl/UserBlockServiceImpl.java`
- 新增 `config/WebSocketConfig.java` 中追加消息 WebSocket 处理器映射（复用 `user-notifications` 已创建的 WebSocket 配置）
- 新增 `websocket/MessageWebSocketHandler.java`
- 新增消息自动清理定时任务（`@Scheduled`）
- 新增频率限制拦截器

**数据库**：
- 新增 `conversations` 表：`id`、`user1_id`、`user2_id`、`last_message_at`、`created_at`
- 新增 `messages` 表：`id`、`conversation_id`、`sender_id`、`content`（TEXT）、`created_at`
- 新增 `user_blocks` 表：`id`、`blocker_id`、`blocked_id`、`created_at`
- 新增 `conversation_participants` 表：`conversation_id`、`user_id`、`unread_count`

**依赖**：
- 后端：复用 `user-notifications` 已引入的 `spring-boot-starter-websocket`
- 前端：无新增依赖

**前置依赖**：
- `user-profile` 已实施或并行实施（站内信需要展示用户头像和昵称）
- 认证机制已存在（假设已有登录功能）

**后续依赖**：
- 本变更不阻塞其他功能变更

**产品需求文档**：`docs/user-module/prd-direct-messages.md`
**交互规格文档**：`docs/user-module/interaction-direct-messages.md`
