# 站内信（Direct Messages）PRD

## 1. 背景与目标

站内信让用户之间可以一对一私信沟通。对于旅行平台而言，用户可能想向去过的旅行者请教经验、协调结伴出行、或询问目的地细节。站内信是社区深度互动的载体，将 ChinaBuddy 从"内容消费平台"升级为"旅行者社交平台"。

**目标**：让用户能够发起和参与一对一私信对话，查看会话列表和历史消息，通过 WebSocket 实现实时收发消息。

## 2. 目标用户与场景

| 用户角色 | 场景 |
|---------|------|
| 旅行者 A | 看到用户 B 发布了某城市的攻略，想私信请教具体路线建议 |
| 结伴旅行者 | 与潜在旅伴沟通行程细节和出发时间 |
| 活跃社区成员 | 收到多条私信，需要管理多个会话 |
| 被骚扰用户 | 收到不当消息，需要屏蔽对方 |

## 3. 已确认决策

| 决策项 | 结论 |
|--------|------|
| 推送方式 | **WebSocket 实时推送** |
| 被屏蔽方提示 | **明确提示发送方已被屏蔽**（发送方看到 "You have been blocked by this user"） |
| 已读回执 | **不需要**（本期不实现消息已读/未读回执） |
| 图片/文件发送 | **不支持**（本期仅支持纯文本消息） |
| 消息保留时长 | **30 天**，超过 30 天的消息自动清理 |
| 群组消息 | **不支持**（本期仅支持一对一私信） |
| 认证机制 | 假设已有登录功能 |

## 4. 用户故事

### US-3.1 查看会话列表

```
As a logged-in user,
I want to see a list of my conversations with other users,
So that I can quickly find and continue any ongoing chat.

Acceptance Criteria:
- Given I am logged in, When I navigate to /messages, Then I see a list of conversations sorted by last message time (newest first)
- Given I have conversations, When the list renders, Then each conversation shows: other user's avatar + nickname, last message snippet (truncated to 40 chars), relative timestamp, and unread count badge
- Given I have no conversations, When I view the page, Then I see an empty state: "No messages yet. Start a conversation!"
- Given a conversation has unread messages, When the list renders, Then that conversation shows an unread badge with the count
```

### US-3.2 查看消息历史

```
As a logged-in user in a conversation,
I want to see the full message history with another user,
So that I can review our past conversation.

Acceptance Criteria:
- Given I click on a conversation, When it opens, Then I see messages in chronological order (oldest at top, newest at bottom), with my messages aligned right and the other user's messages aligned left
- Given each message, When it renders, Then it shows the message text content and send timestamp
- Given the conversation has more than 50 messages, When I scroll to the top, Then older messages are loaded on demand via a "Load earlier messages" button
- Given messages are older than 30 days, When I try to load them, Then they are no longer available and a message "Earlier messages are no longer available" is shown
```

### US-3.3 发送文字消息

```
As a logged-in user in a conversation,
I want to send a text message to the other user,
So that I can communicate with them.

Acceptance Criteria:
- Given I am in a conversation, When I type a message (1-1000 characters) and press Enter or click Send, Then the message appears in the conversation immediately (optimistic update) and is delivered to the recipient via WebSocket
- Given I type a message exceeding 1000 characters, When I try to send, Then I see a validation error "Message must be 1000 characters or less"
- Given I type a message with only whitespace, When I try to send, Then the Send button is disabled
- Given I press Shift+Enter, When I am typing, Then a line break is inserted instead of sending
- Given a message fails to send (network error), When the failure occurs, Then the message is marked with a "Failed to send" indicator and a retry button is shown
```

### US-3.4 发起新会话

```
As a logged-in user,
I want to start a new conversation with another user,
So that I can send them a private message.

Acceptance Criteria:
- Given I am on /messages, When I click "New message", Then I see a user search input where I can type a nickname to find and select a user
- Given I select a user I already have a conversation with, When I confirm, Then the existing conversation opens (no duplicate created)
- Given I select a user I have no conversation with, When I confirm, Then a new conversation is created and opens with an empty message area
- Given I search for a user, When I type at least 2 characters, Then matching users are shown (by nickname, max 10 results)
```

### US-3.5 会话未读状态

```
As a logged-in user,
I want to see which conversations have unread messages,
So that I can prioritize responding to new messages.

Acceptance Criteria:
- Given I receive a new message in a conversation I'm not currently viewing, When I check the conversation list, Then that conversation shows an unread badge
- Given I open a conversation, When I view it, Then all messages in that conversation are marked as read
- Given I have any unread conversations, When I view the messages icon in the header, Then a badge shows the total unread conversation count
```

### US-3.6 屏蔽用户

```
As a logged-in user,
I want to block another user from sending me messages,
So that I can prevent unwanted contact.

Acceptance Criteria:
- Given I am in a conversation, When I click "Block user" from the conversation menu, Then I see a confirmation dialog "Block {nickname}? They will no longer be able to send you messages."
- Given I confirm blocking, When the action completes, Then the conversation is closed and the blocked user disappears from my conversation list
- Given a blocked user tries to send me a message, When they attempt to send, Then they see an explicit error message "You have been blocked by this user" and the message is not delivered
- Given I have blocked a user, When I view my block list (in settings), Then I can see the blocked user and unblock them
```

### US-3.7 实时消息收发

```
As a logged-in user,
I want to receive messages in real time without refreshing the page,
So that I can have a fluid conversation experience.

Acceptance Criteria:
- Given I am in a conversation view, When the other user sends a message, Then the message appears in the conversation within 3 seconds without page refresh
- Given I am on the conversation list, When a new message arrives, Then the conversation list updates (last message snippet, timestamp, unread count) within 3 seconds
- Given the WebSocket connection is lost, When it reconnects, Then any missed messages during the disconnection period are fetched and displayed
- Given I am not logged in, When I browse the site, Then no WebSocket connection is established
```

## 5. 边界清单

| 编号 | 边界场景 | 处理方式 |
|------|---------|---------|
| B-3.1 | 消息发送失败（网络中断） | 消息标记为 "Failed to send"，提供重试按钮 |
| B-3.2 | 向已删除用户发送消息 | 会话保留但标记为 "Deleted user"，不可发送新消息，显示 "This user no longer exists" |
| B-3.3 | 消息中包含 HTML/脚本 | 所有消息内容做 XSS 过滤，纯文本渲染（本期不支持富文本/Markdown） |
| B-3.4 | 用户给自己发消息 | 不允许，搜索用户时不显示自己 |
| B-3.5 | 短时间内发送大量消息（刷屏） | 频率限制：每用户每分钟最多发送 20 条消息，超出后提示 "Too many messages, please slow down" |
| B-3.6 | 消息中的换行符 | 支持换行（Shift+Enter 换行，Enter 发送），消息内换行渲染为换行 |
| B-3.7 | 会话列表分页 | 会话列表按最近消息时间排序，首次加载 20 个会话，滚动加载更多 |
| B-3.8 | 超过 30 天的消息 | 自动清理，不再展示。会话列表保留（基于最近一条未过期消息的时间排序），过期会话从列表中移除 |
| B-3.9 | 对方已屏蔽我时的体验 | 发送消息时明确提示 "You have been blocked by this user"，不暴露屏蔽者的其他信息 |
| B-3.10 | 同时打开多个会话标签页 | 未读计数在所有标签页同步（通过 WebSocket），消息只在一个标签页标记已读即可 |

## 6. 验收标准汇总

- [ ] 登录用户可访问 `/messages` 查看会话列表，按最近消息时间倒序
- [ ] 每条会话展示：对方头像+昵称、最后消息片段（截断 40 字符）、相对时间、未读计数
- [ ] 无会话时展示空状态 "No messages yet. Start a conversation!"
- [ ] 消息历史按时间正序展示，自己的消息靠右，对方消息靠左
- [ ] 消息历史支持向上加载更早消息（每次 50 条）
- [ ] 超过 30 天的消息不可查看
- [ ] 发送消息支持 1-1000 字符纯文本，Enter 发送，Shift+Enter 换行
- [ ] 纯空白消息不可发送（Send 按钮禁用）
- [ ] 消息发送失败时显示 "Failed to send" 标记和重试按钮
- [ ] 可通过搜索昵称（≥2 字符）发起新会话，已有会话不重复创建
- [ ] 打开会话时该会话所有消息标记为已读
- [ ] Header 消息图标 badge 显示总未读会话数
- [ ] 屏蔽用户后对方发送消息时看到 "You have been blocked by this user"
- [ ] 屏蔽用户从自己的会话列表中消失，可在设置中查看和解除屏蔽
- [ ] 实时收发消息，延迟 ≤ 3 秒（WebSocket）
- [ ] WebSocket 断线自动重连，补发断线期间消息
- [ ] 未登录用户不建立 WebSocket 连接
- [ ] 频率限制：每用户每分钟最多 20 条消息
- [ ] 不支持图片/文件发送
- [ ] 不支持群组消息
- [ ] 不支持消息已读回执
