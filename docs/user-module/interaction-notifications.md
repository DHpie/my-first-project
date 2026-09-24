# 消息通知（Notifications）交互规格

## 1. 组件架构总览

```
Header
  └── NotificationBell          ← 铃铛图标 + 未读 badge（常驻 Header 右侧）
        └── NotificationPanel   ← 点击铃铛展开的下拉面板（Popover）
              ├── PanelHeader   ← 标题 + "Mark all as read" 按钮
              ├── NotificationList
              │     └── NotificationItem × N  ← 单条通知行
              ├── LoadMoreTrigger              ← "Load more" 按钮 / 底部提示
              └── (状态层) Loading / Error / Empty
```

| 组件 | 文件路径 | 类型 |
|------|---------|------|
| `NotificationBell` | `components/notifications/notification-bell.tsx` | Client Component |
| `NotificationPanel` | `components/notifications/notification-panel.tsx` | Client Component |
| `NotificationItem` | `components/notifications/notification-item.tsx` | Client Component |

---

## 2. NotificationBell 组件

### 2.1 用途

常驻 Header 右侧的铃铛图标，展示未读通知计数 badge，点击展开通知面板。

### 2.2 Props 定义

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `unreadCount` | `number` | 是 | — | 当前未读通知数量 |
| `onClick` | `() => void` | 是 | — | 点击铃铛的回调（toggle panel） |

### 2.3 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **hidden** | 用户未登录 | 铃铛图标不渲染，不占位 |
| **idle** | `unreadCount === 0` | 铃铛图标 `text-muted-foreground`，无 badge |
| **has-unread** | `unreadCount > 0 && unreadCount <= 99` | 铃铛图标右上角显示红色 badge，内容为数字 |
| **overflow** | `unreadCount > 99` | badge 内容显示 "99+" |
| **hover** | 鼠标悬浮 | `text-foreground`，`transition-colors duration-200` |
| **active** | 面板已展开 | 铃铛图标 `text-primary`，badge 保持显示 |
| **realtime-pulse** | WebSocket 推送新通知到达 | badge 数字增加，触发一次 `scale-110 → scale-100` 弹跳动画（`duration-200`） |

### 2.4 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击铃铛 | toggle `NotificationPanel` 展开/收起；展开时 `aria-expanded="true"` |
| 面板展开时点击页面其他区域 | 面板自动收起（Popover outside click） |
| 按 `Escape` 键 | 面板收起，焦点回到铃铛按钮 |
| 新通知通过 WebSocket 到达（面板关闭） | badge 数字 +1，铃铛触发弹跳动画 |
| 新通知通过 WebSocket 到达（面板打开） | badge 数字 +1，新通知插入列表顶部（见 NotificationPanel 实时推送状态） |

### 2.5 Badge 视觉规格

```
铃铛图标容器（relative）
  ├── Bell icon（lucide-react: `Bell`，20×20，`text-muted-foreground`）
  └── Badge（absolute, -top-1.5 -right-1.5）
        ├── 背景: `bg-primary`（品牌红 #C41E3A）
        ├── 文字: `text-primary-foreground text-[10px] font-bold leading-none`
        ├── 最小尺寸: `min-w-[18px] h-[18px]`
        ├── 圆角: `rounded-full`
        ├── 边框: `ring-2 ring-background`（与 Header 背景隔离）
        └── 内容: count ≤ 99 → 数字; count > 99 → "99+"
```

---

## 3. NotificationPanel 组件

### 3.1 用途

从 Header 铃铛处展开的下拉面板，展示通知列表，支持已读/未读管理、分页加载、实时更新。

### 3.2 Props 定义

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `open` | `boolean` | 是 | — | 面板是否展开 |
| `onOpenChange` | `(open: boolean) => void` | 是 | — | 面板开关回调 |

### 3.3 页面状态全表

面板打开后，内部存在 **5 个互斥状态**，按优先级从高到低排列：

| 状态名 | 触发条件 | 视觉表现 | 覆盖区域 |
|--------|---------|---------|---------|
| **connecting** | WebSocket 未连接且首次数据尚未返回 | 整个面板显示连接中 Skeleton | 全面板 |
| **loading** | 首次拉取通知列表（API 请求中） | 整个列表区域显示 Skeleton 占位 | 列表区域 |
| **error** | 首次拉取通知列表失败 | 错误提示 + Retry 按钮 | 全面板 |
| **empty** | 列表成功返回但数据为空（`length === 0`） | 空状态插图 + 文案 | 列表区域 |
| **data** | 列表成功返回且有数据 | 正常渲染通知列表 | 列表区域 |

### 3.4 各状态详细视觉表现

#### 3.4.1 connecting 状态

```
┌─────────────────────────────────────┐
│ 🔔 Notifications                    │
├─────────────────────────────────────┤
│                                     │
│   [Skeleton 脉冲动画 × 3 行]        │
│   等待 WebSocket 连接建立...         │
│                                     │
└─────────────────────────────────────┘
```

- 3 行 Skeleton，每行高度 64px，间距 `gap-2`
- Skeleton 使用 `bg-muted` + `animate-pulse`

#### 3.4.2 loading 状态（首次加载）

```
┌─────────────────────────────────────┐
│ 🔔 Notifications         Mark all   │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [Avatar○] [████████] [██████]  │ │  ← Skeleton 行 1
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar○] [██████████] [████]  │ │  ← Skeleton 行 2
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar○] [██████] [████████]  │ │  ← Skeleton 行 3
│ └─────────────────────────────────┘ │
│         ... (共 5 行 Skeleton)       │
└─────────────────────────────────────┘
```

- 5 行 Skeleton 占位，模拟 NotificationItem 布局
- 每行结构：左侧圆形 Avatar Skeleton（32×32）+ 右侧两行文字 Skeleton（长条 + 短条）
- 使用 `bg-muted` + `animate-pulse`

#### 3.4.3 error 状态

```
┌─────────────────────────────────────┐
│ 🔔 Notifications                    │
├─────────────────────────────────────┤
│                                     │
│          ⚠️ (lucide: AlertCircle)   │
│       "Something went wrong"        │
│       "Could not load notifications"│
│                                     │
│         [ Retry ]                   │
│                                     │
└─────────────────────────────────────┘
```

- 图标：`lucide-react` 的 `AlertCircle`，40×40，`text-muted-foreground`
- 主文案：`text-sm font-medium text-foreground`，"Something went wrong"
- 副文案：`text-xs text-muted-foreground`，"Could not load notifications"
- Retry 按钮：`variant="outline" size="sm"`，点击重新触发首次加载
- Retry 按钮点击后：进入 **loading** 状态，按钮显示 loading spinner + disabled

#### 3.4.4 empty 状态

```
┌─────────────────────────────────────┐
│ 🔔 Notifications                    │
├─────────────────────────────────────┤
│                                     │
│        🔔 (lucide: Bell, 48×48)     │
│         opacity-30                  │
│                                     │
│       "No notifications yet"        │
│  "When someone interacts with your  │
│    content, you'll see it here."    │
│                                     │
└─────────────────────────────────────┘
```

- 图标：`lucide-react` 的 `Bell`，48×48，`text-muted-foreground opacity-30`
- 主文案：`text-sm font-medium text-foreground`，"No notifications yet"
- 副文案：`text-xs text-muted-foreground text-center max-w-[200px]`
- PanelHeader 中的 "Mark all as read" 按钮隐藏

#### 3.4.5 data 状态（正常渲染）

```
┌─────────────────────────────────────┐
│ 🔔 Notifications         Mark all   │  ← PanelHeader
├─────────────────────────────────────┤
│ ● 🟢 Alice liked your post         │  ← 未读项（蓝色圆点 + 粗体）
│    "Top 10 Spots in..."    2h ago   │
│ ─────────────────────────────────── │
│ 🟡 Bob commented on your post      │  ← 已读项（无圆点 + 常规字重）
│    "Great guide for..."    5h ago   │
│ ─────────────────────────────────── │
│ 🔵 Carol replied to your comment   │  ← 未读项
│    "Thanks for the..."     1d ago   │
│ ─────────────────────────────────── │
│            [ Load more ]            │  ← LoadMoreTrigger
└─────────────────────────────────────┘
```

### 3.5 PanelHeader 交互

| 元素 | 行为 |
|------|------|
| 标题 "Notifications" | 纯文本，`text-sm font-semibold` |
| "Mark all as read" 按钮 | 仅在有未读通知时显示（`unreadCount > 0`） |
| 点击 "Mark all as read" | 按钮进入 loading 态（spinner + disabled）→ API 调用成功 → 所有通知变为已读样式，badge 归零，按钮隐藏 |
| "Mark all as read" 失败 | 按钮恢复可点击，显示 toast "Failed to mark all as read" |

### 3.6 LoadMoreTrigger 状态

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **visible** | 后端返回 `hasMore === true` | 显示 "Load more" 文本按钮，居中，`text-sm text-primary hover:underline` |
| **loading** | 点击 "Load more" 后请求中 | 按钮变为 spinner + "Loading..."，disabled |
| **end** | 后端返回 `hasMore === false` | 显示 "No more notifications"，`text-xs text-muted-foreground`，不可点击 |
| **error** | 加载更多失败 | 显示 "Failed to load. [Retry]"，Retry 为文字链接 |
| **hidden** | 通知总数 ≤ 20（首页即全部） | 不渲染 |

### 3.7 实时推送状态（WebSocket）

| 场景 | 系统行为 | 视觉表现 |
|------|---------|---------|
| 面板关闭时收到新通知 | 更新 `unreadCount`，NotificationBell badge +1 | badge 弹跳动画 |
| 面板打开时收到新通知 | 新通知插入列表**最顶部**，`unreadCount` +1 | 新通知行以 `fade-slide-up` 动画进入（200ms），带未读视觉标记 |
| WebSocket 断线 | 自动重连（指数退避，最大 30s） | 面板底部显示细条提示 "Reconnecting..."，`text-xs text-muted-foreground bg-muted` |
| WebSocket 重连成功 | 拉取断线期间未读通知，批量插入列表 | 提示条消失，新通知以动画进入 |
| WebSocket 重连失败（超过 3 次） | 停止重连，提示用户 | 提示条变为 "Connection lost. [Refresh]"，Refresh 为文字按钮 |

### 3.8 面板尺寸与定位

```
定位：Popover，锚定到 NotificationBell 按钮下方
对齐：right（面板右边缘对齐铃铛右边缘）
偏移：mt-2
宽度：w-[360px]（固定宽度）
最大高度：max-h-[480px]，超出后列表区域 overflow-y-auto
圆角：rounded-lg
阴影：shadow-lg
背景：bg-popover
边框：border
```

响应式：

| 断点 | 行为 |
|------|------|
| Mobile（< 768px） | 面板宽度改为 `w-[calc(100vw-32px)]`，最大不超过 360px，从右侧滑出 |
| Desktop（≥ 768px） | 固定 `w-[360px]` |

---

## 4. NotificationItem 组件

### 4.1 用途

单条通知行，展示互动类型、操作者、动作描述、内容片段和时间戳。

### 4.2 Props 定义

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `id` | `string` | 是 | — | 通知唯一 ID |
| `type` | `'like' \| 'comment' \| 'reply'` | 是 | — | 通知类型 |
| `actorAvatar` | `string \| null` | 是 | — | 操作者头像 URL，null 时为已删除用户 |
| `actorNickname` | `string` | 是 | — | 操作者昵称 |
| `actionText` | `string` | 是 | — | 动作描述（如 "liked your post"） |
| `contentSnippet` | `string` | 是 | — | 目标内容片段（截断至 40 字符） |
| `timestamp` | `string` (ISO 8601) | 是 | — | 通知时间 |
| `isRead` | `boolean` | 是 | — | 是否已读 |
| `isContentDeleted` | `boolean` | 是 | `false` | 原始内容是否已被删除 |
| `onClick` | `(id: string) => void` | 是 | — | 点击回调 |

### 4.3 布局结构

```
┌──────────────────────────────────────────────┐
│  [●]  [Avatar]  Alice liked your post   2h  │  ← 第一行
│              "Top 10 Spots in Chengdu..."    │  ← 第二行（内容片段）
└──────────────────────────────────────────────┘
```

| 区域 | 元素 | 样式 |
|------|------|------|
| 未读指示 | 蓝色圆点 `●` | `h-2 w-2 rounded-full bg-primary`，仅 `isRead === false` 时显示 |
| 头像 | 圆形缩略图 | `h-8 w-8 rounded-full object-cover`；`actorAvatar === null` 时显示默认灰色人形占位 |
| 动作描述 | 文字 | `text-sm`；未读时 `font-semibold text-foreground`，已读时 `font-normal text-muted-foreground` |
| 内容片段 | 文字 | `text-xs text-muted-foreground line-clamp-1`，斜体 |
| 时间戳 | 相对时间 | `text-xs text-muted-foreground`，右对齐 |
| 类型图标 | 小图标叠加在头像右下角 | like: `Heart`（`text-primary`）; comment: `MessageCircle`（`text-accent`）; reply: `Reply`（`text-accent`）；尺寸 12×12 |

### 4.4 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **unread** | `isRead === false` | 左侧蓝色圆点 + 文字 `font-semibold` + 背景 `bg-primary/5` |
| **read** | `isRead === true` | 无圆点 + 文字 `font-normal` + 背景 `transparent` |
| **hover** | 鼠标悬浮 | `bg-muted/50`，`cursor-pointer`，`transition-colors duration-150` |
| **active** | 鼠标按下 | `bg-muted` |
| **focus-visible** | 键盘聚焦 | `outline outline-2 outline-ring outline-offset-[-2px]` |
| **content-deleted** | `isContentDeleted === true` | 内容片段显示 "content removed" + `italic text-muted-foreground`；点击触发 toast 而非跳转 |
| **actor-deleted** | `actorAvatar === null && actorNickname === "Deleted user"` | 头像显示默认灰色占位；整行 `opacity-60`；点击不跳转 |
| **newly-arrived** | WebSocket 实时推送的新通知刚插入 | `fade-slide-up` 动画（200ms），蓝色圆点带一次 `pulse` 动画 |
| **marking-read** | 点击后标记已读进行中 | 蓝色圆点 `opacity-0` 过渡消失（`transition-opacity duration-200`），背景色从 `bg-primary/5` 过渡到 `transparent` |

### 4.5 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击通知行（内容存在） | 1. 行进入 `marking-read` 状态；2. 调用 `markAsRead` API；3. 面板关闭；4. 路由跳转到 `/posts/{postId}`；5. badge 数量 -1 |
| 点击通知行（内容已删除） | 1. 行进入 `marking-read` 状态；2. 调用 `markAsRead` API；3. 显示 toast "This content is no longer available"；4. 不跳转，面板保持打开；5. badge 数量 -1 |
| 点击通知行（用户已删除） | 1. 行进入 `marking-read` 状态；2. 调用 `markAsRead` API；3. 显示 toast "This content is no longer available"；4. 不跳转；5. badge 数量 -1 |
| 点击通知行，API 调用失败 | 行恢复原始状态，显示 toast "Failed to update notification" |

---

## 5. Toast 通知

用于操作反馈和异常提示，复用 shadcn/ui 的 Sonner toast 组件。

| Toast 类型 | 触发场景 | 文案 | 持续时间 |
|-----------|---------|------|---------|
| **success** | "Mark all as read" 成功 | "All notifications marked as read" | 3s，自动消失 |
| **error** | 标记已读 API 失败 | "Failed to update notification" + [Retry] | 手动关闭 |
| **error** | "Mark all as read" API 失败 | "Failed to mark all as read" + [Retry] | 手动关闭 |
| **info** | 点击已删除内容的通知 | "This content is no longer available" | 3s，自动消失 |
| **info** | WebSocket 断线 | "Connection lost. Notifications may be delayed." | 持续显示，重连后消失 |

---

## 6. 完整页面状态流转图

```
                    ┌──────────────┐
                    │  用户未登录   │ → NotificationBell 不渲染
                    └──────────────┘

                    ┌──────────────┐
            ┌──────→│  用户已登录   │──────┐
            │       │  (idle 态)   │      │
            │       └──────────────┘      │
            │                             │
            │ 点击铃铛                     │ 未登录
            │                             │
            ▼                             │
    ┌───────────────┐                     │
    │  首次加载判断  │                     │
    └───────┬───────┘                     │
            │                             │
    ┌───────┴───────────┐                 │
    │ WebSocket 已连接？ │                 │
    └───┬───────────┬───┘                 │
        │ 是        │ 否                  │
        ▼           ▼                     │
  ┌──────────┐ ┌────────────┐            │
  │ loading  │ │ connecting │            │
  │ (Skeleton│ │ (Skeleton  │            │
  │  × 5行)  │ │  + 提示)   │            │
  └────┬─────┘ └─────┬──────┘            │
       │              │                   │
       ▼              ▼                   │
  ┌──────────────────────────┐            │
  │     API 返回结果判断      │            │
  └──┬──────────┬────────┬───┘            │
     │ 成功     │ 失败   │ 空数据          │
     │ + 有数据 │        │                │
     ▼          ▼        ▼                │
 ┌────────┐ ┌───────┐ ┌───────┐          │
 │  data  │ │ error │ │ empty │          │
 │ (列表) │ │ (错误) │ │ (空态) │          │
 └───┬────┘ └───┬───┘ └───────┘          │
     │          │                         │
     │     点击 Retry                     │
     │          │                         │
     │          └──────→ 回到 loading     │
     │                                    │
     │  面板内交互：                       │
     │  ├── 点击通知 → 跳转帖子详情页      │
     │  ├── 点击通知(已删除) → toast 提示  │
     │  ├── Mark all as read → 批量已读   │
     │  ├── Load more → 追加数据          │
     │  └── WebSocket 新通知 → 顶部插入   │
     │                                    │
     └──── 关闭面板 ────→ 回到 idle 态 ───┘
```

---

## 7. 响应式规则

| 断点 | NotificationBell | NotificationPanel |
|------|-----------------|-------------------|
| Mobile（< 768px） | 铃铛图标 18×18，badge 不变 | `w-[calc(100vw-32px)] max-w-[360px]`，从右侧滑入 |
| Desktop（≥ 768px） | 铃铛图标 20×20 | 固定 `w-[360px]`，Popover 下拉 |

---

## 8. 无障碍要求

| 要求 | 实现 |
|------|------|
| 铃铛按钮 | `aria-label="Notifications"` + `aria-haspopup="true"` + `aria-expanded` |
| 未读计数 | 铃铛 `aria-label` 动态包含计数："Notifications, {n} unread" |
| 面板 | `role="dialog"` + `aria-label="Notifications panel"` |
| 通知列表 | `role="list"` + `aria-label="Notification list"` |
| 通知项 | `role="listitem"` + `tabIndex={0}` + 键盘 Enter/Space 触发点击 |
| 未读标记 | 未读通知行 `aria-current="true"`（语义化标记） |
| Mark all as read | `aria-label="Mark all notifications as read"` |
| 实时通知 | 新通知插入时使用 `aria-live="polite"` 区域，屏幕阅读器播报 |
| 焦点管理 | 面板打开时焦点 trap 在面板内；关闭时焦点回到铃铛按钮 |

---

## 9. 动画规格汇总

| 动画 | 触发时机 | CSS 实现 | 时长 |
|------|---------|---------|------|
| badge 弹跳 | 新通知到达，badge 数字变化 | `scale-110 → scale-100`，`transition-transform` | 200ms |
| 新通知滑入 | WebSocket 推送新通知插入列表顶部 | 复用 `fade-slide-up` 关键帧 | 200ms |
| 未读圆点脉冲 | 新通知刚到达 | `animate-pulse` 执行一次 | 500ms |
| 已读过渡 | 点击通知后标记已读 | 背景色 `transition-colors` + 圆点 `transition-opacity` | 200ms |
| 面板展开 | 点击铃铛展开面板 | Popover 默认 `fade-in` + `slide-in-from-top-2` | 150ms |
| 面板收起 | 关闭面板 | Popover 默认 `fade-out` + `slide-out-to-top-2` | 100ms |
| Skeleton 脉冲 | loading/connecting 状态 | `animate-pulse`（Tailwind 内置） | 2s loop |
| 尊重用户偏好 | 系统级减少动画 | 复用 `globals.css` 中 `prefers-reduced-motion` 媒体查询 | 所有动画降为 0.01ms |

---

## 10. 验收清单

- [ ] 未登录用户：Header 中不渲染铃铛图标，不建立 WebSocket 连接
- [ ] 已登录 + 0 未读：铃铛显示，无 badge
- [ ] 已登录 + 1~99 未读：badge 显示对应数字
- [ ] 已登录 + 100+ 未读：badge 显示 "99+"
- [ ] 点击铃铛：展开 NotificationPanel，铃铛变为 `text-primary`
- [ ] 面板首次加载：显示 loading Skeleton（5 行）
- [ ] 面板首次加载失败：显示 error 状态 + Retry 按钮
- [ ] Retry 点击：重新进入 loading 状态
- [ ] 面板加载成功 + 有数据：显示通知列表，未读项有蓝色圆点 + 粗体 + 浅色背景
- [ ] 面板加载成功 + 无数据：显示 empty 状态（Bell 图标 + 文案）
- [ ] 点击未读通知（内容存在）：标记已读 → 面板关闭 → 跳转帖子详情页
- [ ] 点击未读通知（内容已删除）：标记已读 → toast "This content is no longer available" → 面板保持
- [ ] 点击已读通知：同样跳转帖子详情页（无状态变化）
- [ ] "Mark all as read"：所有通知变为已读样式，badge 归零，按钮隐藏
- [ ] "Mark all as read" 失败：toast 错误提示 + 按钮恢复
- [ ] 通知 > 20 条：底部显示 "Load more" 按钮
- [ ] 点击 "Load more"：显示 loading → 追加 20 条 → 到底后显示 "No more notifications"
- [ ] "Load more" 失败：显示错误 + Retry 链接
- [ ] WebSocket 新通知（面板关闭）：badge +1 + 弹跳动画
- [ ] WebSocket 新通知（面板打开）：新通知滑入列表顶部 + badge +1
- [ ] WebSocket 断线：面板底部显示 "Reconnecting..." 提示
- [ ] WebSocket 重连成功：提示消失，补发通知插入列表
- [ ] WebSocket 重连失败（>3 次）：显示 "Connection lost. [Refresh]"
- [ ] Mobile：面板宽度自适应 `calc(100vw - 32px)`
- [ ] Desktop：面板固定 360px
- [ ] 键盘操作：Escape 关闭面板，Tab 焦点 trap，Enter/Space 触发通知
- [ ] 屏幕阅读器：`aria-label` 包含未读计数，新通知通过 `aria-live` 播报
- [ ] 减少动画偏好：所有动画降级
