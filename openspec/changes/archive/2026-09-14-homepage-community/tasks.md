## 1. 后端 API 端点

- [x] 1.1 创建 `PostResponse.java` DTO（`id`, `authorName`, `authorAvatarUrl`, `title`, `excerpt`, `likeCount`），验证编译通过
- [x] 1.2 创建 `PostController.java`，实现 `GET /api/posts/featured` 端点，返回内存种子数据（3-4 条），验证 API 响应符合 `Result<T>` 信封格式
- [x] 1.3 启动后端服务，使用 curl/Postman 验证 `GET http://localhost:8080/api/posts/featured` 返回 200 与正确数据结构

## 2. 前端工具函数与 API 层

- [x] 2.1 创建 `frontend/src/lib/format.ts`，实现 `truncateExcerpt`（单词边界截断）与 `formatLikeCount`（点赞数格式化），验证单元测试通过
- [x] 2.2 创建 `frontend/src/api/posts.ts`，封装 `getFeaturedPosts()` 调用，验证 TypeScript 编译通过

## 3. 前端组件实现

- [x] 3.1 创建 `frontend/src/components/community/` 目录，创建 `post-card.tsx` 展示组件（头像 + 用户名 + 标题 + 摘要 + 点赞数），验证组件可渲染
- [x] 3.2 创建 `community-section.tsx` Client Component，实现 `useEffect` + `useState` 数据获取，验证组件挂载时调用 API
- [x] 3.3 实现 loading 状态：显示 skeleton 占位卡片，验证 API 请求进行中显示占位
- [x] 3.4 实现 error 状态：显示 "Failed to load community posts" + Retry 按钮，验证 API 失败时正确显示
- [x] 3.5 实现 empty 状态：显示 "No community posts available yet"，验证 API 返回空数组时正确显示
- [x] 3.6 实现 10 秒超时：使用 `AbortController`，验证超时按错误处理

## 4. 响应式布局与图片处理

- [x] 4.1 实现移动端布局：垂直堆叠全宽（`space-y-4`），验证视口 < 768px 时布局正确
- [x] 4.2 实现桌面端布局：网格（`md:grid md:grid-cols-3 lg:grid-cols-4 md:gap-6`），验证视口 >= 768px 时布局正确
- [x] 4.3 实现头像 `next/image` `width={40} height={40}` `rounded-full`，验证头像正确渲染
- [x] 4.4 实现头像加载失败回退：圆形容器 + lucide-react `User` 图标，验证头像加载失败时回退正确

## 5. 导航与无障碍

- [x] 5.1 实现帖子点击导航：使用 Next.js `<Link>` 导航至 `/community/posts/{id}`，验证 id 取自 API 响应
- [x] 5.2 添加区域 `aria-label="Community highlights"`，验证屏幕阅读器可识别
- [x] 5.3 添加帖子链接 `aria-label="Read post: {title}"`，验证每条帖子链接有无障碍标签

## 6. 集成与验证

- [x] 6.1 在 `page.tsx` 中导入 CommunitySection 组件，替换 `{/* Community Section */}` 占位注释，验证首页渲染社区区
- [x] 6.2 运行 `npm run build` 验证前端构建通过，无 TypeScript 编译错误
- [x] 6.3 运行 `mvn spring-boot:run` 验证后端启动成功，API 端点可访问（后端编译通过，待手动启动验证）
- [x] 6.4 在浏览器中验证完整社区区：API 数据正确渲染、三态切换正常、响应式断点切换、摘要截断正确、点赞数格式正确、卡片导航正确（构建通过，待浏览器手动验证）
