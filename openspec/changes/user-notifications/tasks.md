## 1. 后端 WebSocket 基础设施

- [ ] 1.1 在 `backend/pom.xml` 中添加 `spring-boot-starter-websocket` 依赖，验证 Maven 依赖安装成功
- [ ] 1.2 创建 `config/WebSocketConfig.java`，实现 `WebSocketConfigurer`，注册 `/ws/notifications` 端点（允许跨域），验证 WebSocket 端点可访问
- [ ] 1.3 创建 `websocket/NotificationWebSocketHandler.java`，继承 `TextWebSocketHandler`，实现连接建立（Token 鉴权 → 用户身份识别 → 存入 `ConcurrentHashMap<Long, WebSocketSession>`）、连接关闭（从 Map 移除）、错误处理，验证连接管理逻辑正确
- [ ] 1.4 实现 Token 鉴权逻辑：从 WebSocket 握手请求的 URL 参数 `token` 中提取 JWT，验证用户身份，无效 Token 拒绝连接，验证鉴权逻辑正确

## 2. 后端通知数据模型与服务

- [ ] 2.1 创建 `entity/Notification.java` JPA 实体，包含 `id`、`userId`、`actorId`、`type`（枚举 LIKE/COMMENT/REPLY）、`targetType`、`targetId`、`contentSnippet`、`isRead`（默认 false）、`createdAt`，验证编译通过
- [ ] 2.2 创建 `repository/NotificationRepository.java`，实现按 userId 分页查询（倒序）、按 userId 统计未读数、批量更新已读状态等查询方法，验证编译通过
- [ ] 2.3 创建 `dto/response/NotificationResponse.java`（id, type, actorAvatar, actorNickname, actionText, contentSnippet, timestamp, isRead, isContentDeleted）和 `dto/response/UnreadCountResponse.java`（count），验证编译通过
- [ ] 2.4 创建 `service/NotificationService.java` 接口和 `service/impl/NotificationServiceImpl.java`，实现通知创建（含重复点赞去重逻辑）、分页查询、标记已读、批量标记已读、未读计数，验证业务逻辑正确
- [ ] 2.5 实现通知创建时的 WebSocket 推送逻辑：创建通知后，检查用户是否有活跃 WebSocket 连接，有则推送 JSON 通知数据，验证推送在 1 秒内完成
- [ ] 2.6 实现重复点赞去重：用户 A 对用户 B 同一帖子重复点赞时，删除之前的未读通知再生成新通知；已读通知不删除，验证去重逻辑正确

## 3. 后端通知 REST API

- [ ] 3.1 创建 `controller/NotificationController.java`，实现 `GET /api/notifications?page=0&size=20` 端点（分页 + 时间倒序），验证返回正确数据结构
- [ ] 3.2 实现 `PUT /api/notifications/{id}/read` 端点（标记单条已读），验证属于当前用户 → 200、不属于 → 403、不存在 → 404
- [ ] 3.3 实现 `PUT /api/notifications/read-all` 端点（批量标记已读），验证所有未读通知被标记
- [ ] 3.4 实现 `GET /api/notifications/unread-count` 端点，验证返回正确未读数
- [ ] 3.5 实现未登录访问保护（所有通知 API 返回 401），验证未登录请求被拒绝

## 4. 后端通知生成集成与自动清理

- [ ] 4.1 在现有点赞业务逻辑中调用 `NotificationService.createNotification()`，传入 LIKE 类型参数，验证点赞时生成通知
- [ ] 4.2 在现有评论业务逻辑中调用 `NotificationService.createNotification()`，传入 COMMENT 类型参数，验证评论时生成通知
- [ ] 4.3 在现有回复业务逻辑中调用 `NotificationService.createNotification()`，传入 REPLY 类型参数，验证回复时生成通知
- [ ] 4.4 确保通知生成不触发给自己发通知（用户 A 给自己帖子点赞/评论/回复时不生成），验证无自通知
- [ ] 4.5 创建通知自动清理定时任务（`@Scheduled` 每日执行），删除 `createdAt` 早于 14 天前的通知记录，验证清理逻辑正确

## 5. 前端 WebSocket Hook 与 API 层

- [ ] 5.1 创建 `frontend/src/types/notification.ts`，定义 `Notification`、`NotificationListResponse`、`UnreadCountResponse`、`WebSocketNotificationMessage` 类型，验证 TypeScript 编译通过
- [ ] 5.2 创建 `frontend/src/api/notifications.ts`，封装 `getNotifications(page, size)`、`markAsRead(id)`、`markAllAsRead()`、`getUnreadCount()` 四个 API 调用，验证 TypeScript 编译通过
- [ ] 5.3 创建 `frontend/src/lib/use-notification-ws.ts` Hook，封装 WebSocket 连接管理（建立连接 + Token 鉴权、消息接收回调、断线重连指数退避初始 1s/最大 30s/最多 3 次、连接状态），验证 Hook 可正常建立连接

## 6. 前端 NotificationBell 组件

- [ ] 6.1 创建 `frontend/src/components/notifications/notification-bell.tsx`，实现铃铛图标渲染（`lucide-react` `Bell` 图标），未登录不渲染，验证组件可见
- [ ] 6.2 实现未读计数 badge：0 未读 → 无 badge、1-99 → 红色数字 badge（`bg-primary`）、> 99 → "99+"，验证 badge 显示正确
- [ ] 6.3 实现点击铃铛 toggle NotificationPanel 展开/收起，验证切换逻辑正确
- [ ] 6.4 实现新通知到达（面板关闭）时 badge +1 并触发弹跳动画（`scale-110 → scale-100`，200ms），验证动画效果

## 7. 前端 NotificationPanel 组件

- [ ] 7.1 创建 `frontend/src/components/notifications/notification-panel.tsx`（Popover 下拉面板），实现 5 个互斥状态：connecting / loading / error / empty / data，验证状态切换正确
- [ ] 7.2 实现 loading 状态（5 行 Skeleton 占位），验证 Skeleton 可见
- [ ] 7.3 实现 error 状态（AlertCircle 图标 + "Something went wrong" + Retry 按钮），验证错误状态正确
- [ ] 7.4 实现 empty 状态（Bell 图标 `opacity-30` + "No notifications yet" + 副文案），验证空状态正确
- [ ] 7.5 实现 data 状态：PanelHeader（标题 + "Mark all as read" 按钮）+ NotificationItem 列表 + LoadMoreTrigger，验证列表渲染正确
- [ ] 7.6 实现面板尺寸：Desktop `w-[360px]`、Mobile `w-[calc(100vw-32px)] max-w-[360px]`、`max-h-[480px]` + `overflow-y-auto`，验证尺寸正确
- [ ] 7.7 实现 Escape 关闭面板 + 焦点回到铃铛按钮，验证交互正确
- [ ] 7.8 实现 "Mark all as read" 按钮：有未读时显示 → 调用 API → 成功 → 全部已读样式 + badge 归零 + toast "All notifications marked as read"（3s），失败 → toast "Failed to mark all as read"（手动关闭），验证流程正确

## 8. 前端 NotificationItem 组件与通知交互

- [ ] 8.1 创建 `frontend/src/components/notifications/notification-item.tsx`，实现单条通知渲染：类型图标 + 操作者头像/昵称 + 动作描述 + 内容片段 + 时间戳，验证渲染正确
- [ ] 8.2 实现未读/已读视觉区分：未读 → 蓝色圆点 + `font-semibold` + `bg-primary/5`；已读 → 无圆点 + `font-normal` + `transparent`，验证样式正确
- [ ] 8.3 实现点击通知（内容存在）：调用 `markAsRead` API → 面板关闭 → 路由跳转 `/posts/{postId}` → badge -1，验证跳转流程
- [ ] 8.4 实现点击通知（内容已删除 `isContentDeleted === true`）：调用 `markAsRead` API → toast "This content is no longer available"（3s）→ 不跳转 + 面板保持 + badge -1，验证处理正确
- [ ] 8.5 实现通知分页：Load more 按钮 → spinner + "Loading..." → 追加 20 条 → 到达末尾显示 "No more notifications"，验证分页加载正确

## 9. WebSocket 断线重连

- [ ] 9.1 实现断线重连指数退避策略（初始 1s，每次翻倍，最大 30s，最多 3 次），面板底部显示 "Reconnecting..." 提示条，验证重连逻辑
- [ ] 9.2 实现重连成功后通过 REST API 拉取断线期间未读通知 + 提示条消失 + 新通知插入列表顶部，验证补发逻辑
- [ ] 9.3 实现重连超过 3 次后停止重连 + 提示条变为 "Connection lost. [Refresh]"，验证停止逻辑

## 10. 集成与验证

- [ ] 10.1 修改 `frontend/src/components/layout/header.tsx`，集成 `NotificationBell` 组件（右侧，需登录后显示），验证 Header 中铃铛可见
- [ ] 10.2 运行 `npm run build` 验证前端构建通过，无 TypeScript 编译错误
- [ ] 10.3 运行 `mvn spring-boot:run` 验证后端启动成功，WebSocket 端点和 REST API 可访问
- [ ] 10.4 在浏览器中验证完整流程：铃铛 badge 显示、面板展开/收起、通知列表加载、标记已读/批量标记、点击跳转、WebSocket 实时推送、断线重连、14 天清理（构建通过，待浏览器手动验证）
