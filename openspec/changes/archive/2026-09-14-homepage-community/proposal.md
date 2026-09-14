## Why

当前首页 \rontend/src/app/page.tsx\ 的 Community Section 区域仅为占位注释（\{/* Community Section */}\），尚未实现任何内容。\homepage-community\ spec 已定义了完整的社区精选区需求——3-4 条 UGC 帖子摘要展示、\GET /api/posts/featured\ API 集成（含 loading/error/empty 三态）、摘要截断、点赞数格式化、头像图片处理——但代码层面尚未落地。本变更将 spec 落地为可运行的社区精选区组件，让访客浏览真实旅行者经验。

## What Changes

- 新增社区区 Client Component（\rontend/src/components/community/community-section.tsx\），含 API 数据获取与三态渲染
- 新增社区帖子卡片组件（\rontend/src/components/community/post-card.tsx\），含头像、用户名、标题、摘要（截断）、点赞数
- 新增后端 API 端点 \GET /api/posts/featured\，返回内存种子数据（MVP 阶段）
- 在 \page.tsx\ 中导入并渲染 CommunitySection 组件，替换占位注释
- 实现摘要单词边界截断（最多 120 字符 + "..."）
- 实现点赞数人类可读格式化（如 "1.2k"）
- 响应式布局：移动端垂直堆叠，桌面端网格（\md:grid md:grid-cols-3 lg:grid-cols-4\）

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- \homepage-community\：从占位注释变为完整社区精选区实现——覆盖帖子展示、API 集成、三态渲染、摘要截断、点赞数格式化、头像处理的全部 spec 要求

## Impact

**前端代码**：
- \rontend/src/app/page.tsx\：导入 CommunitySection 组件，替换 \{/* Community Section */}\ 占位注释
- \rontend/src/components/community/community-section.tsx\：新增（Client Component，API 获取 + 三态渲染）
- \rontend/src/components/community/post-card.tsx\：新增（帖子卡片组件）
- \rontend/src/api/posts.ts\：新增（API 调用封装）
- \rontend/src/lib/format.ts\：新增（点赞数格式化工具函数）

**后端代码**：
- \ackend/src/main/java/com/example/myfirst/controller/PostController.java\：新增（\GET /api/posts/featured\）
- \ackend/src/main/java/com/example/myfirst/dto/response/PostResponse.java\：新增（响应 DTO）
- 内存种子数据：Controller 内硬编码 3-4 条精选帖子（MVP 阶段，后续接入数据库）

**依赖**：无新增依赖。\
ext/image\、\lucide-react\、shadcn/ui 组件已在 \introduce-frontend-styling-infra\ 变更中安装。

**前置依赖**：
- \introduce-frontend-styling-infra\ 变更（Tailwind CSS + shadcn/ui + lucide-react 已安装并验证构建管线）
- \homepage-shell\ 变更（页面骨架已完成，section slot 挂载点就绪）

**后续依赖**：
- 帖子详情页 \/community/posts/{id}\ 由独立 spec 实现，MVP 阶段 404 可接受
