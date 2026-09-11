## Purpose

为 ChinaBuddy 首页提供社区精选区——3–4 条 UGC（用户生成内容）帖子摘要的策展列表，让访客浏览真实的旅行者经验。本区服务于正在规划行程、希望获得真实建议的用户（US-H2）。

## In Scope

1. 社区帖子摘要展示（3–4 条）
2. `GET /api/posts/featured` API 集成，含 loading/error/empty 状态
3. 帖子点击导航至帖子详情页
4. 头像图片渲染（`next/image`）与失败回退
5. 点赞数格式化（人类可读）
6. 摘要按单词边界截断
7. 响应式布局（Tailwind mobile-first 断点）

## Requirements

### Requirement: 社区帖子展示
本区 SHALL 显示 3 至 4 条社区帖子摘要。

#### Scenario: 帖子摘要内容
- **WHEN** 社区区带数据渲染
- **THEN** 每条帖子摘要 SHALL 显示：用户头像（`next/image`）、用户名、帖子标题、帖子摘要（截断至最多 120 字符）、点赞数

#### Scenario: 帖子数量在范围内
- **WHEN** API 返回 N 条帖子（3 ≤ N ≤ 4）
- **THEN** 本区 SHALL 恰好渲染 N 条帖子摘要

#### Scenario: 帖子数量超上限
- **WHEN** API 返回超过 4 条帖子
- **THEN** 本区 SHALL 仅渲染前 4 条并忽略其余

#### Scenario: 帖子数量低于预期范围
- **WHEN** API 返回 1 或 2 条帖子
- **THEN** 本区 SHALL 无错渲染全部可用帖子

### Requirement: 摘要截断
帖子摘要 SHALL 在单词边界处截断，最多 120 字符。

#### Scenario: 摘要未超限
- **WHEN** 帖子完整摘要不超过 120 字符
- **THEN** 全文 SHALL 原样显示，不做修改

#### Scenario: 摘要超限
- **WHEN** 帖子完整摘要超过 120 字符
- **THEN** 文本 SHALL 在 120 字符限制前的最后一个单词边界处截断
- **AND** SHALL 追加 "..."（省略号）表示截断
- **AND** 显示总长度 SHALL NOT 超过 123 字符（120 + "..."）

### Requirement: 精选帖子 API
系统 SHALL 提供 REST API 端点 `GET /api/posts/featured`，返回编辑策展的精选社区帖子列表。响应 SHALL 遵循项目统一的 `Result<T>` 信封格式。本区 SHALL 实现为 Client Component（`"use client"`，数据获取与 loading/error 状态所需）。

#### Scenario: 成功获取
- **WHEN** 前端请求 `GET /api/posts/featured`
- **THEN** API SHALL 返回 HTTP 200 与 `{ "code": 200, "message": "success", "data": [...] }`
- **AND** `data` 中每项 SHALL 为 `CommunityPost` 对象，包含 `id`、`authorName`、`authorAvatarUrl`、`title`、`excerpt`、`likeCount`

#### Scenario: 空数据
- **WHEN** API 返回空数组 `data`
- **THEN** 本区 SHALL 显示占位消息 "No community posts available yet" 而非帖子卡片

#### Scenario: API 错误
- **WHEN** API 请求失败（网络错误或服务器错误）
- **THEN** 本区 SHALL 显示错误消息 "Failed to load community posts" 及可重新触发获取的 "Retry" 按钮

#### Scenario: API 超时
- **WHEN** API 请求 10 秒内未收到响应
- **THEN** 本区 SHALL 将其视为失败请求
- **AND** SHALL 显示与 API 错误场景相同的错误消息与 Retry 按钮

#### Scenario: 加载状态
- **WHEN** API 请求进行中
- **THEN** 本区 SHALL 显示与帖子摘要布局尺寸一致的 skeleton 占位

### Requirement: 帖子点击导航
每条帖子摘要 SHALL 可点击，使用 Next.js `<Link>` 组件导航至帖子详情页。

#### Scenario: 帖子点击
- **WHEN** 用户点击 id 为 "42" 的帖子摘要
- **THEN** 浏览器 SHALL 导航至 `/community/posts/42`

### Requirement: 响应式布局
帖子摘要 SHALL 使用 Tailwind CSS mobile-first 断点前缀适配视口尺寸。

#### Scenario: 移动端布局
- **WHEN** 视口宽度小于 768px（Tailwind 默认基础样式）
- **THEN** 帖子 SHALL 全宽垂直堆叠
- **AND** 每条帖子 SHALL 具有一致的垂直间距（`space-y-4` 或等效）

#### Scenario: 桌面端布局
- **WHEN** 视口宽度为 768px 及以上（`md:` 断点）
- **THEN** 帖子 SHALL 水平排列（`md:grid md:grid-cols-3 lg:grid-cols-4 md:gap-6`）

### Requirement: 头像图片处理
每条帖子的用户头像 SHALL 使用 `next/image` 组件渲染。

#### Scenario: 头像加载成功
- **WHEN** 头像图片 URL 有效
- **THEN** 头像 SHALL 通过 `next/image` 以 `width={40}`、`height={40}` 显示为圆形图片（`rounded-full`）

#### Scenario: 头像加载失败
- **WHEN** 头像图片加载失败
- **THEN** 系统 SHALL 在圆形容器中显示通用用户图标占位（lucide-react 的 `User` 图标）

### Requirement: 点赞数格式化
点赞数 SHALL 以人类可读格式显示。

#### Scenario: 点赞数为零
- **WHEN** 帖子有 0 个赞
- **THEN** SHALL 显示精确数字 "0"

#### Scenario: 点赞数为负
- **WHEN** 帖子点赞数为负（数据异常）
- **THEN** 系统 SHALL 显示 "0" 而非负值

#### Scenario: 点赞数低于 1000
- **WHEN** 帖子有 1 至 999 个赞
- **THEN** SHALL 显示精确数字（如 "328"）

#### Scenario: 点赞数 1000 及以上
- **WHEN** 帖子有 1000 或更多赞
- **THEN** 数字 SHALL 以 "k" 后缀显示，保留一位小数（如 "1.2k"）
- **AND** 换算规则 SHALL 为 `Math.round(count / 100) / 10`（如 1999 → "2.0k"、9999 → "10.0k"）

### Requirement: 无障碍
社区区 SHALL 为屏幕阅读器用户提供可达的地标。

#### Scenario: 区域地标
- **WHEN** 社区区被渲染
- **THEN** 区域容器 SHALL 具有 `aria-label="Community highlights"`

#### Scenario: 帖子链接无障碍
- **WHEN** 帖子摘要被渲染
- **THEN** 帖子链接 SHALL 具有包含帖子标题的 `aria-label`（如 `aria-label="Read post: 3 Days in Chengdu"`）

## Data Structures

### CommunityPost

```typescript
interface CommunityPost {
  /** 唯一标识 */
  id: number;
  /** 作者显示名 */
  authorName: string; // 最大 50 字符
  /** 作者头像图片 URL */
  authorAvatarUrl: string; // 有效 URL
  /** 帖子标题 */
  title: string; // 最大 100 字符
  /** 帖子摘要 / 预览文本（由前端截断） */
  excerpt: string; // API 返回最大 500 字符；显示最大 123 字符（120 + "..."）
  /** 点赞数。API 可能返回负数（数据异常），前端钳制为 0 显示 */
  likeCount: number; // 整数
}
```

### CommunitySectionProps

```typescript
interface CommunitySectionProps {
  /** 无需 props — 数据在组件内部通过 API 获取 */
}
```

### API 响应（参考）

```typescript
// GET /api/posts/featured → Result<CommunityPost[]>
interface ApiPostsResponse {
  code: number;
  message: string;
  data: CommunityPost[];
}
```

## Acceptance Checklist

### 帖子展示
- [ ] 从 API 数据渲染 3–4 条社区帖子摘要
- [ ] 每条帖子显示：头像（`next/image`）、用户名、标题、摘要（截断）、点赞数
- [ ] API 返回 > 4 条 → 仅显示前 4 条
- [ ] API 返回 1–2 条 → 全部无错显示

### 摘要截断
- [ ] 摘要 ≤ 120 字符：全文显示
- [ ] 摘要 > 120 字符：单词边界截断 + 追加 "..."
- [ ] 显示总长度 ≤ 123 字符

### API 集成
- [ ] 组件挂载时调用 `GET /api/posts/featured`
- [ ] 响应遵循 `Result<T>` 信封格式
- [ ] 加载状态：显示 skeleton 占位
- [ ] 空状态：显示 "No community posts available yet"
- [ ] 错误状态：显示 "Failed to load community posts" + Retry 按钮
- [ ] 超时（> 10s）：按错误处理并显示 Retry 按钮

### 导航
- [ ] 帖子点击使用 Next.js `<Link>` 导航至 `/community/posts/{id}`

### 响应式
- [ ] 移动端（< 768px）：垂直堆叠、全宽、`space-y-4`
- [ ] 桌面端（≥ 768px）：`md:grid md:grid-cols-3 lg:grid-cols-4 md:gap-6`

### 头像
- [ ] 头像使用 `next/image`，`width={40} height={40}`、`rounded-full`
- [ ] 头像加载失败显示 lucide-react `User` 图标于圆形容器

### 点赞数
- [ ] 0 个赞 → 显示 "0"
- [ ] 负数 → 显示 "0"
- [ ] 1–999 个赞 → 精确数字（如 "328"）
- [ ] ≥ 1000 个赞 → "Xk" 格式（如 "1.2k"），换算 `Math.round(count/100)/10`

### 无障碍
- [ ] 区域具有 `aria-label="Community highlights"`
- [ ] 每条帖子链接具有 `aria-label="Read post: {title}"`

## Out of Scope

- 动态信息流（无限滚动或算法排序）
- 点赞的用户认证（首页点赞数为纯展示）
- 首页发帖或评论
- 点赞数实时更新
- 帖子图片缩略图（仅显示头像图片）
- 首页帖子分类或标签过滤
