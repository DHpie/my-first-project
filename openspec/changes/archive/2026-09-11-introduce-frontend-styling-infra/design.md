## Context

当前 `frontend/` 目录下的样式系统处于"空白"状态：
- `globals.css` 包含 112 行旧手写 CSS（Vite 模板遗留），与 Next.js 15 App Router 无关
- 无 Tailwind CSS、无 PostCSS 配置、无组件库
- 6 个 homepage spec 全部依赖 Tailwind + shadcn/ui + lucide-react，但这些依赖均未安装

约束：
- Next.js 15.0.0 + React 19.2.8（已确认）
- 必须使用 Tailwind v4（最新稳定版，与 Next.js 15 原生兼容）
- shadcn/ui 必须使用 `new-york` style + `neutral` baseColor（项目约定）
- MVP 阶段不引入自定义主题、深色模式、动画库

## Goals / Non-Goals

**Goals:**
- 建立完整的 Tailwind CSS v4 构建管线，使 Tailwind 工具类在 Next.js 15 中生效
- 初始化 shadcn/ui，生成标准配置文件与 `cn()` 工具函数
- 安装首批 shadcn/ui 组件（Button、Input），供 homepage spec 使用
- 安装 lucide-react，供 homepage spec 的图标需求使用
- 验证构建管线完整性（build / lint / 类型检查 / dev server 全部通过）

**Non-Goals:**
- 页面级样式设计（Hero 背景、卡片样式等）— 属于各 homepage spec 的职责
- 自定义主题设计系统（MVP 使用 shadcn/ui 默认 neutral 主题）
- 深色模式（dark mode）切换功能
- 动画库（framer-motion 等）的引入
- 组件单元测试基础设施（前端测试框架尚未确定）
- 图标组件的自定义封装（直接使用 lucide-react 原生组件）
- 其他 shadcn/ui 组件（Dialog、Skeleton 等）— 按需在后续 spec 中单独安装

## Decisions

### Decision 1: Tailwind CSS v4（而非 v3）

**选择**: Tailwind CSS v4 + `@tailwindcss/postcss`

**理由**:
- v4 是最新稳定版，与 Next.js 15 原生兼容
- v4 使用 `@import "tailwindcss"` 指令（而非 v3 的 `@tailwind base/components/utilities`），语法更简洁
- v4 的 PostCSS 插件 `@tailwindcss/postcss` 是官方推荐，构建性能更优
- v4 支持 `@theme inline` 将 CSS variables 映射到 Tailwind 主题，与 shadcn/ui 的 CSS variables 体系天然契合

**替代方案**:
- Tailwind v3：成熟稳定，但语法较旧（`@tailwind` 指令），与 shadcn/ui 的 CSS variables 映射需要额外配置
- 不使用 Tailwind：项目已约定使用 Tailwind（见 `.harness/config.md`），不重新评估

### Decision 2: shadcn/ui 初始化配置

**选择**: `npx shadcn@latest init -y -d`（非交互模式，使用默认配置）

**配置**:
```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

**理由**:
- `style: "new-york"`：项目约定（见 `.harness/config.md`）
- `baseColor: "neutral"`：项目约定，MVP 使用默认 neutral 主题
- `rsc: true`：Next.js 15 App Router 默认使用 React Server Components
- `tsx: true`：项目使用 TypeScript
- `cssVariables: true`：shadcn/ui 的标准模式，与 Tailwind v4 的 `@theme inline` 配合
- `iconLibrary: "lucide"`：项目使用 lucide-react 作为图标库

**替代方案**:
- `style: "default"`：视觉风格不同，项目已约定使用 new-york
- `baseColor: "slate"` / `"zinc"`：颜色方案不同，项目已约定使用 neutral
- 交互模式初始化：AI Agent 无法执行交互式命令，必须使用 `-y -d` flags

### Decision 3: globals.css 迁移策略

**选择**: 完全重写 `globals.css`（移除所有旧 CSS，替换为 Tailwind 入口 + shadcn/ui 主题 tokens）

**理由**:
- 旧 CSS 是 Vite 模板遗留（112 行），与 Next.js 15 App Router 无关
- 旧 CSS 使用 CSS variables（`--text`、`--bg` 等），但命名与 shadcn/ui 不一致
- 完全重写比迁移更简单：shadcn/ui 初始化会生成标准的 `:root` CSS variables，直接覆盖即可
- 旧 CSS 中的 `#root`、`body`、`h1`、`h2`、`p`、`code` 等样式由 Tailwind 的 preflight（reset）处理，无需保留

**替代方案**:
- 保留部分旧 CSS：增加复杂度，且与 shadcn/ui 主题冲突
- 双 CSS 文件（`globals.css` + `shadcn.css`）：增加维护成本，不符合 shadcn/ui 标准实践

### Decision 4: 依赖安装顺序

**选择**: 按以下顺序安装：
1. `npm install -D tailwindcss @tailwindcss/postcss`（Tailwind + PostCSS 插件）
2. 创建 `postcss.config.mjs`（注册 `@tailwindcss/postcss`）
3. `npx shadcn@latest init -y -d`（初始化 shadcn/ui，自动生成 `components.json`、`src/lib/utils.ts`、改造 `globals.css`）
4. `npx shadcn@latest add button input`（安装首批组件）
5. `npm install lucide-react`（安装图标库）
6. 验证构建管线（`npm run build`、`npm run lint`、`npx tsc --noEmit`、`npm run dev`）

**理由**:
- Tailwind 必须先安装，shadcn/ui 初始化依赖 Tailwind 配置
- shadcn/ui 初始化会自动改造 `globals.css`，无需手动迁移
- 组件安装在 shadcn/ui 初始化之后，因为组件依赖 `cn()` 工具函数
- lucide-react 可以独立安装，但放在最后以便统一验证

**替代方案**:
- 先安装所有依赖再配置：增加出错风险，且 shadcn/ui 初始化需要 Tailwind 已配置
- 手动改造 `globals.css`：增加工作量，且容易与 shadcn/ui 自动生成的配置冲突

## Risks / Trade-offs

**[Risk] Tailwind v4 与 Next.js 15 的兼容性问题**
→ **Mitigation**: Tailwind v4 是官方推荐的最新稳定版，与 Next.js 15 原生兼容。若遇到兼容性问题，可降级至 Tailwind v3（但需要调整配置语法）。

**[Risk] shadcn/ui 初始化覆盖现有 `globals.css`**
→ **Mitigation**: 旧 `globals.css` 是 Vite 模板遗留，无业务价值，完全重写是安全的。初始化前可备份（但非必需）。

**[Risk] PostCSS 配置与 Next.js 内置 PostCSS 冲突**
→ **Mitigation**: Next.js 15 支持自定义 `postcss.config.mjs`，不会与内置 PostCSS 冲突。若遇到冲突，检查 Next.js 文档确认配置方式。

**[Risk] 构建管线验证失败**
→ **Mitigation**: 按顺序验证：先验证 Tailwind（`npm run build` 检查 CSS 生成），再验证 shadcn/ui（检查组件渲染），最后验证 lucide-react（检查图标导入）。若某步失败，回退检查配置。

**[Trade-off] 完全重写 `globals.css` vs 保留部分旧 CSS**
→ **Trade-off**: 完全重写更简单，但丢失了旧 CSS 中的字体栈（`--sans`、`--heading`、`--mono`）。shadcn/ui 的默认主题使用系统字体栈，可满足 MVP 需求。若未来需要自定义字体，可在 shadcn/ui 主题中扩展。
