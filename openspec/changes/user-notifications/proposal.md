## Why

当前 ChinaBuddy 首页已完成全部功能实现并归档 7 个 homepage 变更，但缺乏用户社交互动反馈机制。用户在平台上发布的内容（帖子、评论等）被他人点赞、评论、回复时，没有任何通知渠道告知用户。消息通知是用户回流的核心驱动力——它告诉用户"有人关注了你"，是社区活跃度的关键指标。

本变更通过 WebSocket 实时推送，让登录用户及时收到互动通知，区分已读/未读状态，点击通知可跳转到对应帖子详情页查看互动上下文。

## What Changes

- **通知数据模型**：新增 `Notification` 实体，包含类型（like/comment/reply）、操作者、目标内容、已读状态、时间戳
- **通知生成服务**：在点赞、评论、回复等业务操作时自动生成通知记录
- **通知 API**：
  - `GET /api/notifications`：分页获取通知列表（每页 20 条）
  - `PUT /api/notifications/{id}/read`：标记单条通知已读
  - `PUT /api/notifications/read-all`：批量标记全部已读
  - `GET /api/notifications/unread-count`：获取未读通知数量
- **WebSocket 实时推送**：新增 WebSocket 端点 `/ws/notifications`，实时推送新通知到前端
- **通知数据清理**：超过 14 天的通知自动清理
- **Header 通知铃铛**：在 Header 右侧新增 `NotificationBell` 组件，显示未读计数 badge
- **通知面板**：点击铃铛展开 `NotificationPanel` 下拉面板，展示通知列表
- **通知跳转**：点击通知跳转到对应帖子详情页，同时标记已读
- **批量标记**：面板内 "Mark all as read" 一键清除所有未读

## Capabilities

### New Capabilities

- `user-notifications`：消息通知系统，包含通知生成、实时推送、通知列表展示、已读/未读管理

### Modified Capabilities

- `homepage-shell`：Header 右侧新增 `NotificationBell` 组件（需登录后显示）

## Impact

**前端代码**：
- 新增 3 个组件：`components/notifications/notification-bell.tsx`、`notification-panel.tsx`、`notification-item.tsx`
- 新增 1 个 API 层：`frontend/src/api/notifications.ts`
- 新增 1 个 WebSocket Hook：`frontend/src/lib/use-notification-ws.ts`
- 新增 1 个类型定义：`frontend/src/types/notification.ts`
- 修改 `frontend/src/components/layout/header.tsx`：集成 `NotificationBell`

**后端代码**：
- 新增 `entity/Notification.java`：通知实体
- 新增 `repository/NotificationRepository.java`：JPA 查询接口
- 新增 `controller/NotificationController.java`：REST API
- 新增 `dto/response/NotificationResponse.java`、`dto/response/UnreadCountResponse.java`
- 新增 `service/NotificationService.java` + `service/impl/NotificationServiceImpl.java`
- 新增 `config/WebSocketConfig.java`：WebSocket 配置
- 新增 `websocket/NotificationWebSocketHandler.java`：WebSocket 处理器
- 新增通知自动清理定时任务（`@Scheduled`）

**数据库**：
- 新增 `notifications` 表：`id`、`user_id`、`actor_id`、`type`（like/comment/reply）、`target_type`、`target_id`、`content_snippet`、`is_read`、`created_at`

**依赖**：
- 后端：新增 `spring-boot-starter-websocket`（WebSocket 支持）
- 前端：无新增依赖，WebSocket 使用浏览器原生 `WebSocket` API

**前置依赖**：
- `user-profile` 已实施或并行实施（通知需要展示操作者头像和昵称）
- 认证机制已存在（假设已有登录功能）
- 帖子/评论相关功能已存在（通知的目标内容）

**后续依赖**：
- 本变更不阻塞其他功能变更
- 通知的跳转目标（帖子详情页）可作为后续变更

**产品需求文档**：`docs/user-module/prd-notifications.md`
**交互规格文档**：`docs/user-module/interaction-notifications.md`
