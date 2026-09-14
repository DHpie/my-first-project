## Why

当前首页 `frontend/src/app/page.tsx` 是一个重定向桩——将 `/` 路由直接 redirect 到 `/users`，不包含任何首页骨架。`homepage-shell` spec 已定义了完整的页面结构（sticky header、有序 section slot 容器、footer、skip-to-content 无障碍链接、响应式布局），但代码层面尚未实现。本变更将 spec 落地为首个可运行的 Server Component 页面骨架，为后续 5 个 homepage 功能区域（hero、navigation、destinations、community、ai-widget）的集成提供挂载基础。

## What Changes

- 移除 `page.tsx` 的 redirect 桩，替换为 Next.js App Router Server Component 首页
- 实现 sticky header：品牌 logo（文本）+ AI assistant 导航链接，固定高度 64px，`sticky top-0 z-50`，不透明背景
- 实现 `<main>` 内容区，带 `padding-top ≥ 64px` 防止被 header 遮挡
- 实现有序 section slot 容器：Hero → Navigation → Destinations → Community（本阶段各 slot 渲染空内容占位，布局不折叠）
- 实现 footer：版权文本 "© 2026 ChinaBuddy. All rights reserved." + 三个占位链接（About、Contact、Privacy Policy）
- 实现 skip-to-content 无障碍跳转链接（第一个可聚焦元素，激活后焦点移至 `<main>`）
- 实现响应式布局：移动端单列全宽 16px 水平内边距，桌面端居中容器 max-width 1200px
- 占位链接导航至 "Coming soon" 占位页面

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- `homepage-shell`：从 redirect 桩变为完整页面骨架实现——覆盖 header、section slot 容器、footer、skip-to-content、响应式布局的全部 spec 要求

## Impact

**代码**：
- `frontend/src/app/page.tsx`：完全重写（移除 redirect，实现首页骨架）
- `frontend/src/app/layout.tsx`：更新 metadata（title/description 对齐 ChinaBuddy 品牌）
- `frontend/src/components/layout/header.tsx`：新增（sticky header 组件）
- `frontend/src/components/layout/footer.tsx`：新增（footer 组件）
- `frontend/src/components/layout/skip-to-content.tsx`：新增（无障碍跳转链接）
- `frontend/src/app/coming-soon/page.tsx`：新增（占位页面）

**依赖**：无新增依赖。Tailwind CSS v4、shadcn/ui、lucide-react 已在 `introduce-frontend-styling-infra` 变更中安装。

**前置依赖**：
- `introduce-frontend-styling-infra` 变更（Tailwind CSS + shadcn/ui + lucide-react 已安装并验证构建管线）

**后续依赖**：
- 本变更完成后，`homepage-hero`、`homepage-navigation`、`homepage-destinations`、`homepage-community`、`homepage-ai-widget` 五个功能区域变更方可进入实施
