## Context

当前 `frontend/src/app/page.tsx` 中 Hero Section 区域为占位注释（`{/* Hero Section */}`）。`homepage-shell` 变更已实现页面骨架（header、main、footer），main 容器已就绪。`frontend/package.json` 已确认安装 `next@^15.0.0`、`react@^19.2.8`、`lucide-react@^1.44.0`、`shadcn@^4.21.0`，以及 `@/components/ui/input.tsx` 和 `@/components/ui/button.tsx` 组件可用。

## Goals / Non-Goals

**Goals:**
- 在 `page.tsx` 的 Hero Section 占位处集成 HeroSection 组件
- 实现背景图（next/image）+ 品牌标题/副标题 + 搜索框的完整 Hero 区
- 搜索表单作为嵌套 Client Component，实现提交导航与输入校验

**Non-Goals:**
- 搜索结果页实现（属于独立搜索 spec）
- 背景图 CMS 管理或动态切换
- 搜索建议/自动补全

## Decisions

### 1. 组件拆分：HeroSection（Server Component）+ SearchForm（Client Component）

**决策:** HeroSection 作为 Server Component 实现，内部嵌套 SearchForm 作为 `"use client"` Client Component。

**理由:**
- HeroSection 的内容（背景图 URL、标题、副标题）均为静态数据，无需客户端状态，保持 Server Component 最大化服务端渲染优势
- SearchForm 需要管理输入状态、校验逻辑、导航触发，必须为 Client Component
- 嵌套 Client Component 模式是 Next.js App Router 推荐做法，最小化客户端 JS 体积

**替代方案:** 将 HeroSection 整体设为 Client Component —  rejected，因为会将不必要的服务端可渲染内容推至客户端。

### 2. 背景图实现：next/image fill + onError 回退

**决策:** 使用 `next/image` 的 `fill` prop 实现全宽背景图，通过 `onError` 回调切换至纯色回退背景。

**理由:**
- `fill` + 父容器 `relative` 是 next/image 官方推荐的全屏图片方案
- `priority` prop 确保 LCP 元素预加载
- `onError` 回调设置状态切换容器背景色为 `#1a1a2e`，保持前景内容可读

**替代方案:** CSS `background-image` — rejected，无法利用 next/image 的自动优化（WebP/AVIF 转换、响应式 srcset）。

### 3. 搜索表单导航：useRouter + URL 参数

**决策:** SearchForm 使用 Next.js `useRouter` 的 `router.push()` 导航至 `/search?q={query}`。

**理由:**
- `router.push()` 提供客户端导航，避免全页刷新
- URL 参数传递查询是最简洁的跨页面数据共享方式
- 防重复提交通过 `isNavigating` 状态标志实现

**替代方案:** `<form action>` + Server Action — rejected，搜索导航是纯客户端行为，无需服务端处理。

### 4. 文件位置

**决策:**
- `frontend/src/components/hero/hero-section.tsx` — HeroSection Server Component
- `frontend/src/components/hero/search-form.tsx` — SearchForm Client Component

**理由:** 按功能区域组织组件目录，与 homepage-shell 的 `components/layout/` 保持一致的命名风格（kebab-case 文件名）。

## Risks / Trade-offs

- **[背景图资源缺失]** → `onError` 回退至 `#1a1a2e` 纯色，所有前景内容保持可见可读。需在实施时确认 `hero.png` 已放置于 `public/` 目录。
- **[搜索目标路由 /search 尚未实现]** → MVP 阶段导航至 404 可接受，后续由搜索 spec 实现。
- **[SearchForm 客户端 JS 体积]** → 仅包含输入状态管理 + 导航逻辑，体积可控。lucide-react 的 Search 图标通过 tree-shaking 仅打包所需图标。
