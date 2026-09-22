# 前端开发规范

## 目录结构

```
frontend/src/
  ├── api/              # API 调用层
  │   ├── request.ts    # Axios 实例 + 响应拦截器 (解包 Result<T>)
  │   └── <feature>.ts  # 按功能分文件 (类型定义 + API 函数)
  ├── app/              # Next.js App Router 页面
  │   ├── page.tsx      # 首页
  │   ├── layout.tsx    # 根布局
  │   └── globals.css   # 全局样式 + CSS 变量 + 动画
  ├── components/       # 按功能域分目录
  │   ├── <feature>/    # 功能组件 (section + card 等)
  │   ├── layout/       # 布局组件 (header, footer, skip-to-content)
  │   └── ui/           # 基础 UI 组件 (shadcn/ui: button, input 等)
  ├── lib/              # 工具函数 (format.ts, utils.ts, hooks)
  └── types/            # 全局共享 TypeScript 类型
```

## 组件模式

- 功能组件: **默认导出**, `"use client"` 按需添加 (需要 useState/useEffect 时)
- 数据获取组件遵循**三态渲染**:
  1. `loading` -> Skeleton 占位
  2. `error` -> 错误提示 + Retry 按钮
  3. `empty` -> 空状态提示
  4. `data` -> 正常渲染
- 组件文件命名: **kebab-case** (`destination-card.tsx`)
- 组件函数命名: **PascalCase** (`function DestinationCard`)
- Props 用 `interface` + 类型导入 (`import type { Xxx } from "..."`)

## 数据获取模式

- API 调用集中在 `src/api/<feature>.ts`
- 每个 feature 文件导出: **类型定义** + **API 函数**
- API 函数接收 `AbortSignal` 参数支持超时控制
- 使用 axios 实例 (`src/api/request.ts`)，拦截器自动检查 `Result<T>.code === 200`
- 组件内用 `useState` + `useEffect` + `useCallback` 获取数据

```typescript
// api/<feature>.ts
export interface Feature { id: number; name: string; }

export async function getFeatures(signal?: AbortSignal): Promise<Feature[]> {
  const response = await request.get<Result<Feature[]>>("/api/features", { signal });
  return response.data.data;
}
```

## 类型定义

- 全局共享类型放 `src/types/` (如 `Result<T>`)
- 功能专属类型就近定义在 `api/<feature>.ts` 中导出
- `Result<T>` 类型与后端 `Result<T>` 对应: `{ code: number; message: string; data: T }`

## 图片规范

- **必须**使用 `next/image` (不用 `<img>`)
- 图片加载失败需回退处理 (`useState` + `onError`)
- 静态资源放 `public/`
- 使用 `fill` + 父容器控制尺寸，配合 `aspect-ratio` 保持比例

## 可访问性

- `<section>` 需要 `aria-label`
- 交互元素 (Link, Button) 需要 `aria-label` (当内容不足以表达用途时)
- 支持 `prefers-reduced-motion` (globals.css 全局处理)
- 提供跳转到主内容的链接 (`layout/skip-to-content.tsx`)
