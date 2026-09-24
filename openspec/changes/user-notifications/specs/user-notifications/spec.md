## Purpose

为 ChinaBuddy 实现消息通知系统——当用户的内容（帖子、评论等）被其他用户互动（点赞、评论、回复）时，通过 WebSocket 实时推送通知，前端在 Header 铃铛组件中展示通知列表，支持已读/未读管理、分页加载、点击跳转到帖子详情页。

## ADDED Requirements

### Requirement: 通知数据模型
系统 SHALL 提供 `Notification` JPA 实体，包含以下字段：`id`（Long）、`userId`（Long，通知接收者）、`actorId`（Long，操作者）、`type`（枚举：LIKE/COMMENT/REPLY）、`targetType`（String，目标类型）、`targetId`（Long，目标 ID）、`contentSnippet`（String，内容片段）、`isRead`（Boolean，默认 false）、`createdAt`（LocalDateTime）。

#### Scenario: 通知记录创建
- **WHEN** 系统生成一条新通知
- **THEN** 通知 SHALL 记录操作者 ID、接收者 ID、通知类型、目标内容信息、内容片段
- **AND** `isRead` SHALL 默认为 `false`
- **AND** `createdAt` SHALL 为当前服务器时间

### Requirement: 通知生成
系统 SHALL 在以下业务操作时自动生成通知记录：点赞（LIKE）、评论（COMMENT）、回复（REPLY）。通知生成 SHALL 与业务操作在同一事务中。

#### Scenario: 点赞通知生成
- **WHEN** 用户 A 点赞用户 B 的帖子
- **AND** 用户 A 不是用户 B（非自己点赞自己）
- **THEN** 系统 SHALL 为用户 B 创建一条 LIKE 类型通知，`contentSnippet` 为帖子标题截断

#### Scenario: 评论通知生成
- **WHEN** 用户 A 评论用户 B 的帖子
- **AND** 用户 A 不是帖子所有者
- **THEN** 系统 SHALL 为用户 B 创建一条 COMMENT 类型通知，`contentSnippet` 为评论内容截断

#### Scenario: 回复通知生成
- **WHEN** 用户 A 回复用户 B 的评论
- **AND** 用户 A 不是评论所有者
- **THEN** 系统 SHALL 为用户 B 创建一条 REPLY 类型通知，`contentSnippet` 为回复内容截断

#### Scenario: 重复点赞不重复通知
- **WHEN** 用户 A 对用户 B 的同一帖子点赞后取消，再次点赞
- **AND** 之前的通知尚未被查看（未读）
- **THEN** 系统 SHALL 删除之前的未读通知，生成新的通知（不重复推送）

#### Scenario: 已读通知不被取消点赞删除
- **WHEN** 用户 A 取消点赞用户 B 的帖子
- **AND** 对应的通知已被用户 B 查看（已读）
- **THEN** 系统 SHALL 保留该通知不删除

### Requirement: 通知列表 API
系统 SHALL 提供 `GET /api/notifications` 端点，分页返回当前用户的通知列表（按时间倒序）。

#### Scenario: 获取通知列表
- **WHEN** 登录用户请求 `GET /api/notifications?page=0&size=20`
- **THEN** 系统 SHALL 返回 HTTP 200，`data` 包含通知列表（最多 20 条）和分页信息（`hasMore`、`totalElements`）
- **AND** 每条通知 SHALL 包含 `id`、`type`、`actorAvatar`、`actorNickname`、`actionText`、`contentSnippet`、`timestamp`、`isRead`、`isContentDeleted`

#### Scenario: 通知按时间倒序
- **WHEN** 用户有多条通知
- **THEN** 通知 SHALL 按 `createdAt` 倒序排列（最新在前）

#### Scenario: 未登录访问
- **WHEN** 未登录用户请求通知列表
- **THEN** 系统 SHALL 返回 HTTP 401

### Requirement: 标记通知已读 API
系统 SHALL 提供 `PUT /api/notifications/{id}/read` 端点，标记单条通知为已读。

#### Scenario: 成功标记已读
- **WHEN** 登录用户请求 `PUT /api/notifications/{id}/read`
- **AND** 该通知属于当前用户
- **THEN** 系统 SHALL 将该通知的 `isRead` 设为 `true` 并返回 HTTP 200

#### Scenario: 通知不属于当前用户
- **WHEN** 用户尝试标记不属于自己的通知
- **THEN** 系统 SHALL 返回 HTTP 403

#### Scenario: 通知不存在
- **WHEN** 用户尝试标记不存在的通知 ID
- **THEN** 系统 SHALL 返回 HTTP 404

### Requirement: 批量标记已读 API
系统 SHALL 提供 `PUT /api/notifications/read-all` 端点，将当前用户所有未读通知标记为已读。

#### Scenario: 成功批量标记
- **WHEN** 登录用户请求 `PUT /api/notifications/read-all`
- **THEN** 系统 SHALL 将所有当前用户的未读通知标记为已读并返回 HTTP 200

### Requirement: 未读计数 API
系统 SHALL 提供 `GET /api/notifications/unread-count` 端点，返回当前用户的未读通知数量。

#### Scenario: 获取未读计数
- **WHEN** 登录用户请求 `GET /api/notifications/unread-count`
- **THEN** 系统 SHALL 返回 HTTP 200，`data` 包含 `count`（未读通知数量）

### Requirement: WebSocket 实时推送
系统 SHALL 通过 WebSocket 端点 `/ws/notifications` 实时推送新通知到前端。连接通过 URL 参数 `token` 进行身份验证。

#### Scenario: WebSocket 连接建立
- **WHEN** 登录用户的前端发起 WebSocket 连接到 `/ws/notifications?token={jwt}`
- **THEN** 系统 SHALL 验证 Token，建立连接，并将 session 存储在用户连接映射中

#### Scenario: 新通知实时推送
- **WHEN** 系统为用户生成一条新通知
- **AND** 该用户有活跃的 WebSocket 连接
- **THEN** 系统 SHALL 通过 WebSocket 推送通知数据（JSON 格式）到前端
- **AND** 推送 SHALL 在通知生成后 1 秒内完成

#### Scenario: 未登录不建立连接
- **WHEN** 未登录用户的前端尝试建立 WebSocket 连接
- **THEN** 系统 SHALL 拒绝连接

#### Scenario: WebSocket 断开
- **WHEN** 用户的 WebSocket 连接断开（网络中断、页面关闭）
- **THEN** 系统 SHALL 从连接映射中移除该 session

### Requirement: 通知自动清理
系统 SHALL 通过定时任务自动清理超过 14 天的通知记录。

#### Scenario: 定时清理执行
- **WHEN** 定时任务触发（每日执行）
- **THEN** 系统 SHALL 删除所有 `createdAt` 早于 14 天前的通知记录

### Requirement: 前端 NotificationBell 组件
Header 右侧 SHALL 渲染 `NotificationBell` 组件，展示未读通知计数 badge，点击展开通知面板。

#### Scenario: 未登录不渲染
- **WHEN** 用户未登录
- **THEN** NotificationBell SHALL NOT 渲染

#### Scenario: 零未读
- **WHEN** 用户已登录且 `unreadCount === 0`
- **THEN** 铃铛图标 SHALL 显示（`text-muted-foreground`），无 badge

#### Scenario: 有未读（1-99）
- **WHEN** `unreadCount` 为 1-99
- **THEN** 铃铛图标右上角 SHALL 显示红色 badge（`bg-primary`），内容为数字

#### Scenario: 未读溢出（> 99）
- **WHEN** `unreadCount > 99`
- **THEN** badge SHALL 显示 "99+"

#### Scenario: 点击铃铛
- **WHEN** 用户点击铃铛
- **THEN** NotificationPanel SHALL toggle 展开/收起

#### Scenario: 新通知到达（面板关闭）
- **WHEN** WebSocket 推送新通知且面板处于关闭状态
- **THEN** badge 数字 SHALL +1 并触发弹跳动画（`scale-110 → scale-100`，200ms）

### Requirement: 前端 NotificationPanel 组件
NotificationPanel SHALL 作为 Popover 下拉面板从铃铛处展开，展示通知列表。面板需覆盖 connecting / loading / error / empty / data 五个互斥状态。

#### Scenario: loading 状态
- **WHEN** 首次拉取通知列表 API 请求中
- **THEN** 面板 SHALL 显示 5 行 Skeleton 占位

#### Scenario: error 状态
- **WHEN** 首次拉取通知列表失败
- **THEN** 面板 SHALL 显示 AlertCircle 图标 + "Something went wrong" + "Could not load notifications" + Retry 按钮

#### Scenario: empty 状态
- **WHEN** 通知列表成功返回但数据为空
- **THEN** 面板 SHALL 显示 Bell 图标（`opacity-30`）+ "No notifications yet" + 副文案

#### Scenario: data 状态
- **WHEN** 通知列表有数据
- **THEN** 面板 SHALL 渲染 NotificationItem 列表 + PanelHeader（标题 + "Mark all as read"）+ LoadMoreTrigger

#### Scenario: 面板尺寸
- **WHEN** 面板展开
- **THEN** Desktop SHALL 为 `w-[360px]`，Mobile SHALL 为 `w-[calc(100vw-32px)] max-w-[360px]`
- **AND** 最大高度 `max-h-[480px]`，超出后列表区域 `overflow-y-auto`

#### Scenario: Escape 关闭
- **WHEN** 面板展开时用户按 Escape
- **THEN** 面板 SHALL 收起，焦点回到铃铛按钮

### Requirement: 前端 NotificationItem 组件
每条通知 SHALL 渲染为 NotificationItem，展示类型图标、操作者头像+昵称、动作描述、内容片段、时间戳。

#### Scenario: 未读通知视觉
- **WHEN** 通知 `isRead === false`
- **THEN** 左侧 SHALL 显示蓝色圆点（`bg-primary`）
- **AND** 文字 SHALL 为 `font-semibold`
- **AND** 背景 SHALL 为 `bg-primary/5`

#### Scenario: 已读通知视觉
- **WHEN** 通知 `isRead === true`
- **THEN** 无蓝色圆点，文字 `font-normal`，背景 `transparent`

#### Scenario: 点击通知（内容存在）
- **WHEN** 用户点击一条通知且原始内容存在
- **THEN** 系统 SHALL 调用 `markAsRead` API
- **AND** 面板 SHALL 关闭
- **AND** 路由 SHALL 跳转到 `/posts/{postId}`
- **AND** badge 数量 SHALL -1

#### Scenario: 点击通知（内容已删除）
- **WHEN** 用户点击一条通知且原始内容已被删除（`isContentDeleted === true`）
- **THEN** 系统 SHALL 调用 `markAsRead` API
- **AND** 显示 toast "This content is no longer available"（3s 自动消失）
- **AND** 不进行路由跳转，面板保持打开
- **AND** badge 数量 SHALL -1

### Requirement: Mark all as read
NotificationPanel 的 PanelHeader SHALL 包含 "Mark all as read" 按钮，仅在有未读通知时显示。

#### Scenario: 点击 Mark all as read 成功
- **WHEN** 用户点击 "Mark all as read" 且 API 成功
- **THEN** 所有通知 SHALL 变为已读样式
- **AND** badge SHALL 归零
- **AND** 按钮 SHALL 隐藏
- **AND** 显示 toast "All notifications marked as read"（3s）

#### Scenario: Mark all as read 失败
- **WHEN** API 调用失败
- **THEN** 按钮 SHALL 恢复可点击
- **AND** 显示 toast "Failed to mark all as read"（手动关闭）

### Requirement: 通知分页
通知列表 SHALL 支持分页加载，每页 20 条。

#### Scenario: Load more 显示
- **WHEN** 通知总数 > 20 且还有更多
- **THEN** 列表底部 SHALL 显示 "Load more" 按钮

#### Scenario: Load more 加载
- **WHEN** 用户点击 "Load more"
- **THEN** 按钮 SHALL 变为 spinner + "Loading..."，disabled
- **AND** 加载成功后追加 20 条通知到列表

#### Scenario: 到达末尾
- **WHEN** 所有通知已加载完毕
- **THEN** SHALL 显示 "No more notifications"（`text-xs text-muted-foreground`）

### Requirement: WebSocket 断线重连
前端 SHALL 在 WebSocket 断线后自动重连，使用指数退避策略。

#### Scenario: 断线自动重连
- **WHEN** WebSocket 连接断开
- **THEN** 前端 SHALL 自动尝试重连（初始 1s，每次翻倍，最大 30s）
- **AND** 面板底部 SHALL 显示 "Reconnecting..." 提示条

#### Scenario: 重连成功
- **WHEN** WebSocket 重连成功
- **THEN** 前端 SHALL 通过 REST API 拉取断线期间的未读通知
- **AND** 提示条 SHALL 消失
- **AND** 新通知 SHALL 插入列表顶部

#### Scenario: 重连失败超过 3 次
- **WHEN** 重连尝试超过 3 次
- **THEN** 前端 SHALL 停止重连
- **AND** 提示条 SHALL 变为 "Connection lost. [Refresh]"
