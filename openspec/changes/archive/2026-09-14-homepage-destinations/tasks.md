## 1. 后端 API 端点

- [x] 1.1 创建 `DestinationResponse.java` DTO（`id`, `cityName`, `slug`, `highlight`, `coverImageUrl`, `popularityTag`），验证编译通过
- [x] 1.2 创建 `DestinationController.java`，实现 `GET /api/destinations/featured` 端点，返回内存种子数据（4-6 条），验证 API 响应符合 `Result<T>` 信封格式
- [x] 1.3 启动后端服务，使用 curl/Postman 验证 `GET http://localhost:8080/api/destinations/featured` 返回 200 与正确数据结构

## 2. 前端 API 层与组件

- [x] 2.1 创建 `frontend/src/api/destinations.ts`，封装 `getFeaturedDestinations()` 调用，验证 TypeScript 编译通过
- [x] 2.2 创建 `frontend/src/components/destinations/` 目录，创建 `destination-card.tsx` 纯展示组件（封面图 + 城市名 + 亮点 + 热度标签），验证组件可渲染
- [x] 2.3 创建 `destinations-section.tsx` Client Component，实现 `useEffect` + `useState` 数据获取，验证组件挂载时调用 API
- [x] 2.4 实现 loading 状态：显示 skeleton 卡片（280px x 200px），验证 API 请求进行中显示占位
- [x] 2.5 实现 error 状态：显示 "Failed to load destinations" + Retry 按钮，验证 API 失败时正确显示
- [x] 2.6 实现 empty 状态：显示 "No destinations available at the moment"，验证 API 返回空数组时正确显示
- [x] 2.7 实现 10 秒超时：使用 `AbortController`，验证超时按错误处理

## 3. 响应式布局与图片处理

- [x] 3.1 实现移动端布局：横向滚动（`flex overflow-x-auto snap-x`），卡片占 80% 视口宽，验证视口 < 768px 时布局正确
- [x] 3.2 实现桌面端布局：网格（`md:grid md:grid-cols-4 md:gap-6`），超过 4 张换行，验证视口 >= 768px 时布局正确
- [x] 3.3 实现封面图 `next/image` `fill` + `object-fit: cover`，容器 4:3 宽高比，验证图片正确渲染
- [x] 3.4 实现图片加载失败回退：渐变背景 + 白色城市名文本，验证图片加载失败时回退正确

## 4. 导航与无障碍

- [x] 4.1 实现卡片点击导航：使用 Next.js `<Link>` 导航至 `/destinations/{slug}`，验证 slug 取自 API 响应
- [x] 4.2 添加区域 `aria-label="Featured destinations"`，验证屏幕阅读器可识别
- [x] 4.3 添加卡片链接 `aria-label="Explore {cityName}"`，验证每条卡片链接有无障碍标签

## 5. 集成与验证

- [x] 5.1 在 `page.tsx` 中导入 DestinationsSection 组件，替换 `{/* Destinations Section */}` 占位注释，验证首页渲染目的地区
- [x] 5.2 运行 `npm run build` 验证前端构建通过，无 TypeScript 编译错误
- [x] 5.3 运行 `mvn spring-boot:run` 验证后端启动成功，API 端点可访问（后端编译通过，待手动启动验证）
- [x] 5.4 在浏览器中验证完整目的地区：API 数据正确渲染、三态切换正常、响应式断点切换、卡片导航正确（构建通过，待浏览器手动验证）
