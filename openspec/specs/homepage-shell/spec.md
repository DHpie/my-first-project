## Purpose

为 ChinaBuddy 首页提供页面骨架与路由入口。定义整体布局结构（header、主内容区、footer）以及各功能区域单元（hero、navigation、destinations、community）的挂载点（section slot）组合方式。本 spec 仅覆盖结构性骨架——不承载任何业务内容。AI widget 为 fixed 定位悬浮层，不占用 section slot 序列（其行为见 homepage-ai-widget spec）。

## In Scope

1. `/` 路由下的首页页面（Next.js App Router）
2. Sticky header：品牌 logo + AI assistant 导航链接
3. 有序 section slot 容器（Hero → Navigation → Destinations → Community）
4. Footer：版权文本 + 占位链接
5. Section slot 组合契约（用于组合子组件）
6. Skip-to-content 无障碍跳转链接
7. 响应式布局（Tailwind mobile-first 断点）

## Requirements

### Requirement: 首页路由
系统 SHALL 通过 Next.js App Router 页面在根路由 `/` 提供首页。

#### Scenario: 用户访问首页
- **WHEN** 用户导航至 `/`
- **THEN** 系统 SHALL 渲染首页布局，包含 `<header>`、带有序 section slot 的 `<main>` 内容区、`<footer>`
- **AND** 页面 SHALL 为 Server Component（无 `"use client"` 指令）

#### Scenario: 页面加载性能
- **WHEN** 首页被请求
- **AND** 请求经由标准宽带连接
- **THEN** 服务器 SHALL 在 1.5 秒内交付初始 HTML

### Requirement: 布局结构
首页 SHALL 由按以下自上而下顺序垂直排列的 section slot 组成：Hero、Navigation、Destinations、Community。

#### Scenario: Section 顺序
- **WHEN** 首页被渲染
- **THEN** 各 section SHALL 严格按以下顺序出现：Hero → Navigation → Destinations → Community
- **AND** 每个子组件 SHALL 自带 `aria-label` 属性以标注其语义

#### Scenario: 移动端布局
- **WHEN** 视口宽度小于 768px（Tailwind 默认基础样式）
- **THEN** 所有 section SHALL 以单列全宽垂直堆叠
- **AND** 内容容器 SHALL 具有 16px 水平内边距

#### Scenario: 桌面端布局
- **WHEN** 视口宽度为 768px 及以上（`md:` 断点）
- **THEN** 各 section SHALL 使用最大宽度 1200px 的居中内容容器
- **AND** 容器 SHALL 使用 `mx-auto` 实现水平居中

### Requirement: Header 区
首页 SHALL 包含一个 sticky header，内含品牌 logo（文本形式）与指向 AI assistant 的导航链接。

#### Scenario: 滚动时 Header 可见
- **WHEN** 用户向下滚动页面
- **THEN** header SHALL 保持在视口顶部可见（`sticky top-0 z-50`）
- **AND** header SHALL 具有 64px 的固定高度

#### Scenario: Header 不遮挡内容
- **WHEN** 首页被渲染
- **THEN** `<main>` 内容区 SHALL 具有等于或大于 header 高度（64px）的 `padding-top`，防止内容被 sticky header 遮挡

#### Scenario: 品牌 logo 点击
- **WHEN** 用户点击品牌 logo
- **THEN** 浏览器 SHALL 导航至 `/`

#### Scenario: AI assistant 链接点击
- **WHEN** 用户点击 header 中的 AI assistant 导航链接
- **AND** AI widget（悬浮按钮）已挂载于页面
- **THEN** AI widget 的迷你对话窗 SHALL 打开
- **AND** 焦点 SHALL 移至对话窗的消息输入框

#### Scenario: Header 层级
- **WHEN** 滚动过程中 header 与页面内容重叠
- **THEN** header SHALL 具有高于所有 section 内容的 `z-index`
- **AND** header SHALL 具有不透明背景色，防止内容透出

### Requirement: Footer 区
首页 SHALL 包含一个 footer，内含版权文本与 "About"、"Contact"、"Privacy Policy" 三个占位链接。

#### Scenario: Footer 内容
- **WHEN** 首页被渲染
- **THEN** footer SHALL 显示 "© 2026 ChinaBuddy. All rights reserved." 与三个导航链接

#### Scenario: Footer 占位链接
- **WHEN** 用户点击 "About"、"Contact" 或 "Privacy Policy" 任一链接
- **AND** 目标页面尚未实现（MVP）
- **THEN** 系统 SHALL 导航至显示 "Coming soon" 的占位页面
- **AND** 占位页面 SHALL 提供返回首页的链接

### Requirement: Section Slot 契约
每个 section slot SHALL 接受一个自包含的 React 组件作为子组件。shell SHALL NOT 对 section 组件施加任何数据获取或业务逻辑。

#### Scenario: Slot 渲染子组件
- **WHEN** 某 section 组件被提供给 slot
- **THEN** shell SHALL 原样渲染该组件，不做任何修改

#### Scenario: 缺少 section 组件
- **WHEN** 某 slot 未提供 section 组件（如开发期间）
- **THEN** shell SHALL 为该 slot 渲染空内容且不报错
- **AND** 周边布局 SHALL NOT 意外折叠或偏移

### Requirement: 无障碍
首页骨架 SHALL 通过语义化 HTML 与 skip navigation 提供基线无障碍支持。

#### Scenario: 语义化地标
- **WHEN** 首页被渲染
- **THEN** 页面 SHALL 恰好包含一个 `<header>` 地标、一个 `<main>` 地标和一个 `<footer>` 地标

#### Scenario: Skip-to-content 链接
- **WHEN** 键盘用户首次 Tab 进入页面
- **THEN** 视觉隐藏的 "Skip to main content" 链接 SHALL 作为第一个可聚焦元素获得焦点
- **AND** 激活该链接 SHALL 将焦点移至 `<main>` 元素

## Data Structures

### HomePageProps

```typescript
interface HomePageProps {
  /** 静态骨架页面无需 props。
   *  Section 组件在页面文件中直接导入并组合。
   *  此接口为未来扩展预留（如 feature flags）。 */
}
```

### SectionSlotProps

shell 不提供额外的 slot 包装组件。各子组件（Hero、Navigation、Destinations、Community）直接导入并在页面文件中渲染，每个子组件负责自带 `<section aria-label="...">` 等无障碍属性。

## Acceptance Checklist

### 路由与结构
- [ ] 首页通过 Next.js App Router Server Component 服务于 `/`
- [ ] 页面使用语义化地标：`<header>`、`<main>`、`<footer>`
- [ ] 标准宽带下初始 HTML 在 1.5s 内交付

### Header
- [ ] Header 为 sticky（`sticky top-0 z-50`），固定高度 64px
- [ ] Header 具有不透明背景色，防止内容透出
- [ ] `<main>` 的 `padding-top` ≥ 64px，避免内容被遮挡
- [ ] 点击品牌 logo 导航至 `/`
- [ ] 点击 AI assistant 链接打开 AI widget 对话窗，焦点移至输入框

### Section Slots
- [ ] Section 按顺序渲染：Hero → Navigation → Destinations → Community
- [ ] 每个子组件自带 `aria-label` 属性（由各子组件 spec 负责）
- [ ] 缺少 section 组件时渲染空内容且布局不折叠

### Footer
- [ ] Footer 显示 "© 2026 ChinaBuddy. All rights reserved."
- [ ] Footer 包含 "About"、"Contact"、"Privacy Policy" 链接
- [ ] 占位链接在 MVP 阶段导航至 "Coming soon" 页面

### 响应式
- [ ] 移动端（< 768px）：单列、全宽、16px 水平内边距
- [ ] 桌面端（≥ 768px）：居中容器、最大宽度 1200px、`mx-auto`

### 无障碍
- [ ] "Skip to main content" 链接是第一个可聚焦元素
- [ ] 激活 skip 链接将焦点移至 `<main>`
- [ ] 页面恰好存在一个 `<header>`、一个 `<main>`、一个 `<footer>` 地标

## Out of Scope

- 视觉设计 tokens（颜色、字体、间距）— 属于样式基础设施职责
- 任何 section 的业务内容 — 属于各功能区域 spec 职责
- AI widget 本身 — 属于 homepage-ai-widget spec 职责（widget 为 fixed 悬浮层，不占用 section slot）
- 认证与用户会话管理
- 初始页面加载之外的 SSR 优化
- Header 之外的全局导航菜单（无汉堡菜单、无 mega menu）
- Cookie 同意横幅或 GDPR 合规 UI
- 国际化（i18n）/ 多语言切换
