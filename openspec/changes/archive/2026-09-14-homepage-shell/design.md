## Context

当前 `frontend/src/app/page.tsx` 仅包含 `redirect('/users')`，无任何首页骨架。样式基础设施（Tailwind CSS v4、shadcn/ui、lucide-react）已在 `introduce-frontend-styling-infra` 变更中安装并验证。`homepage-shell` main spec 已定义完整的页面结构需求。本设计聚焦如何将这些需求落地为可维护的组件架构。

## Goals / Non-Goals

**Goals:**
- 实现符合 `homepage-shell` spec 全部验收标准的 Server Component 页面骨架
- 组件拆分清晰：header、footer、skip-to-content 各自独立，便于测试与维护
- 为后续 5 个 homepage 功能区域提供明确的 section slot 挂载点
- 占位页面（Coming soon）可复用，不限于 footer 链接

**Non-Goals:**
- 不实现任何 section 的业务内容（hero、navigation 等由各自变更负责）
- 不引入新的 npm 依赖
- 不实现 AI widget 的交互逻辑（仅预留锚点链接，实际行为由 `homepage-ai-widget` 变更实现）
- 不处理认证、国际化或 SEO 优化

## Decisions

### Decision 1: 组件文件结构

采用 `frontend/src/components/layout/` 目录存放页面骨架组件：

```
src/
  app/
    page.tsx              ← 首页 Server Component（组合所有 layout 组件）
    layout.tsx            ← 根布局（更新 metadata）
    coming-soon/
      page.tsx            ← 占位页面
  components/
    layout/
      header.tsx          ← Sticky header（Server Component）
      footer.tsx          ← Footer（Server Component）
      skip-to-content.tsx ← Skip 链接（Client Component — 需要 onClick 焦点管理）
```

**理由**：与 `components/ui/`（shadcn/ui 原子组件）分离，`layout/` 明确标识页面级骨架组件。后续 homepage 功能区域组件可放入 `components/homepage/` 目录。

**替代方案**：将所有骨架代码内联在 `page.tsx` 中——拒绝，因为 header/footer 各自包含多个 scenario（sticky、响应式、占位链接），内联会导致单文件超过 100 行且难以独立测试。

### Decision 2: Skip-to-content 实现为 Client Component

Skip-to-content 链接需要 `onClick` 事件处理来程序化移动焦点至 `<main>` 元素，因此必须标记为 `"use client"`。

**理由**：React Server Component 无法处理客户端交互事件。`useRef` + `onClick` 需要客户端运行时。

**替代方案**：使用纯 HTML `<a href="#main">` 锚点跳转——拒绝，因为虽然原生锚点可滚动到目标，但 spec 要求"焦点移至 `<main>` 元素"，需要 `element.focus()` 程序化控制。

### Decision 3: Section Slot 实现策略

采用直接导入+条件渲染模式，而非抽象 slot 包装组件：

```tsx
{/* page.tsx 中的 section slot 区域 */}
<HeroSection />      {/* 本变更中为空占位 */}
<NavigationSection /> {/* 本变更中为空占位 */}
{/* ... */}
```

本变更阶段，各 section 组件尚未实现，`page.tsx` 中预留注释占位标记各 slot 位置，不导入任何 section 组件。`<main>` 内容区仅包含 section slot 注释和最小高度占位，确保布局不折叠。

**理由**：与 main spec 的 "Section Slot 契约" 一致——"shell 不提供额外的 slot 包装组件"。后续各 section 变更只需在 `page.tsx` 中添加导入和组件渲染。

**替代方案**：创建 `<SectionSlot name="hero">` 包装组件——拒绝，违反 spec 明确声明的"不提供额外 slot 包装组件"。

### Decision 4: AI Assistant 链接行为

Header 中的 AI assistant 链接在本变更阶段实现为普通 `<a>` 锚点（`href="#ai-assistant"`），不触发任何 widget 交互。spec 中的 "AI widget 的迷你对话窗 SHALL 打开" 场景依赖 `homepage-ai-widget` 变更实现 widget 后方可验证。

**理由**：AI widget 为 fixed 悬浮层，不在本变更范围内。提前实现交互逻辑会产生死代码。

### Decision 5: Coming Soon 占位页面

创建 `frontend/src/app/coming-soon/page.tsx` 作为独立路由页面，显示 "Coming soon" 文本和返回首页链接。使用 Tailwind 基础样式居中显示。

**理由**：spec 要求占位链接导航至 "Coming soon" 页面且提供返回首页链接。独立路由比模态框或内联提示更易于后续复用（其他未实现页面也可指向此路由）。

## Risks / Trade-offs

- **[Risk] Section slot 空占位可能导致视觉空白** → Mitigation：`<main>` 设置 `min-h-[50vh]` 确保骨架有视觉存在感，同时各 slot 位置以注释标记便于后续实现定位
- **[Risk] AI assistant 链接在本阶段无实际功能** → Mitigation：使用 `#ai-assistant` 锚点，`homepage-ai-widget` 变更实施后将替换为实际交互逻辑。在代码中添加 TODO 注释标注
- **[Risk] Skip-to-content Client Component 增加客户端 JS bundle** → Mitigation：该组件极小（< 1KB），影响可忽略。且 skip 链接是无障碍基线要求，不可省略
