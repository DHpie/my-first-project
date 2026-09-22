# 样式开发规范

## 技术栈

- **Tailwind CSS** (实用优先)
- **shadcn/ui** (基于 Radix UI 的组件库)
- **lucide-react** (图标库)
- **CSS 变量**驱动主题系统

## Tailwind 使用原则

- 优先使用 Tailwind utility classes，避免写自定义 CSS
- 使用语义化 CSS 变量 (`bg-primary`, `text-muted-foreground`, `border-border`) 而非硬编码颜色值
- 响应式: **mobile-first**，用 `md:` / `lg:` 前缀断点
- 交互状态: `hover:`, `focus-visible:`, `group-hover:`

## shadcn/ui 组件

- 基础 UI 组件放 `src/components/ui/` (`button.tsx`, `input.tsx` 等)
- 通过 `components.json` 配置，使用 shadcn CLI 添加新组件
- 覆盖样式用 `className` 属性传入，**不修改** `ui/` 内源码
- 自定义组件 (`section-divider.tsx` 等) 放对应功能目录或 `ui/`

## 主题系统

- 所有颜色通过 CSS 变量定义 (`:root` 和 `.dark`)
- 品牌色:
  - `primary: #C41E3A` (中国红)
  - `accent: #D4A017` (金色)
- 品牌渐变:
  - `--gradient-brand`: 135deg 红金渐变
  - `--gradient-card-accent`: 90deg 红金水平渐变
- 支持 light/dark 双主题，dark 模式通过 `.dark` class 切换

## 卡片设计模式

```
article.rounded-xl.border.border-border.bg-card.shadow-sm
  -> hover: shadow-lg, hover:-translate-y-1
  -> transition-all duration-200
```

- 圆角: `rounded-xl`
- 边框: `border border-border`
- 背景: `bg-card`
- 阴影: `shadow-sm` -> `hover:shadow-lg`
- 悬浮位移: `hover:-translate-y-1`
- 装饰性渐变条: 使用 CSS 变量 `--gradient-card-accent` 通过内联样式注入

## 动画规范

- **入场动画**: `fade-slide-up` 关键帧 (globals.css 定义)
- **滚动触发**: `data-visible="true"` + `use-scroll-reveal` 钩子
- **AI 呼吸灯**: `glow-pulse` 关键帧
- **必须**尊重 `prefers-reduced-motion: reduce` (globals.css 全局处理)
- 动画时长: 200-500ms，缓动 `cubic-bezier(0.16, 1, 0.3, 1)`

## 响应式策略

- **mobile-first**: 基础样式 = 移动端
- `md:` (768px) 断点切换到桌面布局
- 移动端横向滚动: `flex` + `overflow-x-auto` + `snap-x snap-mandatory`
- 桌面端网格: `md:grid md:grid-cols-N md:gap-6 md:overflow-visible md:snap-none`
- 图片: 使用 `aspect-[4/3]` 等比例容器 + `object-cover`
