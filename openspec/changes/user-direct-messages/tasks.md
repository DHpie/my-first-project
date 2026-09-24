## 1. 后端数据模型

- [ ] 1.1 创建 `entity/Conversation.java` JPA 实体，包含 `id`、`user1Id`、`user2Id`、`lastMessageAt`、`createdAt`，添加 `(user1Id, user2Id)` 唯一约束且 `user1Id < user2Id`，验证编译通过
- [ ] 1.2 创建 `entity/ConversationParticipant.java` JPA 实体，包含 `conversationId`、`userId`、`unreadCount`（默认 0），复合主键 `(conversationId, userId)`，验证编译通过
- [ ] 1.3 创建 `entity/Message.java` JPA 实体，包含 `id`、`conversationId`、`senderId`、`content`（TEXT）、`createdAt`，验证编译通过
- [ ] 1.4 创建 `entity/UserBlock.java` JPA 实体，包含 `id`、`blockerId`、`blockedId`、`createdAt`，添加 `(blockerId, blockedId)` 唯一约束，验证编译通过
- [ ] 1.5 创建对应 Repository 接口：`ConversationRepository`、`ConversationParticipantRepository`、`MessageRepository`、`UserBlockRepository`，验证编译通过

## 2. 后端 WebSocket 消息处理器

- [ ] 2.1 在现有 `WebSocketConfig.java` 中追加 `/ws/messages` 端点注册，验证 WebSocket 端点可访问
- [ ] 2.2 创建 `websocket/MessageWebSocketHandler.java`，复用 `user-notifications` 的连接管理模式（`ConcurrentHashMap<Long, WebSocketSession>`），实现消息端点的连接建立/关闭/错误处理，验证连接管理正确

## 3. 后端会话与消息 REST API

- [ ] 3.1 创建 `dto/request/CreateConversationRequest.java`（`otherUserId` 字段）和 `dto/request/SendMessageRequest.java`（`content` 字段，1-1000 字符），验证编译通过
- [ ] 3.2 创建 `dto/response/ConversationResponse.java`（conversationId, otherUserAvatar, otherUserNickname, lastMessageSnippet, lastMessageTime, unreadCount）、`dto/response/MessageResponse.java`（id, content, timestamp, isMine）、`dto/response/UnreadConversationCountResponse.java`（count）、`dto/response/UserSearchResultResponse.java`（id, nickname, avatarUrl），验证编译通过
- [ ] 3.3 创建 `service/ConversationService.java` 接口和 `impl/ConversationServiceImpl.java`，实现会话列表查询（按 `lastMessageAt` 倒序分页）、创建会话（`user1Id < user2Id` 排序 + 唯一性检查）、标记已读、未读计数，验证业务逻辑正确
- [ ] 3.4 创建 `service/MessageService.java` 接口和 `impl/MessageServiceImpl.java`，实现消息发送（持久化 + 更新 `lastMessageAt` + 增加对方 `unreadCount` + WebSocket 推送给接收方）、消息历史分页查询（正序，每页 50 条），验证业务逻辑正确
- [ ] 3.5 创建 `controller/ConversationController.java`，实现 `GET /api/conversations`、`POST /api/conversations`、`PUT /api/conversations/{id}/read`、`GET /api/conversations/unread-count` 端点，验证 API 响应正确
- [ ] 3.6 创建 `controller/MessageController.java`，实现 `POST /api/conversations/{id}/messages`、`GET /api/conversations/{id}/messages` 端点，验证 API 响应正确
- [ ] 3.7 实现消息发送校验：空消息 → 400、超长 → 400、被屏蔽 → 403、会话不存在/无权限 → 404，验证各校验场景正确
- [ ] 3.8 实现创建会话校验：自己对自己 → 400 "Cannot create conversation with yourself"，已有会话 → 返回已有会话 ID，验证校验正确
- [ ] 3.9 实现未登录访问保护（所有会话/消息 API 返回 401），验证未登录请求被拒绝

## 4. 后端用户搜索与屏蔽 API

- [ ] 4.1 创建 `service/UserBlockService.java` 接口和 `impl/UserBlockServiceImpl.java`，实现屏蔽/取消屏蔽/屏蔽列表查询/发送时屏蔽校验，验证业务逻辑正确
- [ ] 4.2 创建 `controller/UserBlockController.java`，实现 `POST /api/users/{id}/block`、`DELETE /api/users/{id}/block`、`GET /api/users/blocked` 端点，验证 API 响应正确
- [ ] 4.3 创建 `controller/UserSearchController.java`，实现 `GET /api/users/search?nickname={query}` 端点（≥2 字符、模糊匹配、排除自己、最多 10 条），验证搜索结果正确
- [ ] 4.4 实现搜索参数过短校验：< 2 字符 → 400 "Search query must be at least 2 characters"，验证校验正确

## 5. 后端频率限制与自动清理

- [ ] 5.1 创建频率限制拦截器（`HandlerInterceptor`），基于 `ConcurrentHashMap` 滑动窗口计数器（每用户每分钟最多 20 条消息），超限返回 HTTP 429 "Too many messages, please slow down"，验证限流逻辑正确
- [ ] 5.2 注册拦截器到 `WebMvcConfigurer`，仅拦截 `POST /api/conversations/*/messages` 路径，验证拦截器生效
- [ ] 5.3 创建消息自动清理定时任务（`@Scheduled` 每日执行），删除 `createdAt` 早于 30 天前的消息记录，验证清理逻辑正确

## 6. 前端 API 层、WebSocket Hook 与类型定义

- [ ] 6.1 创建 `frontend/src/types/message.ts`，定义 `Conversation`、`Message`、`ConversationListResponse`、`MessageListResponse`、`UnreadConversationCountResponse`、`UserSearchResult`、`WebSocketMessagePayload` 类型，验证 TypeScript 编译通过
- [ ] 6.2 创建 `frontend/src/api/messages.ts`，封装 `getConversations(page, size)`、`createConversation(otherUserId)`、`getMessages(conversationId, page, size)`、`sendMessage(conversationId, content)`、`markConversationRead(conversationId)`、`getUnreadConversationCount()`、`searchUsers(nickname)`、`blockUser(userId)`、`unblockUser(userId)`、`getBlockedUsers()` API 调用，验证 TypeScript 编译通过
- [ ] 6.3 创建 `frontend/src/lib/use-message-ws.ts` Hook，复用 `use-notification-ws.ts` 的连接管理模式，封装 `/ws/messages` 端点连接、消息接收回调、断线重连，验证 Hook 可正常建立连接

## 7. 前端 MessagesBell 组件

- [ ] 7.1 创建 `frontend/src/components/messages/messages-bell.tsx`，实现消息图标渲染（`lucide-react` `MessageCircle` 图标），未登录不渲染，验证组件可见
- [ ] 7.2 实现未读会话计数 badge（与 NotificationBell 样式一致），点击导航到 `/messages`，验证 badge 和跳转正确

## 8. 前端会话列表页（/messages）

- [ ] 8.1 创建 `frontend/src/app/messages/page.tsx`（Client Component），实现 loading 状态（5 行 Skeleton 占位），验证 loading 可见
- [ ] 8.2 实现 error 状态（错误提示 + Retry 按钮），验证错误状态正确
- [ ] 8.3 实现 empty 状态（MessageCircle 图标 + "No messages yet" + CTA 按钮），验证空状态正确
- [ ] 8.4 实现 data 状态：ConversationItem 列表，每条展示头像 + 昵称 + 消息片段（截断 40 字符）+ 时间 + 未读 badge，验证列表渲染正确
- [ ] 8.5 实现新建会话入口按钮，点击打开 NewConversationDialog，验证 Dialog 打开正确

## 9. 前端会话详情页（/messages/{conversationId}）

- [ ] 9.1 创建 `frontend/src/app/messages/[conversationId]/page.tsx`（Client Component），实现 loading / error / not-found / blocked-by-me / blocked-by-other / deleted-user / data 七个互斥状态，验证状态切换正确
- [ ] 9.2 实现 data 状态消息渲染：按时间正序、自己的消息靠右（`bg-primary text-primary-foreground`）、对方消息靠左（`bg-muted text-foreground`），验证消息布局正确
- [ ] 9.3 实现消息输入区域（`lucide-react` `Send` 按钮 + Enter 发送），验证输入和发送交互正确
- [ ] 9.4 实现消息乐观更新：发送后立即出现在列表底部（`opacity-60`）→ 服务端确认 → 正常样式 → 发送失败 → "Failed to send" + Retry 按钮，验证乐观更新流程
- [ ] 9.5 实现自动滚动：新消息到达且用户在底部 → 自动滚动到底部；用户在上方浏览 → 显示 "↓ New messages" 浮动按钮，验证滚动行为正确
- [ ] 9.6 实现 blocked-by-other 状态：消息历史只读展示 + 输入区域替换为 "You have been blocked by this user"，验证只读模式正确
- [ ] 9.7 实现 ConversationHeader 组件（顶部栏：对方头像 + 昵称 + 更多操作菜单），验证 Header 渲染正确

## 10. 前端新建会话 Dialog 与 Block User

- [ ] 10.1 创建 `frontend/src/components/messages/new-conversation-dialog.tsx`，实现搜索用户（≥2 字符 → 300ms debounce → 搜索 API → 结果列表最多 10 条），验证搜索交互正确
- [ ] 10.2 实现选择用户后 Dialog 关闭 + 路由导航到对应会话详情页，验证跳转正确
- [ ] 10.3 实现响应式：Mobile（< 768px）底部 Sheet 形式、Desktop（≥ 768px）居中弹窗（`w-[400px]`），验证两种形态正确
- [ ] 10.4 创建 Block User 确认 Dialog（二次确认），确认 Block → 调用屏蔽 API → 成功 → 会话从列表消失 + toast "User blocked"；失败 → Dialog 保持 + toast "Failed to block user"，验证屏蔽流程正确

## 11. 集成与验证

- [ ] 11.1 修改 `frontend/src/components/layout/header.tsx`，集成 `MessagesBell` 组件（右侧，需登录后显示），验证 Header 中消息图标可见
- [ ] 11.2 运行 `npm run build` 验证前端构建通过，无 TypeScript 编译错误
- [ ] 11.3 运行 `mvn spring-boot:run` 验证后端启动成功，WebSocket 端点和 REST API 可访问
- [ ] 11.4 在浏览器中验证完整流程：会话列表四状态、会话详情七状态、消息收发 + 乐观更新、新建会话 Dialog、用户搜索、屏蔽/取消屏蔽、频率限制、MessagesBell badge、WebSocket 实时推送、30 天清理（构建通过，待浏览器手动验证）
