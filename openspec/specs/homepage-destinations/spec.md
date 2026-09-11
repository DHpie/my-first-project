## Purpose

为 ChinaBuddy 首页提供热门目的地推荐区——4–6 张目的地卡片的网格，通过封面图、城市名、一行亮点与热度标签展示热门城市。本区帮助首次访问的用户快速了解应用价值（US-H1）。

## In Scope

1. 目的地卡片网格展示（4–6 张）
2. `GET /api/destinations/featured` API 集成，含 loading/error/empty 状态
3. 卡片点击导航至城市详情页
4. 封面图渲染（`next/image`）与失败回退
5. 响应式布局（Tailwind mobile-first 断点）

## Requirements

### Requirement: 目的地卡片展示
本区 SHALL 显示 4 至 6 张目的地卡片，每张代表一个热门城市。

#### Scenario: 卡片内容
- **WHEN** 目的地区带数据渲染
- **THEN** 每张卡片 SHALL 显示：封面图（`next/image`）、城市名（`<h3>`）、一行亮点文本、热度标签（如 "Hot"、"Trending"、"Editor's Pick"）

#### Scenario: 卡片数量在范围内
- **WHEN** API 返回 N 个目的地（4 ≤ N ≤ 6）
- **THEN** 本区 SHALL 恰好渲染 N 张卡片

#### Scenario: 卡片数量超上限
- **WHEN** API 返回超过 6 个目的地
- **THEN** 本区 SHALL 仅渲染前 6 张卡片并忽略其余

#### Scenario: 卡片数量低于预期范围
- **WHEN** API 返回 1 至 3 个目的地
- **THEN** 本区 SHALL 无错渲染全部可用卡片

### Requirement: 精选目的地 API
系统 SHALL 提供 REST API 端点 `GET /api/destinations/featured`，返回编辑策展的精选目的地列表。响应 SHALL 遵循项目统一的 `Result<T>` 信封格式。本区 SHALL 实现为 Client Component（`"use client"`，数据获取与 loading/error 状态所需）。

#### Scenario: 成功获取
- **WHEN** 前端请求 `GET /api/destinations/featured`
- **THEN** API SHALL 返回 HTTP 200 与 `{ "code": 200, "message": "success", "data": [...] }`
- **AND** `data` 中每项 SHALL 为 `Destination` 对象，包含 `id`、`cityName`、`slug`、`highlight`、`coverImageUrl`、`popularityTag`

#### Scenario: 空数据
- **WHEN** API 返回空数组 `data`
- **THEN** 本区 SHALL 显示占位消息 "No destinations available at the moment" 而非卡片

#### Scenario: API 错误
- **WHEN** API 请求失败（网络错误或服务器错误）
- **THEN** 本区 SHALL 显示错误消息 "Failed to load destinations" 及可重新触发获取的 "Retry" 按钮

#### Scenario: API 超时
- **WHEN** API 请求 10 秒内未收到响应
- **THEN** 本区 SHALL 将其视为失败请求
- **AND** SHALL 显示与 API 错误场景相同的错误消息与 Retry 按钮

#### Scenario: 加载状态
- **WHEN** API 请求进行中
- **THEN** 本区 SHALL 显示与卡片布局尺寸一致的 skeleton 占位卡片（280px × 200px）

### Requirement: 卡片点击导航
每张目的地卡片 SHALL 可点击，使用 Next.js `<Link>` 组件导航至城市详情页。

#### Scenario: 卡片点击
- **WHEN** 用户点击 slug 为 "chengdu" 的目的地卡片
- **THEN** 浏览器 SHALL 导航至 `/destinations/chengdu`
- **AND** slug SHALL 直接取自 API 响应的 `slug` 字段（不在客户端派生）

### Requirement: 响应式布局
目的地卡片 SHALL 使用 Tailwind CSS mobile-first 断点前缀适配视口尺寸。

#### Scenario: 移动端布局
- **WHEN** 视口宽度小于 768px（Tailwind 默认基础样式）
- **THEN** 卡片 SHALL 以横向可滚动单行显示（`flex overflow-x-auto snap-x snap-mandatory`）
- **AND** 每张卡片 SHALL 占视口宽度 80%（一次约可见 1.2 张卡片）

#### Scenario: 桌面端布局
- **WHEN** 视口宽度为 768px 及以上（`md:` 断点）
- **THEN** 卡片 SHALL 以网格显示（`md:grid md:grid-cols-4 md:gap-6`）
- **AND** 卡片数超过 4 张时，其余卡片 SHALL 换行至第二行显示，全部可见（无横向滚动）

### Requirement: 图片加载
每张卡片的封面图 SHALL 使用 `next/image` 组件渲染以获得自动优化。

#### Scenario: 图片加载成功
- **WHEN** 封面图 URL 有效并加载成功
- **THEN** 图片 SHALL 通过 `next/image` 以 `fill` prop 与 `object-fit: cover` 渲染
- **AND** 图片容器 SHALL 使用 `relative` 定位与固定宽高比（4:3）

#### Scenario: 图片加载失败
- **WHEN** 封面图加载失败
- **THEN** 卡片 SHALL 显示渐变占位背景，并叠加白色城市名文本

### Requirement: 无障碍
目的地区 SHALL 为屏幕阅读器用户提供可达的地标。

#### Scenario: 区域地标
- **WHEN** 目的地区被渲染
- **THEN** 区域容器 SHALL 具有 `aria-label="Featured destinations"`

#### Scenario: 卡片链接无障碍
- **WHEN** 目的地卡片被渲染
- **THEN** 卡片链接 SHALL 具有 `aria-label="Explore {cityName}"`（如 "Explore Chengdu"）

## Data Structures

### Destination

```typescript
interface Destination {
  /** 唯一标识 */
  id: number;
  /** 城市显示名 */
  cityName: string; // 最大 50 字符
  /** 路由用 URL 安全 slug（由 API 提供，不在客户端派生） */
  slug: string; // 如 "chengdu"、"xi-an"
  /** 一行亮点文本 */
  highlight: string; // 最大 100 字符
  /** 封面图 URL */
  coverImageUrl: string; // 有效 URL
  /** 热度标签文本 */
  popularityTag: string; // 如 "Hot"、"Trending"、"Editor's Pick" | 最大 20 字符
}
```

### DestinationsSectionProps

```typescript
interface DestinationsSectionProps {
  /** 无需 props — 数据在组件内部通过 API 获取 */
}
```

### API 响应（参考）

```typescript
// GET /api/destinations/featured → Result<Destination[]>
interface ApiDestinationsResponse {
  code: number;
  message: string;
  data: Destination[];
}
```

## Acceptance Checklist

### 卡片展示
- [ ] 从 API 数据渲染 4–6 张目的地卡片
- [ ] 每张卡片显示：封面图（`next/image`）、城市名（`<h3>`）、亮点、热度标签
- [ ] API 返回 > 6 项 → 仅显示前 6 张
- [ ] API 返回 1–3 项 → 全部无错显示

### API 集成
- [ ] 组件挂载时调用 `GET /api/destinations/featured`
- [ ] 响应遵循 `Result<T>` 信封格式
- [ ] 加载状态：显示 skeleton 卡片（280px × 200px）
- [ ] 空状态：显示 "No destinations available at the moment"
- [ ] 错误状态：显示 "Failed to load destinations" + Retry 按钮
- [ ] 超时（> 10s）：按错误处理并显示 Retry 按钮

### 导航
- [ ] 卡片点击使用 Next.js `<Link>` 导航至 `/destinations/{slug}`
- [ ] slug 取自 API 响应 `slug` 字段（非客户端派生）

### 响应式
- [ ] 移动端（< 768px）：横向滚动、`snap-x`、卡片占 80% 视口宽
- [ ] 桌面端（≥ 768px）：`md:grid md:grid-cols-4 md:gap-6`，超过 4 张换行显示

### 图片
- [ ] 封面图使用 `next/image`，`fill` prop + `object-fit: cover`
- [ ] 图片容器宽高比 4:3
- [ ] 图片加载失败显示渐变占位 + 城市名

### 无障碍
- [ ] 区域具有 `aria-label="Featured destinations"`
- [ ] 每张卡片链接具有 `aria-label="Explore {cityName}"`

## Out of Scope

- 基于算法的目的地推荐或用户个性化排序
- 无限滚动或分页 — 列表为固定编辑策展集合
- 目的地详情页内容 — 属于独立 spec
- 目的地卡片上的用户评价或评分
- 客户端 slug 生成（slug 由 API 提供）
- 图片懒加载策略定制（委托给 `next/image` 默认值）
