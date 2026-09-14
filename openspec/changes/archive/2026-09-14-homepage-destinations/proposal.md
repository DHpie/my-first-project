## Why

当前首页 \rontend/src/app/page.tsx\ 的 Destinations Section 区域仅为占位注释（\{/* Destinations Section */}\），尚未实现任何内容。\homepage-destinations\ spec 已定义了完整的热门目的地区需求——4-6 张目的地卡片网格、\GET /api/destinations/featured\ API 集成（含 loading/error/empty 三态）、响应式布局与卡片导航——但代码层面尚未落地。本变更将 spec 落地为可运行的目的地区组件，帮助首次访问用户快速了解应用价值。

## What Changes

- 新增目的地区 Client Component（\rontend/src/components/destinations/destinations-section.tsx\），含 API 数据获取与三态渲染
- 新增目的地卡片组件（\rontend/src/components/destinations/destination-card.tsx\），含封面图（\
ext/image\）、城市名、亮点、热度标签
- 新增后端 API 端点 \GET /api/destinations/featured\，返回内存种子数据（MVP 阶段）
- 在 \page.tsx\ 中导入并渲染 DestinationsSection 组件，替换占位注释
- 响应式布局：移动端横向滚动（\snap-x\），桌面端网格（\md:grid md:grid-cols-4\）
- 封面图加载失败回退至渐变背景 + 城市名文本

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- \homepage-destinations\：从占位注释变为完整目的地区实现——覆盖卡片展示、API 集成、三态渲染、响应式布局、图片处理的全部 spec 要求

## Impact

**前端代码**：
- \rontend/src/app/page.tsx\：导入 DestinationsSection 组件，替换 \{/* Destinations Section */}\ 占位注释
- \rontend/src/components/destinations/destinations-section.tsx\：新增（Client Component，API 获取 + 三态渲染）
- \rontend/src/components/destinations/destination-card.tsx\：新增（卡片组件）
- \rontend/src/api/destinations.ts\：新增（API 调用封装）

**后端代码**：
- \ackend/src/main/java/com/example/myfirst/controller/DestinationController.java\：新增（\GET /api/destinations/featured\）
- \ackend/src/main/java/com/example/myfirst/dto/response/DestinationResponse.java\：新增（响应 DTO）
- 内存种子数据：Controller 内硬编码 4-6 条精选目的地（MVP 阶段，后续接入数据库）

**依赖**：无新增依赖。\
ext/image\、\lucide-react\、shadcn/ui 组件已在 \introduce-frontend-styling-infra\ 变更中安装。

**前置依赖**：
- \introduce-frontend-styling-infra\ 变更（Tailwind CSS + shadcn/ui + lucide-react 已安装并验证构建管线）
- \homepage-shell\ 变更（页面骨架已完成，section slot 挂载点就绪）

**后续依赖**：
- 目的地详情页 \/destinations/{slug}\ 由独立 spec 实现，MVP 阶段 404 可接受
