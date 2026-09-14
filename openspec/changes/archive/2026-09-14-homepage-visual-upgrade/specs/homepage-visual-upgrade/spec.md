## Purpose

为 ChinaBuddy 首页实施全面品牌视觉升级——将当前灰度中性主题替换为以中国红（`#C41E3A`）为主色、金色（`#D4A017`）为强调色的大胆品牌视觉体系。涵盖色彩系统、Hero 区渐变叠加与搜索框品牌化、Header/Footer 视觉升级、卡片组件装饰条与 hover 动效、AI Widget 渐变边框与呼吸光晕、入场动画体系、响应式增强与动效无障碍。本变更为纯视觉升级，不改变任何现有功能行为（搜索逻辑、API 调用、路由跳转、数据获取等均不变）。

> 本 delta spec 覆盖以下基线规格中受视觉升级影响的 Requirements：
>
> - `homepage-shell`：Header 视觉（§Requirement: Header 区）、Footer 视觉（§Requirement: Footer 区）、布局容器宽度（§Requirement: 布局结构）
> - `homepage-hero`：背景图叠加层（§Requirement: 品牌背景图）、标题文字（§Requirement: 品牌主标题 / 副标题）、搜索框样式（§Requirement: 搜索输入框）、容器高度与响应式（§Requirement: 响应式行为）
> - `homepage-navigation`：卡片视觉与 hover 动效（§Requirement: 视觉反馈）
> - `homepage-destinations`：卡片视觉升级
> - `homepage-community`：卡片视觉升级

## In Scope

1. 品牌色彩系统——CSS 自定义属性替换（中国红 + 金色 + 暖色中性色）与渐变预设
2. Hero 区视觉升级——双层渐变叠加、标题文字阴影、搜索框毛玻璃胶囊化
3. Header 视觉升级——毛玻璃背景、品牌渐变底边、AI 链接圆点指示器
4. Footer 视觉升级——深色背景、品牌渐变顶线、金色链接 hover
5. 区块几何分隔组件——金色菱形装饰分隔线
6. 卡片组件升级——Navigation / Destinations / Community 的装饰条、hover 浮起、品牌色图标
7. AI Widget 视觉升级——渐变边框、呼吸光晕动效
8. 入场动画体系——IntersectionObserver + CSS `@keyframes` 滚动触发动画
9. 响应式策略增强——`lg` 断点、移动端装饰条位置适配
10. 动效无障碍——`prefers-reduced-motion` 全局降级

## Requirements

### Requirement: 品牌色彩系统

首页 SHALL 将当前灰度中性品牌色替换为中国红 + 金色的品牌色彩体系。所有色彩变更通过修改 `globals.css` 中 `:root` CSS 自定义属性实现，仅影响亮色模式（`.dark` 保留现有值不变）。

#### Scenario: 主色替换为中国红

- **WHEN** 首页在亮色模式下渲染
- **THEN** `--primary` SHALL 为 `#C41E3A`（中国红）
- **AND** `--primary-foreground` SHALL 为 `#FFFFFF`
- **AND** 所有使用 `bg-primary`、`text-primary` 的组件 SHALL 自动继承品牌红色

#### Scenario: 强调色设为金色

- **WHEN** 首页在亮色模式下渲染
- **THEN** `--accent` SHALL 为 `#D4A017`（金色）
- **AND** `--accent-foreground` SHALL 为 `#1A1A1A`

#### Scenario: 次要色设为暖杏白

- **WHEN** 首页在亮色模式下渲染
- **THEN** `--secondary` SHALL 为 `#FFF5E6`（暖杏白）
- **AND** `--secondary-foreground` SHALL 为 `#8B1A2B`（深红）

#### Scenario: 中性色暖化

- **WHEN** 首页在亮色模式下渲染
- **THEN** `--background` SHALL 为 `#FFFBF5`（暖白）
- **AND** `--foreground` SHALL 为 `#1A1A1A`
- **AND** `--muted` SHALL 为 `#F5F0EB`（暖灰）
- **AND** `--muted-foreground` SHALL 为 `#6B6560`（暖灰文字）
- **AND** `--border` SHALL 为 `#E8DDD3`（暖米色）
- **AND** `--card` SHALL 为 `#FFFFFF`

#### Scenario: 渐变预设可用

- **WHEN** 首页在亮色模式下渲染
- **THEN** 以下 CSS 自定义属性 SHALL 在 `:root` 中定义：
  - `--gradient-brand`: `linear-gradient(135deg, #C41E3A 0%, #D4A017 100%)`
  - `--gradient-hero-overlay`: `linear-gradient(to bottom, rgba(196,30,58,0.65) 0%, rgba(212,160,23,0.35) 100%)`
  - `--gradient-card-accent`: `linear-gradient(90deg, #C41E3A 0%, #D4A017 100%)`

#### Scenario: 暗色模式不受影响

- **WHEN** 页面处于 `.dark` 类激活状态
- **THEN** 所有 `--primary`、`--accent`、`--background` 等变量 SHALL 保持 `.dark` 块中定义的现有值
- **AND** 渐变预设 SHALL NOT 在 `.dark` 中覆盖

### Requirement: Hero 区视觉升级

Hero 区 SHALL 保持现有布局结构（背景图 + 居中内容 + 搜索框），通过品牌渐变叠加层、文字阴影增强和搜索框毛玻璃胶囊化提升视觉冲击力。

#### Scenario: 背景图品牌渐变叠加

- **WHEN** Hero 区被渲染
- **THEN** 背景图上方 SHALL 叠加品牌渐变层——使用 `var(--gradient-hero-overlay)`（红→金，从上到下，透明度 65%→35%），允许背景图透过但染上品牌色调
- **AND** 渐变层 SHALL 以绝对定位覆盖背景图全区域（`absolute inset-0`）

#### Scenario: 背景图底部渐隐过渡

- **WHEN** Hero 区被渲染
- **THEN** 渐变层底部 30% 高度 SHALL 从透明渐隐至 `var(--background)` 色，使 Hero 与下方内容自然衔接

#### Scenario: 移除旧纯色背景

- **WHEN** Hero 区被渲染
- **THEN** SHALL NOT 使用 `bg-[#1a1a2e]` 纯色背景
- **AND** 图片加载失败时的回退背景色 SHALL 更新为 `var(--background)`（而非旧的 `#1a1a2e`）

#### Scenario: 标题文字阴影增强

- **WHEN** Hero 区被渲染
- **THEN** 主标题 SHALL 保持白色文字
- **AND** 主标题 SHALL 具有文字阴影 `text-shadow: 0 2px 12px rgba(0,0,0,0.4)` 以增强在渐变叠加层上的可读性

#### Scenario: 副标题排版增强

- **WHEN** Hero 区被渲染
- **THEN** 副标题 SHALL 使用 `text-white/95`（而非当前的 `text-white/90`）
- **AND** 副标题 SHALL 添加 `tracking-wide` 字间距

#### Scenario: 搜索框毛玻璃胶囊化

- **WHEN** Hero 区被渲染
- **THEN** 搜索表单外层 SHALL 包裹毛玻璃胶囊容器——`backdrop-blur-md bg-white/15 border border-white/25 rounded-full`
- **AND** 输入框 SHALL 为透明背景、白色文字、占位文本 `text-white/60`
- **AND** 搜索按钮 SHALL 使用品牌红背景 `bg-[#C41E3A]`，hover 变为 `bg-[#A01830]`
- **AND** 搜索按钮图标 SHALL 保持白色

#### Scenario: 搜索框焦点金色光晕

- **WHEN** 用户聚焦搜索输入框
- **THEN** 胶囊容器 SHALL 显示金色焦点环 `ring-2 ring-[#D4A017]/50`
- **AND** 搜索功能行为（提交即跳转、空值校验、最大长度等）SHALL NOT 改变

#### Scenario: Hero 容器高度调整

- **WHEN** Hero 区被渲染
- **THEN** 移动端最小高度 SHALL 为 360px（从 300px 提升）
- **AND** 桌面端最小高度 SHALL 为 540px（从 500px 提升）

### Requirement: Header 视觉升级

Header SHALL 保持现有极简结构（品牌名 + AI Assistant 链接），仅升级视觉效果。

#### Scenario: 毛玻璃背景

- **WHEN** Header 被渲染
- **THEN** Header 背景 SHALL 为毛玻璃效果——`backdrop-blur-lg bg-background/80`
- **AND** 滚动时页面内容 SHALL 在 Header 后方半透明可见
- **AND** 本 Requirement 显式覆盖 `homepage-shell` spec 中"header SHALL 具有不透明背景色"的要求——视觉升级有意引入半透明毛玻璃效果以增强层次感

#### Scenario: 品牌渐变底边

- **WHEN** Header 被渲染
- **THEN** Header SHALL NOT 使用 `border-b border-border`
- **AND** Header 底部 SHALL 显示 1px 品牌渐变线——`bg-gradient-to-r from-[#C41E3A] via-[#D4A017] to-[#C41E3A]`

#### Scenario: 品牌名 hover 变色

- **WHEN** 用户使用指针设备悬停品牌名 "ChinaBuddy"
- **THEN** 品牌名 SHALL 从 `text-foreground` 变为 `text-[#C41E3A]`
- **AND** 变色 SHALL 带 `transition-colors` 平滑过渡

#### Scenario: AI Assistant 链接圆点指示器

- **WHEN** Header 被渲染
- **THEN** "AI Assistant" 链接文字前 SHALL 显示一个品牌红圆点——`h-2 w-2 rounded-full bg-[#C41E3A]`
- **AND** 圆点 SHALL 暗示"在线/可用"状态

### Requirement: Footer 视觉升级

Footer SHALL 从白底灰字升级为深色底 + 金色点缀的品牌收尾视觉。

#### Scenario: 深色背景

- **WHEN** Footer 被渲染
- **THEN** Footer 背景 SHALL 为 `bg-[#1A1A1A]`（近黑色）
- **AND** SHALL NOT 使用 `bg-background`

#### Scenario: 品牌渐变顶线

- **WHEN** Footer 被渲染
- **THEN** Footer SHALL NOT 使用 `border-t border-border`
- **AND** Footer 顶部 SHALL 显示 2px 品牌渐变线——`bg-gradient-to-r from-[#C41E3A] to-[#D4A017]`

#### Scenario: 文字与链接颜色

- **WHEN** Footer 被渲染
- **THEN** 版权文字 SHALL 为 `text-white/60`
- **AND** 链接 SHALL 为 `text-white/70`
- **AND** 链接 hover SHALL 变为 `text-[#D4A017]`（金色），带 `transition-colors`

#### Scenario: 品牌名金色高亮

- **WHEN** Footer 被渲染
- **THEN** 版权行中的 "ChinaBuddy" SHALL 以 `text-[#D4A017]`（金色）高亮显示

### Requirement: 区块分隔组件

首页 SHALL 在 Navigation、Destinations、Community 三个区块之间插入几何装饰分隔线组件。

#### Scenario: 分隔线视觉

- **WHEN** `<SectionDivider />` 被渲染
- **THEN** SHALL 显示一条居中的细线（`h-px`），两端渐隐为透明，中间带金色菱形装饰
- **AND** 线条颜色 SHALL 为 `from-transparent via-[#D4A017]/40 to-transparent`
- **AND** 菱形装饰 SHALL 为 `h-2 w-2 rotate-45 bg-[#D4A017]/40`
- **AND** 整体宽度 SHALL 为 `max-w-xs mx-auto`

#### Scenario: 分隔线插入位置

- **WHEN** 首页被渲染
- **THEN** `<SectionDivider />` SHALL 出现在 Navigation 与 Destinations 之间
- **AND** `<SectionDivider />` SHALL 出现在 Destinations 与 Community 之间
- **AND** SHALL NOT 出现在 Hero 与 Navigation 之间

### Requirement: 卡片组件视觉升级

所有首页卡片（Navigation / Destinations / Community）SHALL 统一视觉升级语言——底部品牌渐变装饰条、hover 浮起效果、品牌色图标。

#### Scenario: Navigation 卡片底部装饰条

- **WHEN** Navigation 卡片被渲染
- **THEN** 每张卡片底部 SHALL 显示 3px 品牌渐变条——`bg-gradient-to-r from-[#C41E3A] to-[#D4A017]`

#### Scenario: Navigation 卡片图标品牌色

- **WHEN** Navigation 卡片被渲染
- **THEN** 图标 SHALL 为 `text-[#C41E3A]`（品牌红，替代当前的灰色 `text-primary`）
- **AND** hover 时图标 SHALL 缩放至 `scale-110`，带 `transition-transform duration-300`

#### Scenario: Navigation 卡片 hover 浮起

- **WHEN** 用户使用指针设备悬停 Navigation 卡片
- **THEN** 卡片 SHALL 向上位移 `hover:-translate-y-1`
- **AND** 阴影 SHALL 加深为 `hover:shadow-xl`
- **AND** 边框 SHALL 变为 `hover:border-[#D4A017]/30`
- **AND** 标题文字 SHALL 变为 `text-[#C41E3A]`，带 `transition-colors`
- **AND** 所有过渡 SHALL 使用 `transition-all duration-300`

#### Scenario: Navigation 卡片按压回弹

- **WHEN** 用户在触摸设备上按下 Navigation 卡片
- **THEN** 卡片 SHALL 回弹至原位 `active:translate-y-0`

#### Scenario: Destination 卡片封面图叠加层

- **WHEN** Destination 卡片被渲染
- **THEN** 封面图上方 SHALL 叠加底部渐变遮罩——`linear-gradient(to top, rgba(0,0,0,0.3) 0%, transparent 50%)`

#### Scenario: Destination 卡片城市名重定位

- **WHEN** Destination 卡片被渲染
- **THEN** 城市名 SHALL 从卡片内容区移至封面图叠加层上，以白色 `font-semibold` 显示
- **AND** 人气标签 SHALL 变为毛玻璃胶囊——`backdrop-blur-sm bg-white/20 text-white border border-white/20`，定位在封面图右下角

#### Scenario: Destination 卡片内容区装饰竖线

- **WHEN** Destination 卡片被渲染
- **THEN** 卡片内容区的 `highlight` 描述文字 SHALL 左侧带 2px 品牌红竖线——`border-l-2 border-[#C41E3A]/40 pl-3`

#### Scenario: Destination 卡片 hover 效果

- **WHEN** 用户使用指针设备悬停 Destination 卡片
- **THEN** 封面图 SHALL 缩放至 `scale(1.08)`（从 1.05 增强）
- **AND** 卡片 SHALL 向上位移 `-translate-y-1` 并显示 `shadow-xl`
- **AND** 底部 3px 品牌渐变装饰条 SHALL 从 `opacity-0` 渐显至 `opacity-100`

#### Scenario: Community 帖子卡片头像品牌边框

- **WHEN** Community 帖子卡片被渲染
- **THEN** 头像外圈 SHALL 显示品牌红边框——`ring-2 ring-[#C41E3A]/30`

#### Scenario: Community 帖子卡片点赞图标品牌色

- **WHEN** Community 帖子卡片被渲染
- **THEN** Heart 图标 SHALL 为 `text-[#C41E3A]/60`（替代当前的 `text-muted-foreground`）
- **AND** hover 整卡时图标 SHALL 变为 `text-[#C41E3A]` 并带 `scale-110` 微动画

#### Scenario: Community 帖子卡片 hover 与装饰

- **WHEN** 用户使用指针设备悬停 Community 帖子卡片
- **THEN** 卡片 SHALL 向上位移 `hover:-translate-y-1` 并显示 `shadow-xl`
- **AND** 边框 SHALL 变为 `hover:border-[#D4A017]/30`
- **AND** 底部 2px 品牌渐变装饰条 SHALL 从 `opacity-0` 渐显至 `opacity-100`

#### Scenario: 骨架屏暖色化

- **WHEN** Destinations 或 Community 区块处于 loading 状态
- **THEN** 骨架屏底色 SHALL 为 `bg-[#FFF5E6]`（暖杏白，替代 `bg-muted`）
- **AND** 骨架屏脉冲色 SHALL 为 `bg-[#F0E0CC]`（替代 `bg-muted` 的脉冲效果）

### Requirement: AI Widget 视觉升级

AI Widget 悬浮按钮 SHALL 增加渐变边框与呼吸光晕动效，增强品牌辨识度。

#### Scenario: 悬浮按钮渐变边框

- **WHEN** AI Widget 悬浮按钮被渲染
- **THEN** 按钮 SHALL 显示品牌渐变边框——从 `#C41E3A` 到 `#D4A017`
- **AND** 按钮背景 SHALL 保持 `bg-primary`（现为品牌红色）

#### Scenario: 呼吸光晕动效

- **WHEN** AI Widget 悬浮按钮被渲染
- **THEN** 按钮 SHALL 带持续的呼吸光晕效果——红色外发光以 `pulse` 节奏缩放（`box-shadow` 脉动）
- **AND** 光晕颜色 SHALL 为 `rgba(196, 30, 58, 0.4)` 至透明
- **AND** 动效 SHALL 使用 CSS `@keyframes` 实现，周期约 2 秒

#### Scenario: 呼吸光效无障碍降级

- **WHEN** 用户系统启用了 `prefers-reduced-motion: reduce`
- **THEN** 呼吸光晕动画 SHALL 完全停止
- **AND** 按钮 SHALL 保持静态渲染，无光晕效果

### Requirement: 入场动画体系

首页各区块 SHALL 在滚动进入视口时触发 fade-in + slide-up 入场动画，提供生动的浏览体验。

#### Scenario: 动画定义

- **WHEN** 入场动画被触发
- **THEN** 动画 SHALL 为 `fade-slide-up`——从 `opacity: 0; transform: translateY(24px)` 过渡至 `opacity: 1; transform: translateY(0)`
- **AND** 动画时长 SHALL 为 500ms
- **AND** 缓动函数 SHALL 为 `cubic-bezier(0.16, 1, 0.3, 1)`（ease-out-quint）

#### Scenario: 滚动触发机制

- **WHEN** 带有入场动画的元素进入视口（交叉比例 ≥ 15%）
- **THEN** 元素 SHALL 触发 `fade-slide-up` 动画
- **AND** 动画 SHALL 仅触发一次（不重复播放）
- **AND** 实现 SHALL 使用 `IntersectionObserver`（`threshold: 0.15`）封装为共享 Hook

#### Scenario: Hero 区页面加载入场动画

- **WHEN** 首页首次加载
- **THEN** 主标题 SHALL 立即触发 fade-slide-up（延迟 0ms）
- **AND** 副标题 SHALL 以 150ms 延迟触发
- **AND** 搜索框 SHALL 以 300ms 延迟触发

#### Scenario: Navigation 卡片依次入场

- **WHEN** Navigation 区块进入视口
- **THEN** 三张卡片 SHALL 依次触发 fade-slide-up
- **AND** 每张卡片延迟递增 100ms（第 1 张 0ms、第 2 张 100ms、第 3 张 200ms）

#### Scenario: Destination 卡片依次入场

- **WHEN** Destinations 区块进入视口
- **THEN** 区块标题 SHALL 立即触发 fade-slide-up
- **AND** 各 Destination 卡片 SHALL 依次触发，延迟递增 80ms

#### Scenario: Community 卡片依次入场

- **WHEN** Community 区块进入视口
- **THEN** 区块标题 SHALL 立即触发 fade-slide-up
- **AND** 各 Community 帖子卡片 SHALL 依次触发，延迟递增 100ms

#### Scenario: 动画仅使用 GPU 加速属性

- **WHEN** 入场动画播放
- **THEN** SHALL 仅动画 `opacity` 和 `transform` 属性
- **AND** SHALL NOT 动画 `width`、`height`、`margin`、`padding` 等触发 layout 的属性

### Requirement: 响应式策略增强

首页 SHALL 在保持现有响应式断点行为的基础上，增强大屏适配与移动端装饰细节。

#### Scenario: 大屏容器宽度扩展

- **WHEN** 视口宽度为 1024px 及以上（`lg:` 断点）
- **THEN** 首页主内容容器最大宽度 SHALL 从 1200px 扩展至 1280px（`lg:max-w-[1280px]`）
- **AND** Community 区块 SHALL 从 3 列升级至 4 列（`lg:grid-cols-4`）

#### Scenario: 移动端装饰条位置

- **WHEN** 视口宽度小于 768px
- **THEN** 卡片底部品牌渐变装饰条 SHALL 移至卡片顶部（避免底部被视口裁切）

#### Scenario: Hero 搜索框移动端适配

- **WHEN** 视口宽度小于 768px
- **THEN** 毛玻璃胶囊搜索框 SHALL 全宽显示，水平外边距 `mx-3`

#### Scenario: 现有响应式行为保持不变

- **WHEN** 首页在各断点渲染
- **THEN** Destinations 移动端横向滚动 → 桌面端 4 列网格 SHALL 保持不变
- **AND** Community 移动端纵排 → `md` 断点 3 列 SHALL 保持不变
- **AND** Navigation 移动端全宽堆叠 → `md` 断点 3 卡横排 SHALL 保持不变

### Requirement: 动效无障碍

所有入场动画与过渡动效 SHALL 尊重用户的系统级减少动效偏好。

#### Scenario: prefers-reduced-motion 全局降级

- **WHEN** 用户系统设置了 `prefers-reduced-motion: reduce`
- **THEN** 所有 CSS 动画时长 SHALL 降至 0.01ms
- **AND** 所有 CSS 过渡时长 SHALL 降至 0.01ms
- **AND** 动画迭代次数 SHALL 限制为 1 次
- **AND** 元素 SHALL 直接以最终状态渲染（`opacity: 1; transform: none`）

## Data Structures

### useScrollReveal Hook

```typescript
/**
 * 滚动入场动画 Hook。
 * 封装 IntersectionObserver，当目标元素进入视口 ≥15% 时
 * 设置 data-visible="true" 属性触发 CSS 动画。
 */
function useScrollReveal<T extends HTMLElement>(): React.RefObject<T | null>;
```

返回值：一个 `ref`，绑定到需要入场动画的容器元素上。

### SectionDividerProps

```typescript
/**
 * 区块几何分隔组件。
 * 无 props——纯视觉装饰，无交互逻辑。
 * 实现为 Server Component（无 "use client"）。
 */
interface SectionDividerProps {
  // 无属性
}
```

### CSS 自定义属性（新增）

以下 CSS 自定义属性 SHALL 在 `:root` 中定义（仅亮色模式）：

```css
:root {
  /* 品牌色 */
  --primary: #C41E3A;
  --primary-foreground: #FFFFFF;
  --accent: #D4A017;
  --accent-foreground: #1A1A1A;
  --secondary: #FFF5E6;
  --secondary-foreground: #8B1A2B;

  /* 暖色中性色 */
  --background: #FFFBF5;
  --foreground: #1A1A1A;
  --muted: #F5F0EB;
  --muted-foreground: #6B6560;
  --border: #E8DDD3;
  --card: #FFFFFF;

  /* 渐变预设 */
  --gradient-brand: linear-gradient(135deg, #C41E3A 0%, #D4A017 100%);
  --gradient-hero-overlay: linear-gradient(
    to bottom,
    rgba(196, 30, 58, 0.65) 0%,
    rgba(212, 160, 23, 0.35) 100%
  );
  --gradient-card-accent: linear-gradient(90deg, #C41E3A 0%, #D4A017 100%);
}
```

## Acceptance Checklist

### 品牌色彩系统
- [ ] `:root` 中 `--primary` 为 `#C41E3A`（中国红）
- [ ] `:root` 中 `--accent` 为 `#D4A017`（金色）
- [ ] `:root` 中 `--background` 为 `#FFFBF5`（暖白）
- [ ] `:root` 中 `--border` 为 `#E8DDD3`（暖米色）
- [ ] 三个渐变预设（`--gradient-brand`、`--gradient-hero-overlay`、`--gradient-card-accent`）已定义
- [ ] `.dark` 块中变量值未被覆盖

### Hero 区
- [ ] 背景图上方叠加品牌渐变层（红→金，透明度 65%→35%）
- [ ] 底部 30% 渐隐至 `var(--background)` 色
- [ ] 不再使用 `bg-[#1a1a2e]` 纯色背景
- [ ] 主标题带文字阴影 `text-shadow: 0 2px 12px rgba(0,0,0,0.4)`
- [ ] 副标题使用 `text-white/95` + `tracking-wide`
- [ ] 搜索框包裹在毛玻璃胶囊容器中（`backdrop-blur-md bg-white/15 border-white/25 rounded-full`）
- [ ] 搜索按钮为品牌红 `bg-[#C41E3A]`
- [ ] 搜索框焦点环为金色 `ring-[#D4A017]/50`
- [ ] 移动端最小高度 360px、桌面端 540px
- [ ] 搜索功能行为（提交跳转、空值校验、最大长度）未改变

### Header
- [ ] Header 背景为毛玻璃效果（`backdrop-blur-lg bg-background/80`）
- [ ] 底部为品牌渐变线（红→金→红，1px）
- [ ] 不再使用 `border-b border-border`
- [ ] 品牌名 hover 变为 `text-[#C41E3A]`
- [ ] AI Assistant 链接前有品牌红圆点指示器

### Footer
- [ ] Footer 背景为深色 `bg-[#1A1A1A]`
- [ ] 顶部为品牌渐变线（红→金，2px）
- [ ] 不再使用 `border-t border-border`
- [ ] 版权文字为 `text-white/60`
- [ ] 链接 hover 变为金色 `text-[#D4A017]`
- [ ] "ChinaBuddy" 以金色高亮

### 区块分隔
- [ ] `<SectionDivider />` 出现在 Navigation-Destinations 和 Destinations-Community 之间
- [ ] 分隔线为金色菱形 + 渐隐线条
- [ ] Hero 与 Navigation 之间无分隔线

### 卡片组件
- [ ] Navigation 卡片底部 3px 品牌渐变装饰条
- [ ] Navigation 图标为品牌红色 `text-[#C41E3A]`
- [ ] 所有卡片 hover 统一为 `-translate-y-1 shadow-xl border-[#D4A017]/30`
- [ ] Destination 卡片封面图有底部渐变叠加层
- [ ] Destination 城市名在封面图叠加层上（白色）
- [ ] Destination 人气标签为毛玻璃胶囊
- [ ] Destination 描述文字左侧有品牌红竖线
- [ ] Community 头像有品牌红 `ring-2 ring-[#C41E3A]/30`
- [ ] Community Heart 图标为 `text-[#C41E3A]/60`
- [ ] 所有卡片装饰条 hover 时从 `opacity-0` 渐显
- [ ] 骨架屏底色为 `bg-[#FFF5E6]`、脉冲色为 `bg-[#F0E0CC]`

### AI Widget
- [ ] 悬浮按钮有品牌渐变边框（红→金）
- [ ] 悬浮按钮有呼吸光晕动效（红色 `box-shadow` 脉动，周期约 2s）
- [ ] `prefers-reduced-motion` 下呼吸光效完全停止

### 入场动画
- [ ] `@keyframes fade-slide-up` 已在 `globals.css` 中定义
- [ ] `useScrollReveal` Hook 使用 `IntersectionObserver`（`threshold: 0.15`）
- [ ] Hero 标题/副标题/搜索框依次入场（0ms / 150ms / 300ms）
- [ ] Navigation 卡片依次入场（+100ms 递增）
- [ ] Destination 卡片依次入场（+80ms 递增）
- [ ] Community 卡片依次入场（+100ms 递增）
- [ ] 动画仅使用 `opacity` 和 `transform`（GPU 加速）
- [ ] 动画时长 500ms，缓动 `cubic-bezier(0.16, 1, 0.3, 1)`

### 响应式
- [ ] `lg:` 断点（≥ 1024px）容器最大宽度 1280px
- [ ] `lg:` 断点 Community 升级至 4 列
- [ ] 移动端装饰条移至卡片顶部
- [ ] Hero 搜索框移动端全宽 `mx-3`
- [ ] 现有断点行为（mobile 横滚 / md 网格 / md 横排）保持不变

### 无障碍
- [ ] `prefers-reduced-motion: reduce` 全局规则已添加
- [ ] 所有动画在 reduced-motion 下降级为 0.01ms
- [ ] 元素在 reduced-motion 下直接以最终状态渲染

### 纯视觉变更声明
- [ ] 搜索提交逻辑未改变（仍导航至 `/search?q={query}`）
- [ ] API 调用未改变（destinations / community / AI chat 接口不变）
- [ ] 路由跳转未改变（Navigation 卡片链接、Footer 链接不变）
- [ ] 数据获取逻辑未改变（`useEffect` / `useCallback` / `AbortController` 不变）
- [ ] 无障碍结构未改变（`aria-label`、语义化地标、skip-to-content 不变）

## Out of Scope

- 暗色模式视觉适配——本次仅聚焦亮色模式，`.dark` 变量保持不变
- 新增页面或路由——所有变更均在现有首页组件内
- 导航菜单扩展——Header 保持极简结构，不增加汉堡菜单或下拉菜单
- 字体更换——仍使用 Geist Sans，不引入新字体
- 动画库引入——入场动画使用原生 CSS `@keyframes` + `IntersectionObserver`，不引入 Framer Motion 等第三方库
- 后端变更——所有 API 接口、数据库逻辑、服务端渲染行为不变
- AI Widget 功能变更——聊天逻辑、消息处理、API 调用不变，仅视觉升级
- 国际化（i18n）——所有显示文本保持英文不变
- 性能优化——不以 Core Web Vitals 调优为目标（但动画实现需保证不劣化现有性能）
- 浏览器兼容性格外适配——依赖 Tailwind 4 + 现代浏览器原生能力
