## Purpose

为 ChinaBuddy 首页提供 Hero 区——访客第一眼看到的视觉区域。通过背景图、主标题、副标题和搜索输入框传达品牌价值主张，让有明确目的地的用户可直接跳转到相关内容（US-H3：搜索直达目标内容）。

## In Scope

1. 全宽品牌背景图（含降级回退）
2. 品牌主标题（`<h1>`）
3. 品牌副标题（`<p>`）
4. 带"提交即跳转"行为的搜索输入框
5. 响应式布局（Tailwind mobile-first 断点）

## Requirements

### Requirement: 品牌背景图
Hero 区 SHALL 显示代表品牌视觉形象的全宽背景图，使用 `next/image` 组件实现。

#### Scenario: 图片正常加载
- **WHEN** 首页加载
- **AND** 背景图源 URL 有效且可达
- **THEN** Hero 区 SHALL 渲染带 `fill` prop 的 `next/image` 组件，铺满容器全宽
- **AND** 图片 SHALL 使用 `priority` prop 禁用懒加载（LCP 元素）
- **AND** 容器 SHALL 移动端最小高度 300px、桌面端最小高度 500px

#### Scenario: 图片加载失败
- **WHEN** 背景图加载失败（网络错误或资源缺失）
- **THEN** Hero 区 SHALL 显示纯色回退背景（`#1a1a2e`）而非破图
- **AND** 所有前景内容（标题、副标题、搜索框）SHALL 保持可见可读

#### Scenario: 移动端图片定位
- **WHEN** 视口宽度小于 768px
- **THEN** 背景图 SHALL 使用 `object-position: center top` 优先展示图片上部
- **AND** 容器高度 SHALL 最小为 300px

#### Scenario: 桌面端图片定位
- **WHEN** 视口宽度为 768px 及以上
- **THEN** 背景图 SHALL 使用 `object-position: center center`
- **AND** 容器高度 SHALL 最小为 500px

### Requirement: 品牌主标题
Hero 区 SHALL 以醒目位置显示标题文本 "Discover China Like a Local"。

#### Scenario: 标题可见性
- **WHEN** Hero 区被渲染
- **THEN** 标题 SHALL 以 `<h1>` 元素显示，文本精确为 "Discover China Like a Local"
- **AND** `<h1>` SHALL 使用 Tailwind 响应式字号（如 `text-3xl md:text-5xl lg:text-6xl`）

### Requirement: 副标题
Hero 区 SHALL 在标题正下方显示副标题 "Your AI-powered travel companion for exploring China"。

#### Scenario: 副标题可见性
- **WHEN** Hero 区被渲染
- **THEN** 副标题 SHALL 以 `<p>` 元素显示，文本精确为 "Your AI-powered travel companion for exploring China"
- **AND** 副标题 SHALL 使用 Tailwind 响应式字号（如 `text-base md:text-lg`）

### Requirement: 搜索输入框
Hero 区 SHALL 提供占位文本为 "Search destinations, tips, or ask AI..." 的搜索输入框，允许用户搜索特定内容。搜索输入框 SHALL 使用 shadcn/ui `Input` 与 `Button` 组件实现。搜索表单 SHALL 实现为嵌套 Client Component（`"use client"`，交互逻辑所需）。

#### Scenario: 搜索框存在
- **WHEN** Hero 区被渲染
- **THEN** 搜索输入框 SHALL 可见，占位文本为 "Search destinations, tips, or ask AI..."
- **AND** 输入框 SHALL 具有 `aria-label="Search destinations, tips, or ask AI"` 以支持屏幕阅读器
- **AND** 搜索图标按钮（lucide-react 的 `Search` 图标）SHALL 位于输入框右侧

#### Scenario: 用户提交搜索
- **WHEN** 用户在搜索框输入 "Chengdu"
- **AND** 用户按下 Enter 或点击搜索图标按钮
- **THEN** 系统 SHALL 导航至 `/search?q=Chengdu`，携带输入的查询作为 URL 参数
- **AND** 搜索输入框 SHALL 保留已输入的查询文本

#### Scenario: 空搜索提交
- **WHEN** 用户提交空输入的搜索表单
- **THEN** 系统 SHALL NOT 导航
- **AND** SHALL 在输入框下方显示校验提示 "Please enter a search term"

#### Scenario: 纯空白搜索提交
- **WHEN** 用户提交仅含空白字符的输入（如 `"   "`）
- **THEN** 系统 SHALL 将其视为空输入
- **AND** SHALL NOT 导航
- **AND** SHALL 显示校验提示 "Please enter a search term"

#### Scenario: 搜索输入最大长度
- **WHEN** 用户输入或粘贴超过 200 字符的文本
- **THEN** 输入框 SHALL 拒绝超出 200 字符限制的字符
- **AND** SHALL 显示提示 "Search query is too long (max 200 characters)"

#### Scenario: XSS 安全渲染
- **WHEN** 搜索输入包含 HTML 或脚本内容（如 `<script>alert(1)</script>`）
- **THEN** 输入框 SHALL 以纯文本渲染该内容，不执行任何脚本
- **AND** 导航 URL 的查询参数 SHALL 经过正确的 URL 编码

#### Scenario: 搜索框焦点
- **WHEN** 用户点击或 Tab 至搜索输入框
- **THEN** 输入框 SHALL 获得焦点并显示可见焦点环（Tailwind `focus-visible:ring-2`）

#### Scenario: 防止重复提交
- **WHEN** 导航进行中用户点击搜索按钮
- **THEN** 系统 SHALL NOT 触发重复导航

### Requirement: 响应式行为
Hero 区 SHALL 使用 Tailwind CSS mobile-first 断点前缀适配不同视口尺寸。

#### Scenario: 移动端布局
- **WHEN** 视口宽度小于 768px（Tailwind 默认基础样式，无 `md:` 前缀）
- **THEN** Hero 区 SHALL 使用垂直堆叠布局，垂直内边距 24px
- **AND** 标题 SHALL 使用 `text-3xl` 字号
- **AND** 搜索输入框 SHALL 全宽显示

#### Scenario: 桌面端布局
- **WHEN** 视口宽度为 768px 及以上（`md:` 断点）
- **THEN** Hero 区 SHALL 使用居中布局，标题字号 `text-5xl`
- **AND** 内容容器 SHALL 最大宽度 1200px，水平自动外边距

### Requirement: 首屏性能
Hero 区是最大内容绘制（LCP）元素，SHALL 满足性能目标。

#### Scenario: LCP 目标
- **WHEN** 首页在模拟 4G 连接（Moto G Power 配置）下加载
- **THEN** LCP 指标 SHALL 低于 2.5 秒
- **AND** 背景图 SHALL 通过 `next/image` 的 `priority` prop 预加载

## Data Structures

### HeroSectionProps

```typescript
interface HeroSectionProps {
  /** 背景图的 URL 或静态导入 */
  backgroundImage: string;
  /** 背景图的 alt 文本（无障碍） */
  backgroundAlt?: string; // 默认: ""
  /** 品牌主标题文本 */
  headline?: string; // 默认: "Discover China Like a Local" | 最大 100 字符
  /** 品牌副标题文本 */
  subtitle?: string; // 默认: "Your AI-powered travel companion for exploring China" | 最大 200 字符
  /** 搜索输入框占位文本 */
  searchPlaceholder?: string; // 默认: "Search destinations, tips, or ask AI..."
}
```

### SearchFormProps（嵌套 Client Component）

```typescript
interface SearchFormProps {
  /** 搜索输入框占位文本 */
  placeholder?: string; // 默认: "Search destinations, tips, or ask AI..."
  /** 允许的最大输入长度 */
  maxLength?: number; // 默认: 200 | 约束: 50–500
}
```

## Acceptance Checklist

### 结构与布局
- [ ] Hero 区作为首页的一部分渲染于 `/` 路由
- [ ] 背景图使用 `next/image` 的 `fill` prop 铺满全宽
- [ ] 背景图已设置 `priority` prop（LCP 元素）
- [ ] 容器移动端最小高度 300px、桌面端 500px
- [ ] 背景图移动端 `object-position: center top`，桌面端 `center center`

### 内容
- [ ] 标题以 `<h1>` 渲染，文本精确为 "Discover China Like a Local"
- [ ] 副标题以 `<p>` 渲染，文本精确为 "Your AI-powered travel companion for exploring China"
- [ ] 标题使用响应式字号（`text-3xl md:text-5xl`）
- [ ] 副标题使用响应式字号（`text-base md:text-lg`）

### 搜索
- [ ] 搜索框占位文本为 "Search destinations, tips, or ask AI..."
- [ ] 搜索框 `aria-label` 与占位文本一致
- [ ] 搜索图标按钮（lucide-react `Search` 图标）位于输入框右侧
- [ ] 提交非空查询导航至 `/search?q={query}`
- [ ] 提交空输入不导航并显示 "Please enter a search term"
- [ ] 纯空白输入按空输入处理
- [ ] 输入框拒绝超过 200 字符的字符
- [ ] 输入的 HTML/脚本内容以纯文本渲染（XSS 安全）
- [ ] 导航进行中禁止重复提交

### 响应式
- [ ] 移动端（< 768px）：堆叠布局、24px 垂直内边距、搜索框全宽
- [ ] 桌面端（≥ 768px）：居中布局、最大宽度 1200px 容器

### 错误处理
- [ ] 图片加载失败显示回退色 `#1a1a2e`，所有前景内容可见
- [ ] 输入框聚焦时焦点环可见（`focus-visible:ring-2`）

### 性能
- [ ] 模拟 4G 连接下 LCP < 2.5s

## Out of Scope

- 搜索结果页实现 — 属于独立的搜索 spec
- 搜索建议或自动补全下拉
- 动态背景图轮播或用户个性化图片
- 搜索历史或最近查询
- 搜索结果排序或过滤逻辑
- 国际化（i18n）/ 搜索多语言支持
- 背景视频或动画 Hero 效果
- 搜索输入语音输入或基于地理位置的建议
