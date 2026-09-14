## Why

当前 ChinaBuddy 首页已完成功能实现（Hero 区、导航卡片、目的地推荐、社区精选、AI 悬浮窗），但视觉层面仍使用 shadcn/ui 默认灰度主题——`--primary` 为深灰色、`--background` 为纯白、所有卡片仅灰框白底。整体缺乏品牌辨识度，与"Discover China Like a Local"的产品定位不匹配。

本变更将首页从灰度中性主题全面升级为中国红（`#C41E3A`）+ 金色（`#D4A017`）的品牌视觉体系，引入毛玻璃效果、品牌渐变、入场动画与精致 hover 过渡，使首页在视觉上更具吸引力和现代感，同时确保布局、交互和响应式表现符合现代网页最佳实践。

## What Changes

- **色彩系统**：将 `globals.css` 中 `:root` CSS 自定义属性从灰度值替换为中国红 + 金色品牌色 + 暖色中性色，新增 3 个渐变预设
- **Hero 区**：背景图叠加品牌红-金渐变层、标题文字阴影增强、搜索框重构为毛玻璃胶囊样式、容器高度微调
- **Header**：背景改为毛玻璃半透明、底部边线替换为品牌渐变线、品牌名 hover 变色、AI 链接增加圆点指示器
- **Footer**：背景改为深色（近黑）、顶部替换为品牌渐变线、链接 hover 变金色、品牌名金色高亮
- **区块分隔**：新增 `<SectionDivider />` 共享组件，在 Navigation-Destinations 和 Destinations-Community 之间插入金色菱形装饰分隔线
- **卡片升级**：Navigation / Destinations / Community 卡片统一增加底部品牌渐变装饰条、hover 浮起效果、品牌色图标/标签
- **AI Widget**：悬浮按钮增加品牌渐变边框与呼吸光晕动效
- **入场动画**：新增 `useScrollReveal` Hook（IntersectionObserver），各区块卡片依次 fade-in + slide-up
- **响应式**：新增 `lg:` 断点容器扩展、移动端装饰条位置适配
- **无障碍**：`prefers-reduced-motion` 全局降级规则

## Capabilities

### New Capabilities

无新增独立 capability。本次变更为跨模块视觉升级，不引入新的独立功能单元。

### Modified Capabilities

- `homepage-shell`：Header 视觉（毛玻璃背景 + 品牌渐变底边）、Footer 视觉（深色背景 + 品牌渐变顶线）、布局容器 `lg:` 断点扩展、区块间新增 `<SectionDivider />`
- `homepage-hero`：背景图品牌渐变叠加层、标题文字阴影、搜索框毛玻璃胶囊化、容器高度调整
- `homepage-navigation`：卡片底部装饰条、图标品牌色、hover 浮起效果
- `homepage-destinations`：封面图叠加层、城市名重定位、人气标签毛玻璃化、装饰竖线、入场动画
- `homepage-community`：头像品牌边框、点赞图标品牌色、底部装饰条、入场动画
- `homepage-ai-widget`：悬浮按钮渐变边框、呼吸光晕动效

## Impact

**代码**：
- 新增 2 个文件：`frontend/src/lib/use-scroll-reveal.ts`（IntersectionObserver Hook）、`frontend/src/components/ui/section-divider.tsx`（分隔组件）
- 修改 12 个文件：`globals.css`、`page.tsx`、`header.tsx`、`footer.tsx`、`hero-section.tsx`、`hero-background.tsx`、`search-form.tsx`、`navigation-section.tsx`、`destinations-section.tsx`、`destination-card.tsx`、`community-section.tsx`、`post-card.tsx`
- 不修改：`layout.tsx`、`skip-to-content.tsx`、`ai-widget.tsx` 内部逻辑（仅视觉 class 变更）、`button.tsx`、`input.tsx`、所有 API 层文件

**依赖**：无新增依赖。所有视觉效果通过 Tailwind CSS 4 + CSS 自定义属性 + 原生 `IntersectionObserver` 实现，不引入 Framer Motion 等第三方动画库。

**前置依赖**：
- `introduce-frontend-styling-infra`（Tailwind CSS + shadcn/ui + lucide-react 已安装）
- 所有 homepage 功能变更已归档（shell / hero / navigation / destinations / community / ai-widget）

**后续依赖**：
- 本变更为纯视觉升级，不阻塞任何后续功能变更
- 暗色模式品牌适配可作为独立后续变更

**视觉设计详细文档**：
- `docs/homepage-visual-upgrade-design.md` 包含完整的色彩定义、渐变预设、各组件视觉规格
