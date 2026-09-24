# 消息通知（Notifications）PRD

## 1. 背景与目标

当用户的内容（帖子、评论、目的地收藏等）获得其他用户的互动时，系统需要及时通知该用户。消息通知是用户回流的核心驱动力——它告诉用户"有人关注了你"，是社区活跃度的关键指标。

**目标**：通过实时推送让用户及时收到互动通知，区分已读/未读状态，点击通知跳转到对应帖子详情页查看互动上下文。

## 2. 目标用户与场景

| 用户角色 | 场景 |
|---------|------|
| 内容发布者 | 帖子被点赞后收到实时通知，查看是谁点赞 |
| 被评论者 | 评论被回复后收到通知，查看评论内容 |
| 活跃用户 | 累积多条未读通知，希望批量标记已读 |
| 低频用户 | 长时间未登录后，希望快速了解错过的互动（14 天内） |

## 3. 已确认决策

| 决策项 | 结论 |
|--------|------|
| 推送方式 | **WebSocket 实时推送** |
| 通知聚合 | **不聚合**，每条互动独立展示 |
| 数据保留时长 | **14 天**，超过 14 天的通知自动清理 |
| 点击通知行为 | **跳转到对应帖子详情页**，同时标记已读 |
| 认证机制 | 假设已有登录功能 |

## 4. 用户故事

### US-2.1 查看通知列表

```
As a logged-in user,
I want to see a list of system notifications about interactions with my content,
So that I know who engaged with me and what happened.

Acceptance Criteria:
- Given I am logged in, When I open the notification panel, Then I see a chronological list (newest first) of notifications
- Given I have notifications, When the list renders, Then each notification shows: notification type icon, actor avatar + nickname, action description (e.g., "liked your post"), target content snippet, and relative timestamp (e.g., "2h ago")
- Given I have no notifications, When I open the panel, Then I see an empty state: "No notifications yet"
```

### US-2.2 未读标记与未读计数

```
As a logged-in user,
I want to see which notifications are unread and how many unread notifications I have,
So that I can prioritize catching up on new interactions.

Acceptance Criteria:
- Given I have unread notifications, When I view the notification icon in the header, Then a badge shows the count of unread notifications (capped at "99+")
- Given I open the notification panel, When a new notification arrives via WebSocket while the panel is open, Then it appears at the top of the list with an "unread" visual indicator (bold text + colored dot)
- Given I click on an unread notification, When it is clicked, Then that notification is marked as read, the badge count decreases by 1, and I am navigated to the corresponding post detail page
```

### US-2.3 批量标记已读

```
As a logged-in user with multiple unread notifications,
I want to mark all notifications as read at once,
So that I can clear the unread badge without clicking each one.

Acceptance Criteria:
- Given I have 1 or more unread notifications, When I click "Mark all as read", Then all notifications become read and the badge count becomes 0
- Given I have 0 unread notifications, When I view the panel, Then the "Mark all as read" button is disabled/hidden
```

### US-2.4 通知类型支持

```
As a logged-in user,
I want to receive notifications for different types of interactions,
So that I can distinguish between likes, comments, and other actions.

Acceptance Criteria:
- Given someone likes my post, When the notification is generated, Then it shows: [heart icon] "{actor} liked your post '{post title snippet}'"
- Given someone comments on my post, When the notification is generated, Then it shows: [comment icon] "{actor} commented on your post: '{comment snippet}'"
- Given someone replies to my comment, When the notification is generated, Then it shows: [reply icon] "{actor} replied to your comment: '{reply snippet}'"
```

### US-2.5 通知点击跳转（帖子详情页）

```
As a logged-in user,
I want to click a notification and be taken to the relevant post detail page,
So that I can see the interaction in context.

Acceptance Criteria:
- Given I click any notification, When it is clicked, Then I am navigated to the corresponding post detail page and the notification is marked as read
- Given I click a notification, When the post detail page loads, Then the badge count decreases by 1 and the unread visual indicator is removed
- Given the original post has been deleted, When I click the notification, Then I see a toast message "This content is no longer available" and the notification is still marked as read, but no navigation occurs
```

### US-2.6 通知分页与加载

```
As a logged-in user with many notifications,
I want to load older notifications as I scroll,
So that the page remains responsive even with many notifications.

Acceptance Criteria:
- Given I have more than 20 notifications, When I open the panel, Then the first 20 are shown with a "Load more" option at the bottom
- Given I click "Load more", When the next page loads, Then 20 more notifications are appended to the list
- Given I have reached the end of all notifications, When I try to load more, Then the message "No more notifications" is shown
```

### US-2.7 实时推送接收

```
As a logged-in user,
I want to receive notifications in real time without refreshing the page,
So that I never miss an interaction.

Acceptance Criteria:
- Given I am on any page of the application, When someone interacts with my content, Then the notification badge count increases within 3 seconds
- Given the WebSocket connection is lost, When it reconnects, Then any missed notifications during the disconnection period are fetched and displayed
- Given I am not logged in, When I browse the site, Then no WebSocket connection is established
```

## 5. 边界清单

| 编号 | 边界场景 | 处理方式 |
|------|---------|---------|
| B-2.1 | 用户删除了被点赞/评论的内容 | 相关通知保留但标记为 "content removed"，点击后提示 "This content is no longer available"，不跳转 |
| B-2.2 | 点赞后立即取消点赞 | 如果通知尚未被查看（未读），则删除该通知；如果已读，保留不删除 |
| B-2.3 | 同一用户对同一内容重复点赞/取消 | 只生成一条通知，不重复推送 |
| B-2.4 | 自己给自己内容评论 | 不生成通知 |
| B-2.5 | 通知中的用户已被封禁/删除 | 通知保留，actor 显示为 "Deleted user"，不可点击 |
| B-2.6 | 超过 14 天的通知 | 自动清理，不再展示。用户无法查看 14 天前的历史通知 |
| B-2.7 | 时间戳的时区处理 | 使用相对时间（"2h ago", "3d ago"），避免时区困扰 |
| B-2.8 | WebSocket 断线重连 | 自动重连（指数退避，最大间隔 30s），重连后拉取断线期间的未读通知 |
| B-2.9 | 通知内容中包含被删除的评论 | 通知保留，内容 snippet 显示 "[deleted]"，点击后跳转到帖子详情页顶部 |

## 6. 验收标准汇总

- [ ] 登录用户在任意页面，互动发生后 3 秒内收到实时通知
- [ ] 通知列表按时间倒序展示，每条包含类型图标、actor 头像+昵称、动作描述、内容片段、相对时间
- [ ] 未登录用户不建立 WebSocket 连接
- [ ] 通知图标 badge 显示未读数量，上限 "99+"
- [ ] 点击通知跳转到对应帖子详情页，同时标记已读，badge 数量减 1
- [ ] "Mark all as read" 一键清除所有未读状态
- [ ] 支持三种通知类型：点赞、评论、回复，各自展示对应图标和文案
- [ ] 已删除内容的通知显示 "content removed"，点击提示 "This content is no longer available"，不跳转
- [ ] 通知列表分页，每页 20 条，支持 "Load more"
- [ ] 超过 14 天的通知自动清理
- [ ] WebSocket 断线后自动重连，重连后补发断线期间未读通知
- [ ] 自己对自己的内容互动不生成通知
- [ ] 同一用户对同一内容重复点赞只生成一条通知
