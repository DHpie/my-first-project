## Why

当前首页 `frontend/src/app/page.tsx` 的 Hero Section 区域仅为占位注释（`{/* Hero Section */}`），尚未实现任何视觉内容。`homepage-hero` spec 已定义了完整的 Hero 区需求——品牌背景图、主标题、副标题、搜索输入框、响应式布局与首屏性能约束——但代码层面尚未落地。本变更将 spec 落地为可运行的 Hero 区组件，作为首页首个可见的业务内容区域，为访客提供品牌第一印象与搜索入口。

## What Changes

- 新增 Hero 区 Server Component 组件（`frontend/src/components/sections/hero-section.tsx`），包含背景图、标题、副标题
- 新增嵌套 Client Component 搜索表单（`frontend/src/components/sections/search-form.tsx`），实现搜索输入、校验、导航跳转
- 在 `page.tsx` 中导入并渲染 Hero 区组件，替换现有占位注释
- 背景图使用 `next/image` 的 `fill` + `priority` prop，含 `#1a1a2e` 纯色回退
- 搜索表单实现空输入/纯空白/超长输入/XSS 防护/防重复提交等异常路径
- 响应式布局：移动端垂直堆叠 300px 最小高度，桌面端居中 500px 最小高度

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- `homepage-hero`：从占位注释变为完整 Hero 区实现——覆盖背景图、标题、副标题、搜索输入框、响应式布局、首屏性能的全部 spec 要求

## Impact

**代码**：
- `frontend/src/app/page.tsx`：导入 HeroSection 组件，替换 `{/* Hero Section */}` 占位注释
- `frontend/src/components/sections/hero-section.tsx`：新增（Hero 区 Server Component）
- `frontend/src/components/sections/search-form.tsx`：新增（嵌套 Client Component，搜索表单交互逻辑）

**依赖**：无新增依赖。`next/image`、`lucide-react`、shadcn/ui `Input`/`Button` 组件已在 `introduce-frontend-styling-infra` 变更中安装并验证。

**前置依赖**：
- `introduce-frontend-styling-infra` 变更（Tailwind CSS + shadcn/ui + lucide-react 已安装并验证构建管线）
- `homepage-shell` 变更（页面骨架已完成，section slot 挂载点就绪）

**后续依赖**：
- 本变更完成后，`homepage-navigation` 变更可并行实施（两者均为静态区域，互不依赖）
