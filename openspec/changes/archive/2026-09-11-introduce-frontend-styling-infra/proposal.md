## Why

ChinaBuddy 首页的 6 个功能模块（shell、hero、navigation、destinations、community、ai-widget）全部依赖 Tailwind CSS、shadcn/ui 组件库和 lucide-react 图标库，但这些依赖当前**均未安装**。`frontend/package.json` 仅有 next/react/react-dom/axios，缺少样式基础设施。若不先引入这些依赖，所有 homepage spec 的验收清单（Tailwind 类名、shadcn/ui 组件、lucide-react 图标）将无法通过。

## What Changes

- 安装 Tailwind CSS v4 + `@tailwindcss/postcss` 并配置 PostCSS 构建管线
- 改造 `frontend/src/app/globals.css`：移除 112 行旧手写 CSS（Vite 模板遗留），替换为 Tailwind 入口指令 + shadcn/ui 主题 tokens
- 初始化 shadcn/ui：生成 `components.json`（style: new-york, baseColor: neutral）、`src/lib/utils.ts`（`cn()` 工具函数）
- 安装首批 shadcn/ui 组件：`Button`、`Input`（homepage-hero 搜索框和 homepage-ai-widget 聊天输入所需）
- 安装 lucide-react 图标库（homepage spec 引用的 `Search`、`Users`、`Map`、`Bot`、`Globe`、`User` 图标）
- 验证构建管线完整性：`npm run build`、`npm run lint`、`npx tsc --noEmit`、`npm run dev` 全部通过

## Capabilities

### New Capabilities

无。本 change 是基础设施引入，不引入新的用户可见 capability。

### Modified Capabilities

无。本 change 不修改任何现有 main spec 的行为。

**说明**：本 change 属于纯 tooling/infrastructure 变更（安装依赖、配置构建管线），不改变任何 spec 级别的用户可见行为。所有 homepage spec 的 requirement 已在各自的 main spec 中定义，本 change 只是实施这些 requirement 的前置依赖。因此应在 `.openspec.yaml` 中设置 `skip_specs: true`。

## Impact

**代码**：
- `frontend/src/app/globals.css`：完全重写（移除 112 行旧 CSS，替换为 Tailwind + shadcn/ui 主题）
- `frontend/postcss.config.mjs`：新增（Tailwind PostCSS 配置）
- `frontend/components.json`：新增（shadcn/ui 配置）
- `frontend/src/lib/utils.ts`：新增（`cn()` 工具函数）
- `frontend/src/components/ui/button.tsx`：新增（shadcn/ui Button 组件）
- `frontend/src/components/ui/input.tsx`：新增（shadcn/ui Input 组件）

**依赖**：
- `package.json` devDependencies 新增：`tailwindcss`、`@tailwindcss/postcss`、`clsx`、`tailwind-merge`
- `package.json` dependencies 新增：`lucide-react`

**构建**：
- PostCSS 构建管线引入，Next.js 15 构建流程变更
- 现有 `npm run build`、`npm run dev` 命令行为变化（生成 Tailwind CSS）

**后续依赖**：
- 本 change 完成后，6 个 homepage spec（shell、hero、navigation、destinations、community、ai-widget）方可进入实施阶段
