## Context

当前 ChinaBuddy 首页已完成全部功能实现并归档 7 个 homepage 变更，用户模块个人中心（`user-profile`）正在并行实施。平台缺乏用户社交互动反馈机制——帖子被点赞、评论、回复时，内容发布者无法收到任何通知。

后端尚未引入 WebSocket 支持，本变更是平台首个 WebSocket 功能，需要建立 WebSocket 基础设施（配置、连接管理、消息协议），为后续站内信（`user-direct-messages`）复用奠定基础。

产品需求与交互规格详见 `docs/user-module/prd-notifications.md` 和 `docs/user-module/interaction-notifications.md`。

## Goals / Non-Goals

**Goals:**
- 设计通知数据模型（`Notification` 实体）
- 实现通知生成服务（在点赞、评论、回复时生成通知）
- 实现通知 REST API（列表分页、标记已读、未读计数）
- 建立 WebSocket 基础设施并实现实时通知推送
- 实现前端 `NotificationBell` + `NotificationPanel` + `NotificationItem` 组件体系
- 实现通知点击跳转到帖子详情页
- 实现 14 天通知自动清理
- 实现 WebSocket 断线自动重连（指数退避，最大 30s）

**Non-Goals:**
- 通知聚合（同一内容多次点赞合并为一条）— PRD 已确认不聚合
- 通知设置/偏好（用户无法自定义接收哪些类型的通知）
- 推送通知（浏览器 Push Notification / 移动端推送）
- 帖子详情页实现（通知跳转目标，可作为后续变更）
- 通知图片/富媒体内容（仅文本 snippet）

## Decisions

### 1. WebSocket 基础设施：Spring Boot WebSocket + 原生浏览器 WebSocket API

**决策:** 后端引入 `spring-boot-starter-websocket`，使用 `WebSocketHandler` + `WebSocketConfigurer` 注册处理器。前端使用浏览器原生 `WebSocket` API。

**理由:**
- Spring Boot WebSocket starter 是官方标准方案
- 浏览器原生 `WebSocket` API 零依赖，适合单向推送场景
- 避免引入 Socket.IO 等重依赖

**替代方案:** Socket.IO — rejected，非标准协议。STOMP over WebSocket — rejected，对简单推送过度设计。SSE — rejected，WebSocket 更通用且站内信也需要。

### 2. WebSocket 连接管理：用户级单连接 + Token 鉴权

**决策:** 每个登录用户在前端建立一条 WebSocket 连接（`ws://host/ws/notifications?token={jwt}`），后端通过 Token 识别用户身份。连接存储在 `ConcurrentHashMap<Long, WebSocketSession>` 中。

**理由:**
- 单连接模式简化消息分发逻辑
- Token 鉴权复用现有认证机制
- `ConcurrentHashMap` 线程安全

**替代方案:** 用户级多连接（多标签页各建一条）— rejected，增加服务端资源消耗。

### 3. 通知数据模型：单表设计

**决策:** 使用单张 `notifications` 表存储所有类型通知，通过 `type` 字段区分（like/comment/reply）。

**理由:**
- 三种通知类型结构相似，单表足以表达
- `contentSnippet` 存储截断后的文本，避免查询时 JOIN 原始内容表
- `target_type` + `target_id` 多态关联支持未来扩展

**替代方案:** 每种通知类型独立表 — rejected，结构高度相似，独立表增加查询复杂度。

### 4. 通知生成：业务服务内调用 NotificationService

**决策:** 在现有的点赞、评论、回复业务逻辑中，调用 `NotificationService.createNotification()` 方法生成通知。通知生成与业务操作在同一事务中。

**理由:**
- 同步生成确保通知与业务操作一致性
- `NotificationService` 封装通知创建逻辑，业务服务只需传入必要参数

**替代方案:** 异步事件驱动（`@EventListener`）— rejected，MVP 阶段同步调用足够。

### 5. 通知面板：Popover 下拉面板（非独立页面）

**决策:** 通知面板作为 `NotificationBell` 的 Popover 下拉实现，不创建独立的 `/notifications` 路由页面。

**理由:**
- 通知是轻量级交互——用户快速查看 → 点击跳转 → 关闭面板
- Popover 面板不离开当前页面，用户体验更流畅

**替代方案:** 独立 `/notifications` 页面 — rejected，通知列表不需要全屏展示。

### 6. WebSocket 断线重连：指数退避 + 拉取补发

**决策:** 前端 WebSocket 断线后，使用指数退避策略自动重连（初始 1s，每次翻倍，最大 30s，最多 3 次）。重连成功后，通过 REST API 拉取断线期间的未读通知。

**理由:**
- 指数退避避免频繁重连对服务端造成压力
- REST API 拉取补发确保不遗漏通知
- 3 次上限避免无限重连循环

## Risks / Trade-offs

- **[WebSocket 首次引入]** → 本变更是平台首个 WebSocket 功能 → 基础设施可被后续 `user-direct-messages` 复用，是一次性投入。
- **[通知生成与业务耦合]** → 在点赞/评论/回复服务中直接调用 `NotificationService` 增加耦合 → MVP 阶段可接受，后续可通过事件总线解耦。
- **[ConcurrentHashMap 连接存储]** → 内存存储不支持多实例部署 → MVP 单实例可接受，后续引入 Redis Pub/Sub。
- **[通知 14 天清理]** → 定时清理任务在单实例上执行 → MVP 单实例无需分布式锁。
- **[帖子详情页不存在]** → 通知跳转到帖子详情页，但该页面可能尚未实现 → 跳转 URL 先定义好（`/posts/{postId}`），页面不存在时显示 404。
