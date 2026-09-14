## Context

当前 `frontend/src/app/page.tsx` 中 Navigation Section 区域为占位注释（`{/* Navigation Section */}`）。`homepage-shell` 变更已实现页面骨架，main 容器已就绪。`frontend/package.json` 已确认安装 `lucide-react@^1.44.0`，提供 `Users`、`Map`、`Bot`、`Globe` 图标。本区域为纯静态 Server Component，无需客户端状态或 API 调用。

## Goals / Non-Goals

**Goals:**
- 在 `page.tsx` 的 Navigation Section 占位处集成 NavigationSection 组件
- 实现三张平台入口卡片（Travel Community、Attraction Guides、AI Assistant），每张含图标 + 标题 + 描述
- 卡片使用 Next.js `<Link>` 实现客户端导航至对应路由
- 响应式布局与悬停/聚焦/触摸视觉反馈

**Non-Goals:**
- 动态卡片内容或个性化推荐
- 卡片拖拽排序或动态数量
- 外部 URL 导航（所有导航均为站内）

## Decisions

### 1. 纯 Server Component 实现

**决策:** NavigationSection 作为纯 Server Component 实现，不使用 `"use client"`。

**理由:**
- 导航区仅包含静态内容（图标、文本）和 `<Link>` 导航，无需客户端状态
- Next.js `<Link>` 在服务端组件中自动处理客户端导航，无需额外交互逻辑
- 保持零客户端 JS，最大化首屏性能

**替代方案:** 使用 Client Component + `onClick` — rejected，`<Link>` 在服务端组件中已提供完整的客户端导航能力，无需额外 JS。

### 2. 卡片数据结构：静态数组常量

**决策:** 三张卡片数据定义为组件文件内的静态 TypeScript 数组常量（`NavigationCard[]`），而非外部配置或 API 获取。

**理由:**
- 卡片内容固定（恰好 3 张），无动态变化需求
- 静态常量避免不必要的运行时开销
- 类型安全：`NavigationCard` 接口约束图标类型联合 `"Users" | "Map" | "Bot"`

**替代方案:** 从 API 获取卡片数据 — rejected，spec 明确固定 3 张卡片，API 层引入无价值。

### 3. 图标回退策略

**决策:** 使用 try/catch 包裹图标渲染，失败时回退至 `Globe` 图标。

**理由:**
- lucide-react 图标为纯组件导入，运行时失败概率极低但需防御
- `Globe` 图标语义通用，适合作为导航类图标的回退

**替代方案:** 不处理图标失败 — rejected，spec 明确要求回退行为。

### 4. 文件位置

**决策:** `frontend/src/components/navigation/navigation-section.tsx`

**理由:** 按功能区域组织组件目录，与 homepage-hero 的 `components/hero/` 保持一致的命名风格。

## Risks / Trade-offs

- **[目标路由尚未实现]** → `/community`、`/attractions`、`/ai-assistant` 路由在 MVP 阶段导航至 Next.js 内置 404 页面，spec 明确可接受。各平台页面由独立 spec 实现。
- **[图标导入失败]** → 回退至 `Globe` 图标，卡片布局不偏移。lucide-react 为成熟库，实际风险极低。
