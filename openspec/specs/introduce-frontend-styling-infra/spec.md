## Purpose

为 ChinaBuddy 前端引入样式基础设施：Tailwind CSS + shadcn/ui 组件库 + lucide-react 图标库。这是所有 homepage 模块（shell、hero、navigation、destinations、community、ai-widget）实施的前置依赖。本 spec 只定义基础设施的引入与配置，不包含任何页面级样式设计。

## In Scope

1. 安装 Tailwind CSS 并配置 PostCSS 构建管线
2. 初始化 shadcn/ui（生成 `components.json`、CSS variables、`lib/utils.ts` 的 `cn()` 工具函数）
3. 安装 lucide-react 图标库
4. 改造 `globals.css`（Tailwind directives + shadcn/ui 主题 tokens）
5. 安装首批 shadcn/ui 组件：`Button`、`Input`（homepage-hero 搜索框和 homepage-ai-widget 聊天输入所需）
6. 验证构建管线（build / lint / 类型检查全部通过）

## Requirements

### Requirement: Tailwind CSS 安装
系统 SHALL 安装 Tailwind CSS 并配置 PostCSS 使其在 Next.js 15 构建管线中正常工作。

#### Scenario: 安装成功
- **WHEN** 执行 `npm install tailwindcss @tailwindcss/postcss` 并创建 `postcss.config.mjs`
- **THEN** `package.json` 的 `devDependencies` SHALL 包含 `tailwindcss` 和 `@tailwindcss/postcss`
- **AND** `postcss.config.mjs` SHALL 注册 `@tailwindcss/postcss` 插件

#### Scenario: Tailwind 类名生效
- **WHEN** 任意组件中使用 Tailwind 工具类（如 `flex`、`md:flex`、`text-3xl`）
- **THEN** 构建产物中 SHALL 生成对应的 CSS 规则
- **AND** 页面渲染时样式 SHALL 正确应用

### Requirement: globals.css 改造
系统 SHALL 将现有 `globals.css` 改造为 Tailwind 入口文件，包含 Tailwind directives 和 shadcn/ui 主题 tokens。

#### Scenario: Tailwind 指令生效
- **WHEN** `globals.css` 被改造
- **THEN** 文件顶部 SHALL 包含 `@import "tailwindcss"` 指令
- **AND** 所有原有的手写 CSS SHALL 被移除或迁移至 shadcn/ui 的 CSS variables 体系

#### Scenario: shadcn/ui 主题 tokens
- **WHEN** `globals.css` 被改造
- **THEN** 文件 SHALL 包含 `:root` 中的 shadcn/ui 主题 CSS variables（`--background`、`--foreground`、`--primary` 等）
- **AND** 支持 `@theme inline` 将 CSS variables 映射到 Tailwind 主题

### Requirement: shadcn/ui 初始化
系统 SHALL 初始化 shadcn/ui 组件库，生成标准配置文件与工具函数。

#### Scenario: CLI 初始化
- **WHEN** 执行 `npx shadcn@latest init -y -d`（非交互模式：`-y` 跳过确认、`-d` 使用默认配置）
- **THEN** 项目根目录 SHALL 生成 `components.json` 配置文件
- **AND** 配置 SHALL 指定 style 为 "new-york"、baseColor 为 "neutral"
- **AND** 配置 SHALL 使用 CSS variables 主题模式

#### Scenario: cn() 工具函数
- **WHEN** shadcn/ui 初始化完成
- **THEN** `src/lib/utils.ts` SHALL 导出 `cn()` 函数用于合并 Tailwind 类名
- **AND** `cn()` SHALL 基于 `clsx` + `tailwind-merge` 实现

### Requirement: 首批 shadcn/ui 组件安装
系统 SHALL 安装 homepage 模块所需的首批 shadcn/ui 组件。

#### Scenario: Button 组件安装
- **WHEN** 执行 `npx shadcn@latest add button`
- **THEN** `src/components/ui/button.tsx` SHALL 被生成
- **AND** Button 组件 SHALL 支持 `variant`（default/destructive/outline/secondary/ghost/link）和 `size`（default/sm/lg/icon）props

#### Scenario: Input 组件安装
- **WHEN** 执行 `npx shadcn@latest add input`
- **THEN** `src/components/ui/input.tsx` SHALL 被生成
- **AND** Input 组件 SHALL 支持原生 `input` 的所有 props 透传

### Requirement: lucide-react 安装
系统 SHALL 安装 lucide-react 图标库作为项目统一的图标方案。

#### Scenario: 安装成功
- **WHEN** 执行 `npm install lucide-react`
- **THEN** `package.json` 的 `dependencies` SHALL 包含 `lucide-react`
- **AND** 所有 homepage spec 引用的图标（`Search`、`Users`、`Map`、`Bot`、`Globe`、`User`）SHALL 均可从 `lucide-react` 导入

### Requirement: 构建管线验证
系统 SHALL 在引入全部依赖后验证构建管线完整性。

#### Scenario: 构建通过
- **WHEN** 执行 `npm run build`
- **THEN** 构建 SHALL 零错误完成
- **AND** 产物中 SHALL 包含 Tailwind 生成的 CSS

#### Scenario: Lint 通过
- **WHEN** 执行 `npm run lint`
- **THEN** Lint SHALL 零错误零警告完成

#### Scenario: 类型检查通过
- **WHEN** 执行 `npx tsc --noEmit`
- **THEN** 类型检查 SHALL 零错误完成

#### Scenario: 开发服务器启动
- **WHEN** 执行 `npm run dev`
- **THEN** 开发服务器 SHALL 正常启动于 `http://localhost:3000`
- **AND** 页面 SHALL 无样式相关报错

## Data Structures

### components.json（shadcn/ui 配置文件）

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

### cn() 工具函数签名

```typescript
// src/lib/utils.ts
export function cn(...inputs: ClassValue[]): string
```

## Acceptance Checklist

### 依赖安装
- [ ] `tailwindcss` + `@tailwindcss/postcss` 已安装至 devDependencies
- [ ] `lucide-react` 已安装至 dependencies
- [ ] `clsx` + `tailwind-merge` 已安装（cn() 依赖）

### 配置文件
- [ ] `postcss.config.mjs` 存在且注册 Tailwind 插件
- [ ] `components.json` 存在且 style=new-york、baseColor=neutral、cssVariables=true
- [ ] `src/lib/utils.ts` 存在且导出 `cn()`

### globals.css
- [ ] 顶部包含 `@import "tailwindcss"` 指令
- [ ] `:root` 包含 shadcn/ui 主题 CSS variables
- [ ] 无遗留的旧手写 CSS

### shadcn/ui 组件
- [ ] `src/components/ui/button.tsx` 存在
- [ ] `src/components/ui/input.tsx` 存在
- [ ] Button 支持 6 种 variant 和 4 种 size
- [ ] Input 支持原生 props 透传

### 验证
- [ ] `npm run build` 零错误
- [ ] `npm run lint` 零错误
- [ ] `npx tsc --noEmit` 零错误
- [ ] `npm run dev` 正常启动且无样式报错
- [ ] Tailwind 工具类在页面中生效（抽样验证 `flex`、`md:flex`）

## Out of Scope

- 页面级样式设计（Hero 背景、卡片样式等）— 属于各 homepage spec 的职责
- 自定义主题设计系统（MVP 使用 shadcn/ui 默认 neutral 主题）
- 深色模式（dark mode）切换功能
- 动画库（framer-motion 等）的引入
- 组件单元测试基础设施（前端测试框架尚未确定，见 `.harness/config.md > Tool Preferences`）
- 图标组件的自定义封装（直接使用 lucide-react 原生组件）
- 其他 shadcn/ui 组件（Dialog、Skeleton 等）— 按需在后续 spec 中单独安装
