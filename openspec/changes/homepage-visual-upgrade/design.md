## Context

ChinaBuddy 首页已完成全部功能实现并归档 6 个 homepage 变更（shell / hero / navigation / destinations / community / ai-widget）。当前视觉层面使用 shadcn/ui 默认灰度主题——`--primary` 为深灰色（`oklch(0.205 0 0)`）、`--background` 为纯白（`oklch(1 0 0)`）、所有卡片仅灰框白底、hover 仅有基础 `shadow-lg` + `scale` 变化。`tw-animate-css` 已安装但未使用。

`frontend/package.json` 当前依赖：`next@^15.0.0`、`react@^19.2.8`、`tailwindcss@^4.3.3`、`shadcn@^4.21.0`、`lucide-react@^1.44.0`、`tw-animate-css@^1.4.0`。

视觉设计详细规格已记录在 `docs/homepage-visual-upgrade-design.md`，本 design.md 聚焦技术决策。

## Goals / Non-Goals

**Goals:**
- 将灰度 CSS 变量替换为中国红 + 金色品牌色彩系统（仅亮色模式）
- 实现 Hero 区品牌渐变叠加层 + 毛玻璃搜索框
- 实现 Header/Footer 品牌视觉升级（毛玻璃、渐变边线）
- 为所有首页卡片添加统一的品牌装饰条与 hover 浮起效果
- 实现 IntersectionObserver 驱动的滚动入场动画体系
- 为 AI Widget 悬浮按钮添加渐变边框与呼吸光晕
- 新增区块分隔组件，增强区块间视觉过渡
- 确保 `prefers-reduced-motion` 下所有动效完全降级

**Non-Goals:**
- 暗色模式品牌适配（`.dark` 保持不变）
- 引入第三方动画库（Framer Motion 等）
- 新增页面或路由
- Header 导航菜单扩展
- 字体更换（保持 Geist Sans）
- 性能调优 / Core Web Vitals 优化

## Decisions

### 1. 色彩系统实现：CSS 自定义属性替换

**决策:** 直接修改 `globals.css` 中 `:root` 块的 CSS 自定义属性值，将灰度 oklch 值替换为品牌色 hex 值。渐变通过新增 `--gradient-brand`、`--gradient-hero-overlay`、`--gradient-card-accent` 三个 CSS 自定义属性实现。

**理由:**
- CSS 自定义属性是 shadcn/ui 主题系统的标准扩展方式，所有 `bg-primary`、`text-primary` 等 Tailwind 类自动继承新值
- 渐变通过 CSS 变量定义、组件通过 Tailwind 任意值语法 `bg-[var(--gradient-brand)]` 引用，保持单一数据源
- 仅修改 `:root` 块，`.dark` 块完全不动，确保暗色模式不受影响

**替代方案:** 创建独立的 `brand-theme.css` 文件 — rejected，增加文件分裂，不如直接修改 `:root` 直观。

### 2. 入场动画实现：IntersectionObserver + CSS @keyframes

**决策:** 封装 `useScrollReveal` Hook（原生 `IntersectionObserver`，`threshold: 0.15`），通过设置 `data-visible="true"` 属性触发 CSS `@keyframes fade-slide-up` 动画。不引入 Framer Motion 或其他动画库。

**理由:**
- 原生 `IntersectionObserver` 性能优于 scroll 事件监听，浏览器原生支持
- CSS `@keyframes` 动画仅操作 `opacity` + `transform`（GPU 加速属性），不触发 layout
- `tw-animate-css` 已安装但仅提供预设动画类，自定义 `@keyframes` 更灵活
- 无新依赖，零额外包体积

**替代方案:** 使用 `tw-animate-css` 的预设动画类 — rejected，预设类无法精确控制延迟递增和触发时机。使用 Framer Motion — rejected，引入重依赖，对简单入场动画过度。

### 3. 毛玻璃效果实现：Tailwind backdrop-blur 工具类

**决策:** Header 使用 `backdrop-blur-lg bg-background/80`，Hero 搜索框使用 `backdrop-blur-md bg-white/15 border-white/25`。

**理由:**
- Tailwind CSS 4 原生支持 `backdrop-blur-*`，无需额外 CSS
- `backdrop-filter` 在现代浏览器中支持良好（Chrome 52+, Firefox 103+, Safari 9+）
- 与品牌色彩系统无耦合，可独立调整

**替代方案:** CSS `filter: blur()` 伪元素模拟 — rejected，增加 DOM 复杂度，Tailwind 工具类已足够。

### 4. 区块分隔组件：独立 Server Component

**决策:** 创建 `components/ui/section-divider.tsx` 作为 Server Component（无交互逻辑），在 `page.tsx` 中插入于 Navigation-Destinations 和 Destinations-Community 之间。

**理由:**
- 纯视觉装饰，无状态无交互，Server Component 零客户端 JS
- 放在 `components/ui/` 与 `button.tsx`、`input.tsx` 同级，符合共享 UI 组件惯例
- 在 `page.tsx` 中显式插入，比在各 section 组件内部添加分隔更清晰

**替代方案:** 在各 section 组件内部添加 `::after` 伪元素分隔 — rejected，耦合 section 组件与视觉装饰，违反单一职责。

### 5. AI Widget 呼吸光晕：CSS @keyframes box-shadow 脉动

**决策:** 在 `globals.css` 中新增 `@keyframes glow-pulse` 动画，通过 `box-shadow` 在 `rgba(196,30,58,0.4)` 与透明之间脉动，周期 2s。渐变边框通过 `border-image` 或包裹层实现。

**理由:**
- `box-shadow` 动画为合成属性动画，现代浏览器可 GPU 加速
- CSS `@keyframes` 实现呼吸效果最简洁，无需 JS 定时器
- `prefers-reduced-motion` 全局规则自动降级

**替代方案:** JS `setInterval` 动态修改 `box-shadow` — rejected，性能差且增加复杂度。

### 6. 文件组织

**决策:**
- `frontend/src/lib/use-scroll-reveal.ts` — IntersectionObserver Hook
- `frontend/src/components/ui/section-divider.tsx` — 分隔组件
- 其余变更在现有文件内修改

**理由:** 与现有 `lib/`（工具函数）和 `components/ui/`（共享 UI 组件）目录职责一致。

## Risks / Trade-offs

- **[毛玻璃浏览器兼容性]** → `backdrop-filter` 在 IE 中不支持，但项目目标为现代浏览器，可接受。降级方案：不支持的浏览器渲染为半透明纯色背景，内容仍可读。
- **[入场动画性能]** → 大量同时触发的入场动画可能造成首帧卡顿 → 动画仅操作 `opacity` + `transform`（GPU 合成层），6 张卡片 stagger 延迟分散渲染压力。
- **[品牌色全局影响]** → 修改 `--primary` 会影响所有使用 `bg-primary`/`text-primary` 的组件（包括 AI Widget 按钮、shadcn Button 默认变体） → 这正是预期效果：品牌色贯穿全站。AI Widget 按钮变红符合设计意图。
- **[渐变边框实现复杂度]** → CSS 原生不支持 `border-image` + `border-radius` 组合 → 可通过包裹层 `bg-gradient` + 内层 `bg-background` 的嵌套方案实现，或使用 `border-image-slice` 配合 `border-image-source`。需在实施时验证具体方案。
- **[视觉设计文档与 spec 一致性]** → `docs/homepage-visual-upgrade-design.md` 与 `spec.md` 可能存在措辞差异 → `spec.md` 为权威源，`design.md` 为参考文档。实施时以 spec 为准。
