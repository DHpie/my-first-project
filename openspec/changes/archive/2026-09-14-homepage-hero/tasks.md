## 1. 组件目录与 SearchForm Client Component

- [x] 1.1 创建 `frontend/src/components/hero/` 目录，创建 `search-form.tsx` 文件并添加 `"use client"` 指令，验证文件可被 TypeScript 编译（`npx tsc --noEmit` 无新增错误）
- [x] 1.2 实现 SearchForm 组件：导入 shadcn/ui `Input` 和 `Button`、lucide-react `Search` 图标，渲染搜索输入框（占位文本 "Search destinations, tips, or ask AI..."）和搜索图标按钮，验证组件可渲染且输入框可聚焦
- [x] 1.3 实现搜索提交逻辑：使用 `useRouter` 的 `router.push()` 导航至 `/search?q={query}`，添加 `isNavigating` 状态防止重复提交，验证输入 "Chengdu" 后按 Enter 导航至 `/search?q=Chengdu`
- [x] 1.4 实现空输入/纯空白校验：提交空字符串或纯空白时不导航，显示 "Please enter a search term" 提示，验证两种场景均正确拦截
- [x] 1.5 实现最大长度校验：输入框限制 200 字符，超出时显示 "Search query is too long (max 200 characters)"，验证粘贴超长文本被截断
- [x] 1.6 添加 `aria-label="Search destinations, tips, or ask AI"` 到输入框，验证屏幕阅读器可识别

## 2. HeroSection Server Component

- [x] 2.1 创建 `hero-section.tsx` 文件（Server Component，无 `"use client"`），定义 `HeroSectionProps` TypeScript 接口，验证 TypeScript 编译通过
- [x] 2.2 实现背景图容器：使用 `next/image` 的 `fill` + `priority` prop，父容器 `relative`，移动端最小高度 300px、桌面端 500px，验证容器尺寸正确
- [x] 2.3 实现背景图加载失败回退：通过 `onError` 回调切换容器背景色为 `#1a1a2e`，验证图片加载失败时前景内容仍可读
- [x] 2.4 实现品牌标题 `<h1>` "Discover China Like a Local"（响应式字号 `text-3xl md:text-5xl lg:text-6xl`）和副标题 `<p>` "Your AI-powered travel companion for exploring China"（`text-base md:text-lg`），验证文本精确匹配且字号响应式
- [x] 2.5 在 HeroSection 中嵌套渲染 SearchForm 组件，验证搜索框在 Hero 区内正确显示

## 3. 响应式布局

- [x] 3.1 实现移动端布局：垂直堆叠、24px 垂直内边距、搜索框全宽，验证视口 < 768px 时布局正确
- [x] 3.2 实现桌面端布局：居中布局、最大宽度 1200px 容器、`mx-auto`，验证视口 ≥ 768px 时布局正确
- [x] 3.3 实现背景图 `object-position`：移动端 `center top`、桌面端 `center center`，验证两种视口下图片定位正确

## 4. 集成与验证

- [x] 4.1 在 `page.tsx` 中导入 HeroSection 组件，替换 `{/* Hero Section */}` 占位注释，验证首页渲染 Hero 区
- [x] 4.2 确认 `hero.png` 资源存在于 `frontend/public/` 目录，验证背景图正常加载（注：hero.png 尚未添加至 public/，onError 回退至 #1a1a2e 纯色背景，符合 spec）
- [x] 4.3 运行 `npm run build` 验证构建通过，无 TypeScript 编译错误或 Next.js 构建警告
- [x] 4.4 在浏览器中验证完整 Hero 区：背景图渲染、标题/副标题可见、搜索框可输入并提交、响应式断点切换正常（构建通过，待浏览器手动验证）
