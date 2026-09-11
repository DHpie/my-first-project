## Purpose

为 ChinaBuddy 首页提供功能导航区——三张平台入口卡片，将用户引导至三大核心产品区域：Travel Community（旅行社区）、Attraction Guides（景点攻略）与 AI Assistant（AI 助手）。每张卡片通过图标、标题与一行描述传达其目的地。本区实现为静态 Server Component（无 `"use client"`，除 `<a>` 导航外无交互逻辑）。

## In Scope

1. 三张平台入口卡片（Travel Community、Attraction Guides、AI Assistant）
2. 每张卡片包含图标 + 标题 + 描述
3. 卡片点击导航至对应平台路由
4. 响应式布局（Tailwind mobile-first 断点）
5. 悬停 / 聚焦 / 触摸视觉反馈

## Requirements

### Requirement: 三张平台卡片
导航区 SHALL 恰好显示三张卡片，每张代表一个平台入口。

#### Scenario: 卡片内容
- **WHEN** 导航区被渲染
- **THEN** 它 SHALL 显示三张卡片，内容如下：
  1. **Travel Community** — lucide-react 的 `Users` 图标 + 标题 "Travel Community" + 描述 "Share experiences and discover hidden gems from fellow travelers"
  2. **Attraction Guides** — lucide-react 的 `Map` 图标 + 标题 "Attraction Guides" + 描述 "Curated guides for China's top destinations and hidden treasures"
  3. **AI Assistant** — lucide-react 的 `Bot` 图标 + 标题 "AI Assistant" + 描述 "Plan your trip with personalized AI-powered recommendations"

#### Scenario: 卡片结构
- **WHEN** 每张卡片被渲染
- **THEN** 它 SHALL 按垂直顺序包含：图标（lucide-react）、标题（`<h3>`）、一行描述（`<p>`）
- **AND** 卡片 SHALL 包裹在 `<a>` 元素中，保留原生导航语义

#### Scenario: 图标渲染失败
- **WHEN** 某 lucide-react 图标渲染失败（如导入错误）
- **THEN** 卡片 SHALL 显示 lucide-react 的 `Globe` 图标作为回退
- **AND** 卡片布局 SHALL NOT 偏移或折叠

### Requirement: 卡片点击导航
每张卡片 SHALL 可点击，使用 Next.js `<Link>` 组件进行客户端导航至对应平台区域。

#### Scenario: Travel Community 卡片点击
- **WHEN** 用户点击 Travel Community 卡片
- **THEN** 浏览器 SHALL 导航至 `/community`

#### Scenario: Attraction Guides 卡片点击
- **WHEN** 用户点击 Attraction Guides 卡片
- **THEN** 浏览器 SHALL 导航至 `/attractions`

#### Scenario: AI Assistant 卡片点击
- **WHEN** 用户点击 AI Assistant 卡片
- **THEN** 浏览器 SHALL 导航至 `/ai-assistant`

#### Scenario: 目标路由尚未实现
- **WHEN** 用户点击某卡片且目标路由尚未实现（MVP）
- **THEN** Next.js SHALL 渲染内置 404 页面
- **AND** MVP 阶段可接受；各平台页面将由独立 spec 实现

#### Scenario: 键盘可达性
- **WHEN** 用户 Tab 至卡片并按下 Enter
- **AND** 卡片渲染为带有效 `href` 的 `<a>` 元素
- **THEN** 卡片 SHALL 像鼠标点击一样触发导航

### Requirement: 响应式布局
三张卡片 SHALL 使用 Tailwind CSS mobile-first 断点前缀适配视口尺寸。

#### Scenario: 移动端布局
- **WHEN** 视口宽度小于 768px（Tailwind 默认基础样式）
- **THEN** 三张卡片 SHALL 全宽垂直堆叠
- **AND** 每张卡片 SHALL 具有一致的垂直间距（`space-y-4` 或等效）

#### Scenario: 桌面端布局
- **WHEN** 视口宽度为 768px 及以上（`md:` 断点）
- **THEN** 三张卡片 SHALL 水平排列（`md:flex md:gap-6`）
- **AND** 每张卡片 SHALL 等宽（`flex-1`）

### Requirement: 视觉反馈
每张卡片 SHALL 使用 Tailwind CSS 过渡工具类提供交互反馈，表明其可点击。

#### Scenario: 悬停状态
- **WHEN** 用户使用指针设备悬停于卡片
- **THEN** 卡片 SHALL 在 200ms 内显示视觉变化（如 `hover:shadow-lg` 或 `hover:scale-[1.02]`，配合 `transition-all duration-200`）

#### Scenario: 聚焦状态
- **WHEN** 卡片获得键盘焦点
- **THEN** 卡片 SHALL 显示可见焦点环（`focus-visible:ring-2 focus-visible:ring-offset-2`）

#### Scenario: 触摸按下状态
- **WHEN** 用户在触摸设备上按下卡片
- **THEN** 卡片 SHALL 显示视觉变化（如 `active:scale-[0.98]`）提供触觉反馈

## Data Structures

### NavigationCard

```typescript
interface NavigationCard {
  /** 卡片唯一标识 */
  id: string;
  /** lucide-react 图标组件名 */
  icon: "Users" | "Map" | "Bot";
  /** 卡片标题文本（最大 50 字符） */
  title: string;
  /** 一行描述文本（最大 100 字符） */
  description: string;
  /** 目标路由路径 */
  href: string;
}
```

### NavigationSectionProps

```typescript
interface NavigationSectionProps {
  /** 导航卡片数组 — 必须恰好包含 3 项 */
  cards: NavigationCard[]; // 约束: length === 3
}
```

## Acceptance Checklist

### 卡片内容
- [ ] 恰好渲染 3 张卡片：Travel Community、Attraction Guides、AI Assistant
- [ ] 每张卡片使用 lucide-react 图标：`Users`、`Map`、`Bot`
- [ ] 每张卡片按垂直顺序包含图标 → 标题（`<h3>`）→ 描述（`<p>`）
- [ ] 图标渲染失败回退至 `Globe` 图标且布局不偏移

### 导航
- [ ] Travel Community 卡片导航至 `/community`
- [ ] Attraction Guides 卡片导航至 `/attractions`
- [ ] AI Assistant 卡片导航至 `/ai-assistant`
- [ ] 导航使用 Next.js `<Link>` 客户端路由
- [ ] 键盘 Tab + Enter 可触发导航

### 响应式
- [ ] 移动端（< 768px）：卡片垂直堆叠、全宽、`space-y-4`
- [ ] 桌面端（≥ 768px）：卡片水平排列、`md:flex md:gap-6`、等宽

### 视觉反馈
- [ ] 悬停：`hover:shadow-lg` 或 `hover:scale-[1.02]`，配合 `transition-all duration-200`
- [ ] 聚焦：`focus-visible:ring-2 focus-visible:ring-offset-2`
- [ ] 触摸：`active:scale-[0.98]`

## Out of Scope

- 动态卡片内容或个性化推荐
- 链接至外部 URL 的卡片（所有导航均为站内）
- 悬停/聚焦/按下过渡之外的动画
- 卡片拖拽排序
- 动态卡片数量（固定恰好 3 张）
- 卡片角标或 "New" 标识
