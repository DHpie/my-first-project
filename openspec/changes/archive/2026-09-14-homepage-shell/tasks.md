## 1. 项目结构搭建

- [x] 1.1 创建 `frontend/src/components/layout/` 目录，创建空文件 `header.tsx`、`footer.tsx`、`skip-to-content.tsx`，验证目录和文件存在
- [x] 1.2 创建 `frontend/src/app/coming-soon/` 目录和空文件 `page.tsx`，验证目录和文件存在

## 2. Skip-to-content 无障碍组件

- [x] 2.1 实现 `skip-to-content.tsx` 为 Client Component（`"use client"`），包含视觉隐藏的 "Skip to main content" 链接，使用 `onClick` + `useRef` 将焦点程序化移至 `<main id="main-content">` 元素，验证：Tab 键可聚焦该链接，激活后焦点移至 `<main>`
- [x] 2.2 确认 skip-to-content 链接使用 `sr-only` + `focus:not-sr-only` 模式（默认视觉隐藏，聚焦时可见），验证：聚焦时链接文本可见

## 3. Header 组件

- [x] 3.1 实现 `header.tsx` 为 Server Component，包含 sticky 定位（`sticky top-0 z-50`）、固定高度 64px、不透明背景色，验证：`npm run build` 通过且组件无 TypeScript 错误
- [x] 3.2 在 header 中实现品牌 logo 文本链接（`<a href="/">`），点击导航至 `/`，验证：渲染为有效 `<a>` 元素且 `href="/"`
- [x] 3.3 在 header 中实现 AI assistant 导航链接（`<a href="#ai-assistant">`），添加 TODO 注释标注待 `homepage-ai-widget` 变更实现交互逻辑，验证：渲染为有效 `<a>` 元素
- [x] 3.4 实现 header 响应式布局：移动端全宽，桌面端内容容器 max-width 1200px + `mx-auto`，验证：Tailwind 类名正确应用于组件

## 4. Footer 组件

- [x] 4.1 实现 `footer.tsx` 为 Server Component，显示版权文本 "© 2026 ChinaBuddy. All rights reserved."，验证：`npm run build` 通过且文本正确渲染
- [x] 4.2 在 footer 中实现三个占位链接："About"、"Contact"、"Privacy Policy"，均导航至 `/coming-soon`，验证：三个 `<a>` 元素 `href` 均为 `/coming-soon`
- [x] 4.3 实现 footer 响应式布局：移动端垂直堆叠，桌面端水平排列，验证：Tailwind 类名正确应用于组件

## 5. Coming Soon 占位页面

- [x] 5.1 实现 `coming-soon/page.tsx` 为 Server Component，显示 "Coming soon" 标题文本和返回首页链接（`<a href="/">`），使用 Tailwind 居中布局，验证：访问 `/coming-soon` 显示 "Coming soon" 文本且链接可导航回 `/`

## 6. 根布局更新

- [x] 6.1 更新 `layout.tsx` 的 metadata：title 改为 "ChinaBuddy"，description 改为 "Discover China Like a Local"，验证：页面 HTML `<title>` 标签包含 "ChinaBuddy"
- [x] 6.2 在 `layout.tsx` 的 `<body>` 中为 `<main>` 目标预留 `id="main-content"` 的约定（在 `page.tsx` 中实现），验证：`layout.tsx` 无 TypeScript 错误

## 7. 首页组合

- [x] 7.1 重写 `page.tsx` 为 Server Component（移除 `redirect('/users')`），导入并组合 `SkipToContent`、`Header`、`Footer` 组件，实现语义化地标结构：`<SkipToContent />` → `<Header />` → `<main id="main-content" pt-[64px]>` → `<Footer />`，验证：`npm run build` 通过
- [x] 7.2 在 `<main>` 内添加 section slot 注释占位标记（`{/* Hero Section */}`、`{/* Navigation Section */}`、`{/* Destinations Section */}`、`{/* Community Section */}`），设置 `min-h-[50vh]` 防止布局折叠，验证：页面渲染无空白错误且 `<main>` 有最小高度
- [x] 7.3 实现 `<main>` 内容区响应式容器：移动端 `px-4`（16px），桌面端 `md:max-w-[1200px] md:mx-auto`，验证：Tailwind 类名正确应用

## 8. 构建验证与集成测试

- [x] 8.1 运行 `npm run build` 验证全量构建通过（无 TypeScript 错误、无编译错误），验证：命令退出码为 0
- [x] 8.2 运行 `npm run lint` 验证无 lint 错误，验证：命令退出码为 0
- [x] 8.3 运行 `npx tsc --noEmit` 验证类型检查通过，验证：命令退出码为 0
- [x] 8.4 启动 `npm run dev`，手动验证：访问 `/` 显示首页骨架（header + main + footer），访问 `/coming-soon` 显示占位页面，验证：两个路由均正常渲染
