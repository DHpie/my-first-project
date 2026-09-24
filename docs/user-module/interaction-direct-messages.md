# 站内信（Direct Messages）交互规格

## 1. 组件架构总览

```
/messages（会话列表页）
  └── MessagesPage                        ← 页面容器（Client Component）
        ├── MessagesHeader                ← 页面标题 + "New message" 按钮
        ├── ConversationList              ← 会话列表
        │     └── ConversationItem × N    ← 单个会话行
        ├── LoadMoreConversations         ← 会话列表分页
        └── (状态层) Loading / Error / Empty

/messages?new=true（新建会话浮层）
  └── NewConversationDialog              ← 搜索用户 + 发起会话

/messages/:conversationId（会话详情页）
  └── ConversationPage                    ← 页面容器（Client Component）
        ├── ConversationHeader            ← 对方头像+昵称 + 更多操作菜单
        │     └── ConversationMenu        ← 下拉菜单（Block user）
        ├── MessageList                   ← 消息列表
        │     ├── LoadEarlierTrigger      ← 加载更早消息
        │     └── MessageBubble × N       ← 单条消息气泡
        ├── MessageInput                  ← 消息输入框 + Send 按钮
        └── (状态层) Loading / Error / Empty / Blocked / Deleted

Header（全局）
  └── MessagesBell                        ← 消息图标 + 未读 badge
```

| 组件 | 文件路径 | 类型 |
|------|---------|------|
| `MessagesPage` | `app/messages/page.tsx` | Client Component |
| `ConversationPage` | `app/messages/[conversationId]/page.tsx` | Client Component |
| `ConversationList` | `components/messages/conversation-list.tsx` | Client Component |
| `ConversationItem` | `components/messages/conversation-item.tsx` | Client Component |
| `MessageList` | `components/messages/message-list.tsx` | Client Component |
| `MessageBubble` | `components/messages/message-bubble.tsx` | Client Component |
| `MessageInput` | `components/messages/message-input.tsx` | Client Component |
| `NewConversationDialog` | `components/messages/new-conversation-dialog.tsx` | Client Component |
| `MessagesBell` | `components/messages/messages-bell.tsx` | Client Component |

---

## 2. MessagesBell（Header 消息图标）

### 2.1 用途

常驻 Header 右侧的消息图标，展示未读会话计数 badge，点击跳转到 `/messages`。

### 2.2 Props 定义

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `unreadCount` | `number` | 是 | — | 未读会话总数 |

### 2.3 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **hidden** | 用户未登录 | 图标不渲染 |
| **idle** | `unreadCount === 0` | `lucide-react` 的 `MessageCircle` 图标，`text-muted-foreground`，无 badge |
| **has-unread** | `unreadCount > 0 && unreadCount <= 99` | 图标右上角红色 badge 显示数字 |
| **overflow** | `unreadCount > 99` | badge 显示 "99+" |
| **hover** | 鼠标悬浮 | `text-foreground`，`transition-colors duration-200` |
| **realtime-pulse** | WebSocket 推送新消息 | badge 弹跳 `scale-110 → scale-100`（200ms） |

### 2.4 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击图标 | 导航到 `/messages` |
| 新消息到达（WebSocket） | badge +1 + 弹跳动画 |

### 2.5 Badge 视觉规格

与 NotificationBell 保持一致：
- `bg-primary text-primary-foreground text-[10px] font-bold`
- `min-w-[18px] h-[18px] rounded-full ring-2 ring-background`
- `absolute -top-1.5 -right-1.5`

---

## 3. MessagesPage（会话列表页）

### 3.1 进入条件

- 路由：`/messages`
- 守卫：需要登录，未登录重定向到登录页

### 3.2 页面状态全表

页面存在 **4 个互斥状态**，按优先级从高到低：

| 状态名 | 触发条件 | 视觉表现 |
|--------|---------|---------|
| **loading** | 首次拉取会话列表 | 全面板 Skeleton 占位 |
| **error** | 首次拉取失败 | 错误提示 + Retry 按钮 |
| **empty** | 列表成功返回但无会话 | 空状态插图 + 文案 + CTA |
| **data** | 有会话数据 | 正常渲染会话列表 |

### 3.3 各状态详细视觉表现

#### 3.3.1 loading 状态

```
┌─────────────────────────────────────────────┐
│  Messages                        [New msg]  │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ [Avatar○] [████████]        [██]  [●3] │ │  ← Skeleton 行 1
│ │           [████████████████]             │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ [Avatar○] [██████]          [██]       │ │  ← Skeleton 行 2
│ │           [██████████████]              │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ [Avatar○] [██████████]       [██]      │ │  ← Skeleton 行 3
│ │           [████████████████████]        │ │
│ └─────────────────────────────────────────┘ │
│         ... (共 5 行 Skeleton)               │
└─────────────────────────────────────────────┘
```

- 5 行 Skeleton，每行高度 72px，`gap-0`（行间 border 分隔）
- 每行结构：左侧圆形 Avatar Skeleton（40×40）+ 右侧两行文字 Skeleton（昵称 + 消息片段）+ 右侧时间戳 Skeleton + 可选 badge Skeleton

#### 3.3.2 error 状态

```
┌─────────────────────────────────────────────┐
│  Messages                        [New msg]  │
├─────────────────────────────────────────────┤
│                                             │
│          ⚠️ (AlertCircle, 48×48)            │
│          text-muted-foreground              │
│                                             │
│        "Something went wrong"               │
│     "Could not load your messages"          │
│                                             │
│            [ Retry ]                        │
│                                             │
└─────────────────────────────────────────────┘
```

- Retry 按钮：`variant="outline"`，点击后进入 loading 状态
- Retry 中：按钮 spinner + disabled

#### 3.3.3 empty 状态

```
┌─────────────────────────────────────────────┐
│  Messages                        [New msg]  │
├─────────────────────────────────────────────┤
│                                             │
│       💬 (MessageCircle, 48×48)             │
│        opacity-30 text-muted-foreground     │
│                                             │
│       "No messages yet"                     │
│  "Start a conversation with someone!"       │
│                                             │
│         [ Start a conversation ]            │  ← variant="default"
│                                             │
└─────────────────────────────────────────────┘
```

- 图标：`lucide-react` 的 `MessageCircle`，48×48，`text-muted-foreground opacity-30`
- 主文案：`text-sm font-medium text-foreground`
- 副文案：`text-xs text-muted-foreground text-center max-w-[220px]`
- CTA 按钮：`variant="default"`，点击打开 NewConversationDialog

#### 3.3.4 data 状态

```
┌─────────────────────────────────────────────┐
│  Messages                        [New msg]  │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ [Avatar] Alice              2h    [●3] │ │  ← 有未读
│ │          liked your guide about...      │ │
│ ├─────────────────────────────────────────┤ │
│ │ [Avatar] Bob                  5h        │ │  ← 已读
│ │          Thanks for the tips!           │ │
│ ├─────────────────────────────────────────┤ │
│ │ [Avatar] Carol               1d   [●1] │ │  ← 有未读
│ │          See you in Beijing!            │ │
│ ├─────────────────────────────────────────┤ │
│ │            [ Load more ]                │ │  ← LoadMoreConversations
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 3.4 ConversationItem 组件

#### Props 定义

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `conversationId` | `string` | 是 | — | 会话 ID |
| `otherUserAvatar` | `string \| null` | 是 | — | 对方头像 URL |
| `otherUserNickname` | `string` | 是 | — | 对方昵称 |
| `lastMessageSnippet` | `string` | 是 | — | 最后一条消息片段（截断 40 字符） |
| `lastMessageTime` | `string` (ISO 8601) | 是 | — | 最后消息时间 |
| `unreadCount` | `number` | 是 | — | 未读消息数 |
| `isActive` | `boolean` | 否 | `false` | 是否为当前选中会话（Desktop 双栏模式） |

#### 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **default** | 已读会话 | `bg-transparent`，文字 `text-muted-foreground`，无 badge |
| **unread** | `unreadCount > 0` | `bg-primary/5`，昵称 `font-semibold text-foreground`，消息片段 `font-medium text-foreground`，右侧红色 badge |
| **hover** | 鼠标悬浮 | `bg-muted/50`，`cursor-pointer`，`transition-colors duration-150` |
| **active** | `isActive === true`（Desktop 双栏） | `bg-muted border-l-2 border-l-primary` |
| **focus-visible** | 键盘聚焦 | `outline outline-2 outline-ring outline-offset-[-2px]` |
| **deleted-user** | 对方用户已删除 | 头像显示默认占位，昵称显示 "Deleted user"，整行 `opacity-60` |
| **newly-updated** | WebSocket 新消息到达 | 会话行更新（snippet + timestamp + badge），`fade-slide-up` 200ms |

#### 布局结构

```
┌──────────────────────────────────────────────┐
│  [Avatar]  Alice                    2h  [●3] │  ← 第一行：头像 + 昵称(左) + 时间+badge(右)
│            liked your guide about...         │  ← 第二行：消息片段
└──────────────────────────────────────────────┘
```

| 区域 | 样式 |
|------|------|
| Avatar | `h-10 w-10 rounded-full object-cover`；null 时默认灰色 `User` 图标 |
| 昵称 | `text-sm font-medium`；未读时 `font-semibold` |
| 消息片段 | `text-xs text-muted-foreground line-clamp-1`；未读时 `font-medium text-foreground` |
| 时间戳 | `text-xs text-muted-foreground`，右对齐 |
| Badge | `bg-primary text-primary-foreground text-[10px] font-bold min-w-[18px] h-[18px] rounded-full` |

#### 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击会话行 | 导航到 `/messages/{conversationId}` |
| 点击有未读的会话 | 导航 + 该会话所有消息标记已读 + badge 消失 + Header badge 更新 |

### 3.5 LoadMoreConversations 状态

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **visible** | 后端返回 `hasMore === true` | 列表底部居中 "Load more" 文字按钮，`text-sm text-primary hover:underline cursor-pointer` |
| **loading** | 点击后请求中 | spinner + "Loading..."，disabled |
| **end** | `hasMore === false` | 不渲染（无会话了就不显示任何提示） |
| **error** | 加载失败 | "Failed to load. [Retry]"，Retry 为文字链接 |
| **hidden** | 会话总数 ≤ 20 | 不渲染 |

### 3.6 实时推送状态（会话列表页）

| 场景 | 系统行为 | 视觉表现 |
|------|---------|---------|
| 收到新消息（已有会话） | 对应会话行更新（snippet + timestamp + badge +1），会话排序可能变化 | 会话行 `newly-updated` 动画 |
| 收到新消息（新会话） | 新会话插入列表顶部 | `fade-slide-up` 200ms 动画 |
| WebSocket 断线 | 自动重连 | 列表顶部细条 "Reconnecting..."，`text-xs text-muted-foreground bg-muted` |
| 重连成功 | 补发断线期间消息 | 提示条消失，列表更新 |
| 重连失败（>3 次） | 停止重连 | "Connection lost. [Refresh]" |

---

## 4. NewConversationDialog（新建会话浮层）

### 4.1 用途

搜索用户并发起新会话，或打开已有会话。

### 4.2 触发方式

- 会话列表页点击 "New message" 按钮
- URL 参数 `?new=true`

### 4.3 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **idle** | 刚打开，搜索框为空 | 搜索输入框 + placeholder "Search by nickname..." + 下方空白 |
| **typing** | 输入 < 2 字符 | 搜索输入框下方显示 "Type at least 2 characters to search"，`text-xs text-muted-foreground` |
| **searching** | 输入 ≥ 2 字符，请求中 | 搜索输入框 + spinner + "Searching..." |
| **results** | 搜索返回结果 | 搜索输入框 + 用户结果列表（最多 10 条） |
| **no-results** | 搜索返回空 | 搜索输入框 + "No users found"，`text-sm text-muted-foreground` |
| **search-error** | 搜索请求失败 | 搜索输入框 + "Search failed. [Retry]" |
| **creating** | 选中用户后创建会话中 | Dialog 内 spinner + "Starting conversation..." |

### 4.4 视觉布局

```
┌───────────────────────────────────┐
│  New message                 [✕]  │
├───────────────────────────────────┤
│                                   │
│  [ 🔍 Search by nickname...   ]  │  ← Input with search icon
│                                   │
│  ┌─────────────────────────────┐  │
│  │ [Avatar] Alice              │  │  ← 搜索结果行
│  ├─────────────────────────────┤  │
│  │ [Avatar] Bob                │  │
│  ├─────────────────────────────┤  │
│  │ [Avatar] Carol              │  │
│  └─────────────────────────────┘  │
│                                   │
└───────────────────────────────────┘
```

### 4.5 搜索结果行状态

| 状态 | 视觉表现 |
|------|---------|
| **default** | Avatar + 昵称，`hover:bg-muted cursor-pointer` |
| **hover** | `bg-muted` |
| **selected** | `bg-primary/10 border border-primary` |
| **existing** | 已有会话的用户，昵称旁显示小标签 "existing"，`text-xs text-muted-foreground` |

### 4.6 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 输入 ≥ 2 字符 | 300ms debounce 后触发搜索 API |
| 清空搜索框 | 回到 idle 状态 |
| 点击搜索结果用户 | 该行变为 selected → 创建/打开会话 → 导航到 `/messages/{conversationId}` → Dialog 关闭 |
| 按 `Escape` | 关闭 Dialog |
| 点击 ✕ | 关闭 Dialog |
| 点击遮罩层 | 关闭 Dialog |

---

## 5. ConversationPage（会话详情页）

### 5.1 进入条件

- 路由：`/messages/{conversationId}`
- 守卫：需要登录
- 前置：会话必须存在且当前用户是参与者

### 5.2 页面状态全表

页面存在 **7 个互斥状态**，按优先级从高到低：

| 状态名 | 触发条件 | 视觉表现 |
|--------|---------|---------|
| **loading** | 首次拉取会话数据 + 消息列表 | 全面板 Skeleton |
| **error** | 首次拉取失败 | 错误提示 + Retry |
| **not-found** | 会话 ID 不存在或当前用户非参与者 | "Conversation not found" + 返回链接 |
| **blocked-by-me** | 当前用户已屏蔽对方 | 会话只读模式 + 顶部提示条 |
| **blocked-by-other** | 对方已屏蔽当前用户 | 发送区域替换为提示文案 |
| **deleted-user** | 对方用户已删除 | 会话只读模式 + 顶部提示条 |
| **data** | 正常会话数据 | 消息列表 + 输入框 |

### 5.3 各状态详细视觉表现

#### 5.3.1 loading 状态

```
┌─────────────────────────────────────────────┐
│  [Avatar○] [████████]           [⋯ Menu]   │  ← Header Skeleton
├─────────────────────────────────────────────┤
│                                             │
│          [──── Skeleton bubble ────]        │  ← 对方消息 Skeleton（靠左）
│    [──── Skeleton bubble ──────]            │
│          [──── Skeleton bubble ────]        │
│               [── Skeleton bubble ──]       │  ← 自己消息 Skeleton（靠右）
│    [──── Skeleton bubble ──────]            │
│                                             │
├─────────────────────────────────────────────┤
│  [ Type a message...                  ] [➤] │  ← Input Skeleton
└─────────────────────────────────────────────┘
```

- Header：Avatar Skeleton（32×32）+ 昵称 Skeleton
- 消息区域：6 个气泡 Skeleton，左右交替，宽度随机（40%-70%）
- 输入区域：Input Skeleton + 按钮 Skeleton

#### 5.3.2 error 状态

同会话列表 error 状态样式，居中显示。

#### 5.3.3 not-found 状态

```
┌─────────────────────────────────────────────┐
│                                             │
│          💬 (MessageCircle, 48×48)          │
│           text-muted-foreground             │
│                                             │
│       "Conversation not found"              │
│    "This conversation doesn't exist or      │
│     you don't have access."                 │
│                                             │
│         [ ← Back to messages ]              │  ← variant="outline"
│                                             │
└─────────────────────────────────────────────┘
```

#### 5.3.4 blocked-by-me 状态（我屏蔽了对方）

```
┌─────────────────────────────────────────────┐
│  [Avatar] Deleted User          [⋯ Menu]   │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ ⚠️ You have blocked this user.         │ │  ← 顶部提示条
│ │    Messages will not be delivered.      │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│    (历史消息正常展示，只读)                   │
│                                             │
├─────────────────────────────────────────────┤
│  Input 区域替换为：                         │
│  "You have blocked this user"              │  ← text-sm text-muted-foreground
│  [ Unblock ]                               │  ← variant="outline" size="sm"
└─────────────────────────────────────────────┘
```

#### 5.3.5 blocked-by-other 状态（对方屏蔽了我）

```
┌─────────────────────────────────────────────┐
│  [Avatar] Alice                   [⋯ Menu]  │
├─────────────────────────────────────────────┤
│                                             │
│    (历史消息正常展示，只读)                   │
│                                             │
├─────────────────────────────────────────────┤
│  Input 区域替换为：                         │
│                                             │
│  "You have been blocked by this user"      │  ← text-sm text-muted-foreground
│                                             │
└─────────────────────────────────────────────┘
```

- 无 Unblock 按钮（因为是对方屏蔽了我）

#### 5.3.6 deleted-user 状态

```
┌─────────────────────────────────────────────┐
│  [Avatar○] Deleted user                     │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ ℹ️ This user no longer exists.         │ │  ← 顶部提示条
│ └─────────────────────────────────────────┘ │
│                                             │
│    (历史消息正常展示，只读)                   │
│                                             │
├─────────────────────────────────────────────┤
│  "This user no longer exists"              │
└─────────────────────────────────────────────┘
```

#### 5.3.7 data 状态（正常会话）

```
┌─────────────────────────────────────────────┐
│  [Avatar] Alice                   [⋯ Menu]  │  ← ConversationHeader
├─────────────────────────────────────────────┤
│  [ Load earlier messages ]                   │  ← LoadEarlierTrigger（条件显示）
│                                             │
│    ┌──────────────────┐                     │
│    │ Hey! How's your  │                     │  ← 对方消息（靠左）
│    │ trip going?      │                     │
│    │ 10:30 AM         │                     │
│    └──────────────────┘                     │
│                                             │
│         ┌──────────────────┐                │
│         │ Going great!     │                │  ← 自己消息（靠右）
│         │ Just arrived     │                │
│         │ in Beijing 🎉    │                │
│         │ 10:32 AM        │                │
│         └──────────────────┘                │
│                                             │
│    ┌──────────────────┐                     │
│    │ Awesome! Let     │                     │  ← 对方新消息（WebSocket 实时到达）
│    │ me know if you   │                     │
│    │ need any tips    │                     │
│    │ 10:35 AM         │                     │
│    └──────────────────┘                     │
│                                             │
├─────────────────────────────────────────────┤
│  [ Type a message...                  ] [➤] │  ← MessageInput
└─────────────────────────────────────────────┘
```

### 5.4 ConversationHeader 组件

#### 布局

```
[Avatar 32×32]  Alice                    [⋯]
```

| 元素 | 样式 |
|------|------|
| Avatar | `h-8 w-8 rounded-full object-cover` |
| 昵称 | `text-sm font-semibold text-foreground` |
| 更多菜单 | `lucide-react` 的 `MoreVertical`，`variant="ghost" size="icon-sm"` |

#### ConversationMenu 下拉菜单

| 菜单项 | 图标 | 行为 |
|--------|------|------|
| Block user | `Ban` | 点击打开确认对话框 |

### 5.5 MessageBubble 组件

#### Props 定义

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `id` | `string` | 是 | — | 消息 ID |
| `content` | `string` | 是 | — | 消息文本内容 |
| `timestamp` | `string` (ISO 8601) | 是 | — | 发送时间 |
| `isMine` | `boolean` | 是 | — | 是否为当前用户发送 |
| `status` | `'sent' \| 'failed'` | 否 | `'sent'` | 发送状态 |

#### 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **mine** | `isMine === true` | 气泡靠右，`bg-primary text-primary-foreground rounded-2xl rounded-tr-sm` |
| **other** | `isMine === false` | 气泡靠左，`bg-muted text-foreground rounded-2xl rounded-tl-sm` |
| **failed** | `status === 'failed'` | 气泡下方显示 "Failed to send" + [Retry] 链接，`text-xs text-destructive` |
| **sending** | 消息正在发送（乐观更新中） | 气泡 `opacity-60`，无时间戳 |
| **hover** | 鼠标悬浮 | 无视觉变化（`cursor-default`） |

#### 气泡布局

```
┌──────────────────────────┐
│ Message text content     │  ← text-sm，支持换行 `whitespace-pre-wrap`
│ that spans multiple      │
│ lines if needed          │
│                     10:32│  ← 时间戳，text-[10px] opacity-60，右下角
└──────────────────────────┘
```

- 最大宽度：`max-w-[75%]`
- 内边距：`px-3 py-2`
- 时间戳格式：相对时间（< 1 天 → "2h ago"；≥ 1 天 → "Sep 23"）

#### failed 状态详细

```
┌──────────────────────────┐
│ Message content          │
│                     10:32│
└──────────────────────────┘
  ⚠ Failed to send  [Retry]     ← text-xs text-destructive
```

- Retry 点击：重新发送该消息
- Retry 中：显示 spinner，Retry 文字变为 "Retrying..."

### 5.6 MessageInput 组件

#### Props 定义

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `disabled` | `boolean` | 否 | `false` | 是否禁用输入 |
| `placeholder` | `string` | 否 | `"Type a message..."` | 输入框占位文案 |
| `onSend` | `(content: string) => void` | 是 | — | 发送回调 |

#### 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **empty** | 输入为空或纯空白 | Send 按钮 disabled，`opacity-50` |
| **typing** | 输入有效内容（1-1000 字符） | Send 按钮 enabled，`bg-primary text-primary-foreground` |
| **near-limit** | 字数 > 900 | 右下角字数统计 `text-xs text-accent`，"{n}/1000" |
| **at-limit** | 字数 === 1000 | 字数统计 `text-destructive`，输入截断 |
| **over-limit** | 尝试输入超过 1000 字符 | 输入被截断，toast "Message must be 1000 characters or less" |
| **disabled** | `disabled === true`（被屏蔽/用户已删除） | Input 替换为提示文案，不渲染输入框 |
| **sending** | 消息发送中 | Send 按钮 spinner + disabled |
| **focus** | 输入框聚焦 | `border-ring ring-3 ring-ring/50` |

#### 布局

```
┌──────────────────────────────────────────────┐
│ [ Type a message...                   ] [➤] │
│                                  456/1000    │  ← 字数统计（> 900 时显示）
└──────────────────────────────────────────────┘
```

- 输入框：`h-10 rounded-lg border border-input px-3`
- Send 按钮：`h-10 w-10 rounded-lg`，`lucide-react` 的 `Send` 图标
- 字数统计：仅 > 900 字符时显示，`text-[10px] text-right mr-1`

#### 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 按 `Enter` | 发送消息（如有有效内容） |
| 按 `Shift+Enter` | 插入换行符 |
| 点击 Send 按钮 | 发送消息 |
| 发送中再次点击 Send | 按钮 disabled，忽略 |
| 输入纯空白 | Send 按钮 disabled |
| 输入超过 1000 字符 | 输入截断 + toast |

### 5.7 LoadEarlierTrigger 组件

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **visible** | 有更多历史消息 | 列表顶部居中 "Load earlier messages" 文字按钮 |
| **loading** | 加载中 | spinner + "Loading..." |
| **end** | 没有更早消息（或已达 30 天边界） | "Earlier messages are no longer available"，`text-xs text-muted-foreground`，3s 后自动消失 |
| **error** | 加载失败 | "Failed to load. [Retry]" |
| **hidden** | 消息总数 ≤ 50 | 不渲染 |

### 5.8 实时推送状态（会话详情页）

| 场景 | 系统行为 | 视觉表现 |
|------|---------|---------|
| 对方发送新消息 | 新消息气泡插入列表底部 | `fade-slide-up` 200ms 动画，自动滚动到底部 |
| 自己在他处发送消息 | 同上（WebSocket 同步） | 同上 |
| WebSocket 断线 | 自动重连 | 消息区域顶部细条 "Reconnecting..." |
| 重连成功 | 补发断线期间消息 | 提示条消失，消息批量插入 |
| 重连失败（>3 次） | 停止重连 | "Connection lost. [Refresh]" |
| 消息发送失败 | 乐观更新后收到失败响应 | 气泡 `opacity-100` 恢复 + 底部显示 "Failed to send" + [Retry] |

### 5.9 自动滚动行为

| 场景 | 行为 |
|------|------|
| 新消息到达（用户在底部） | 自动滚动到底部 |
| 新消息到达（用户在上方浏览历史） | 不自动滚动，底部出现 "↓ New messages" 浮动按钮 |
| 点击 "↓ New messages" | 滚动到底部，按钮消失 |
| 首次加载完成 | 滚动到最新消息（底部） |
| 加载更早消息 | 保持当前阅读位置（不跳动） |

---

## 6. Block User 确认对话框

### 6.1 视觉

```
┌───────────────────────────────────┐
│                                   │
│   Block Alice?                    │  ← text-lg font-semibold
│                                   │
│   They will no longer be able     │
│   to send you messages.           │  ← text-sm text-muted-foreground
│                                   │
│   [ Cancel ]        [ Block ]     │
│                                   │
└───────────────────────────────────┘
```

- 使用 shadcn/ui Dialog
- Block 按钮：`variant="destructive"`
- Block 中：按钮 spinner + "Blocking..."

### 6.2 状态

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **closed** | 未触发 | 不渲染 |
| **open** | 点击 "Block user" | Dialog 弹出 |
| **confirming** | 点击 Block 按钮 | 按钮 spinner + disabled |
| **success** | API 成功 | Dialog 关闭 → 会话列表刷新（该会话消失）→ toast "User blocked" |
| **error** | API 失败 | Dialog 保持打开 → toast "Failed to block user" → 按钮恢复 |

---

## 7. Toast 通知汇总

| Toast 类型 | 触发场景 | 文案 | 持续时间 |
|-----------|---------|------|---------|
| **success** | 屏蔽用户成功 | "User blocked" | 3s |
| **success** | 消息发送成功 | 不显示 toast（静默） | — |
| **error** | 屏蔽用户失败 | "Failed to block user" | 手动关闭 |
| **error** | 消息发送失败 | "Failed to send. [Retry]" | 手动关闭 |
| **error** | 被对方屏蔽 | "You have been blocked by this user" | 5s |
| **warning** | 频率限制触发 | "Too many messages, please slow down" | 3s |
| **error** | 消息超过 1000 字符 | "Message must be 1000 characters or less" | 3s |
| **info** | WebSocket 断线 | "Connection lost. Messages may be delayed." | 持续显示 |

---

## 8. 完整页面状态流转图

### 8.1 会话列表页

```
  用户访问 /messages
       │
       ▼
  ┌──────────────┐
  │  已登录？     │
  └──┬────────┬──┘
     │ 否     │ 是
     ▼        ▼
  redirect  ┌────────────┐
  to login  │  loading   │ ← Skeleton × 5
            └─────┬──────┘
                  │
          ┌───────┼────────┐
          │       │        │
          ▼       ▼        ▼
    ┌────────┐ ┌──────┐ ┌──────────┐
    │ error  │ │empty │ │   data   │
    │(错误+  │ │(空态)│ │ (会话列表)│
    │ Retry) │ │      │ │          │
    └────────┘ └──────┘ └────┬─────┘
                             │
                    ┌────────┼──────────┐
                    │        │          │
                    ▼        ▼          ▼
               点击会话  点击 New msg  WebSocket
                    │        │          │
                    ▼        ▼          ▼
              导航到会话  NewConvDialog  实时更新列表
              详情页      搜索+创建      + badge
```

### 8.2 会话详情页

```
  用户访问 /messages/{id}
       │
       ▼
  ┌──────────────┐
  │  已登录？     │
  └──┬────────┬──┘
     │ 否     │ 是
     ▼        ▼
  redirect  ┌────────────┐
  to login  │  loading   │ ← 全面板 Skeleton
            └─────┬──────┘
                  │
      ┌───────────┼────────────┬──────────────┐
      │           │            │              │
      ▼           ▼            ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐
│  error   │ │not-found │ │  data    │ │ deleted-user │
│ (错误+   │ │(不存在)  │ │ (正常)   │ │ (用户已删除) │
│  Retry)  │ │          │ │          │ │              │
└──────────┘ └──────────┘ └────┬─────┘ └──────────────┘
                               │
                    ┌──────────┼───────────┐
                    │          │           │
                    ▼          ▼           ▼
              检查屏蔽状态   发送消息    WebSocket
                    │          │           │
              ┌─────┼─────┐   │           │
              │     │     │   │           │
              ▼     ▼     ▼   ▼           ▼
          未屏蔽  我屏蔽  被屏蔽  发送中   新消息到达
          (data)  了对方  对方    │        │
              │   (只读)  (只读)  ▼        ▼
              │     │     │   乐观更新  气泡插入
              │     │     │   → sent    + 自动滚动
              │     │     │   → failed  + "Failed"
              │     │     │
              ▼     ▼     ▼
          正常输入  显示    显示
          + 发送   Unblock  "blocked"
                   按钮    提示
```

---

## 9. 响应式规则

### 9.1 会话列表页

| 断点 | 布局 |
|------|------|
| Mobile（< 768px） | 全屏单列，会话项占满宽度，`px-4` |
| Desktop（≥ 768px） | 居中 `max-w-[600px] mx-auto` |

### 9.2 会话详情页

| 断点 | 布局 |
|------|------|
| Mobile（< 768px） | 全屏，消息区域 `px-3`，MessageInput 吸底 `sticky bottom-0 bg-background border-t` |
| Desktop（≥ 768px） | 居中 `max-w-[720px] mx-auto`，消息区域 `px-4` |

### 9.3 NewConversationDialog

| 断点 | 布局 |
|------|------|
| Mobile（< 768px） | 底部 Sheet 滑入（`sheet` 组件） |
| Desktop（≥ 768px） | 居中 Dialog，`w-[400px]` |

---

## 10. 无障碍要求

| 要求 | 实现 |
|------|------|
| 会话列表 | `role="list"` + `aria-label="Conversations"` |
| 会话项 | `role="listitem"` + `tabIndex={0}` + `aria-label="{nickname}, {snippet}, {time}{unread}"` |
| 未读 badge | `aria-label="{n} unread messages"` |
| 消息列表 | `role="log"` + `aria-live="polite"` + `aria-label="Message history"` |
| 消息气泡 | `aria-label="{sender}, {content}, {time}"` |
| 输入框 | `aria-label="Message input"` + `aria-describedby="char-count"` |
| Send 按钮 | `aria-label="Send message"` |
| 字数统计 | `aria-live="polite"` |
| Block 对话框 | `role="alertdialog"` + `aria-labelledby` + `aria-describedby` |
| Header badge | `aria-label="Messages, {n} unread conversations"` |
| 新消息到达 | `aria-live="polite"` 区域播报 |
| 焦点管理 | Dialog 打开时焦点 trap；关闭后焦点回到触发元素 |

---

## 11. 动画规格汇总

| 动画 | 触发时机 | CSS 实现 | 时长 |
|------|---------|---------|------|
| badge 弹跳 | 新消息到达，badge 数字变化 | `scale-110 → scale-100`，`transition-transform` | 200ms |
| 新消息气泡滑入 | WebSocket 推送新消息 | 复用 `fade-slide-up` 关键帧 | 200ms |
| 新会话行滑入 | 新会话插入列表 | 复用 `fade-slide-up` | 200ms |
| Skeleton 脉冲 | loading 状态 | `animate-pulse`（Tailwind 内置） | 2s loop |
| Dialog 进入 | NewConversation / Block 确认弹出 | shadcn/ui Dialog 默认 `fade-in` + `zoom-in-95` | 150ms |
| Dialog 退出 | 关闭对话框 | shadcn/ui Dialog 默认 `fade-out` + `zoom-out-95` | 100ms |
| Sheet 滑入（Mobile） | NewConversation 底部弹出 | shadcn/ui Sheet 默认 `slide-in-from-bottom` | 200ms |
| 消息发送中 | 乐观更新 | `opacity-60`，`transition-opacity` | 200ms |
| 消息发送失败 | 发送失败 | `opacity-100` 恢复 + 错误文案淡入 | 200ms |
| 尊重用户偏好 | 系统级减少动画 | 复用 `globals.css` 中 `prefers-reduced-motion` | 所有动画降为 0.01ms |

---

## 12. 验收清单

### 会话列表页

- [ ] 未登录访问 `/messages` → 重定向到登录页
- [ ] 已登录访问 → loading Skeleton → 正常渲染会话列表
- [ ] 加载失败 → error 状态 + Retry 按钮
- [ ] 无会话 → empty 状态 + "Start a conversation" CTA
- [ ] 会话列表按最近消息时间倒序
- [ ] 每条会话展示：头像 + 昵称 + 消息片段（截断 40 字符）+ 时间 + 未读 badge
- [ ] 有未读的会话：背景高亮 + badge 显示数字
- [ ] 会话 > 20 条 → 底部 "Load more"
- [ ] "Load more" 成功 → 追加 20 条
- [ ] "Load more" 失败 → 错误 + Retry
- [ ] 点击会话 → 导航到会话详情页
- [ ] 点击有未读的会话 → 标记已读 + badge 消失 + Header badge 更新
- [ ] WebSocket 新消息 → 对应会话行实时更新（snippet + timestamp + badge）
- [ ] WebSocket 新会话 → 列表顶部插入新会话行
- [ ] WebSocket 断线 → "Reconnecting..." 提示
- [ ] WebSocket 重连成功 → 提示消失 + 补发
- [ ] WebSocket 重连失败 → "Connection lost. [Refresh]"

### 新建会话

- [ ] 点击 "New message" → 打开 NewConversationDialog
- [ ] 输入 < 2 字符 → "Type at least 2 characters to search"
- [ ] 输入 ≥ 2 字符 → 300ms debounce → 搜索结果（最多 10 条）
- [ ] 搜索无结果 → "No users found"
- [ ] 搜索失败 → "Search failed. [Retry]"
- [ ] 搜索结果不显示自己
- [ ] 选择已有会话用户 → 打开已有会话（不重复创建）
- [ ] 选择新用户 → 创建新会话 → 导航到会话详情页
- [ ] Mobile：底部 Sheet 滑入
- [ ] Desktop：居中 Dialog

### 会话详情页

- [ ] 未登录 → 重定向
- [ ] 会话不存在 → not-found 状态 + "Back to messages" 链接
- [ ] 正常会话 → loading Skeleton → 消息列表 + 输入框
- [ ] 消息按时间正序，自己的靠右，对方的靠左
- [ ] 每条消息显示文本 + 时间戳
- [ ] 消息 > 50 条 → 顶部 "Load earlier messages"
- [ ] 加载更早消息 → 保持阅读位置
- [ ] 超过 30 天 → "Earlier messages are no longer available"
- [ ] Enter 发送消息 → 乐观更新 → sent/failed
- [ ] Shift+Enter 换行
- [ ] 纯空白 → Send 按钮 disabled
- [ ] 超过 1000 字符 → 输入截断 + toast
- [ ] 发送失败 → "Failed to send" + [Retry]
- [ ] 点击 Retry → 重新发送
- [ ] 新消息到达（用户在底部）→ 自动滚动到底部
- [ ] 新消息到达（用户在上方）→ "↓ New messages" 浮动按钮
- [ ] 对方用户已删除 → 只读模式 + 提示条
- [ ] 我屏蔽了对方 → 只读模式 + "Unblock" 按钮
- [ ] 对方屏蔽了我 → 只读模式 + "You have been blocked" 提示
- [ ] Block user → 确认对话框 → 确认后会话从列表消失 + toast
- [ ] Block 失败 → toast 错误
- [ ] 频率限制 → toast "Too many messages, please slow down"
- [ ] Header 消息图标 badge 显示总未读会话数
- [ ] 键盘操作：Tab 遍历，Enter 发送，Escape 关闭 Dialog
- [ ] 屏幕阅读器：消息列表 `role="log"` + `aria-live`
- [ ] 减少动画偏好：所有动画降级
