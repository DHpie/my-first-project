## Context

当前 \rontend/src/app/page.tsx\ 中 Community Section 区域为占位注释。\homepage-shell\ 变更已实现页面骨架。后端已有 Spring Boot 项目结构，包含 User CRUD 的完整分层。本区域需要新增 \GET /api/posts/featured\ API 端点，MVP 阶段使用内存种子数据。与 \homepage-destinations\ 类似，本区域也是 Client Component + API 获取模式。

## Goals / Non-Goals

**Goals:**
- 在 \page.tsx\ 的 Community Section 占位处集成 CommunitySection 组件
- 实现 3-4 条社区帖子摘要展示，含头像、用户名、标题、摘要（截断）、点赞数
- 新增后端 API 端点返回内存种子数据
- 实现 loading/error/empty 三态渲染
- 实现摘要单词边界截断与点赞数格式化

**Non-Goals:**
- 动态信息流（无限滚动或算法排序）
- 点赞的用户认证（首页点赞数为纯展示）
- 首页发帖或评论
- 数据库持久化（MVP 阶段使用内存数据）

## Decisions

### 1. Client Component + API 获取

**决策:** CommunitySection 实现为 Client Component（\"use client"\），组件挂载时调用 \GET /api/posts/featured\ 获取数据。

**理由:**
- 需要 loading/error/empty 三态渲染，必须客户端状态管理
- 与 \homepage-destinations\ 保持一致的架构模式
- 10 秒超时通过 \AbortController\ 实现

**替代方案:** Server Component + \etch\ — rejected，无法实现客户端三态渲染和 Retry 按钮。

### 2. 后端 API：内存种子数据

**决策:** \PostController\ 内硬编码 3-4 条精选帖子数据，直接返回 \Result<List<PostResponse>>\。

**理由:**
- MVP 阶段快速验证前端集成，无需数据库
- 遵循项目已有 \Result<T>\ 信封格式
- 后续接入数据库时仅需替换数据源，Controller 接口不变

**替代方案:** 使用 H2 内存数据库 + JPA — rejected，MVP 阶段过度设计。

### 3. 摘要截断工具函数

**决策:** 在 \rontend/src/lib/format.ts\ 中实现 \	runcateExcerpt(text: string, maxLength: number): string\ 函数，在单词边界处截断。

**理由:**
- 截断逻辑可复用（如帖子列表页）
- 单词边界截断避免截断单词中间
- 纯函数，易于测试

### 4. 点赞数格式化工具函数

**决策:** 在 \rontend/src/lib/format.ts\ 中实现 \ormatLikeCount(count: number): string\ 函数。

**理由:**
- 格式化逻辑可复用
- 钳制负数为 0，处理数据异常
- 1000 以上使用 "k" 后缀，保留一位小数

### 5. 组件拆分

**决策:**
- \community-section.tsx\：Client Component，负责数据获取、三态渲染、布局
- \post-card.tsx\：纯展示组件，接收 \CommunityPost\ prop 渲染单张帖子卡片

**理由:**
- 关注点分离：数据逻辑与 UI 渲染解耦
- \post-card.tsx\ 可复用（如社区列表页）

## Risks / Trade-offs

- **[API 端点尚未实现]** → 前端开发阶段可使用 mock 数据或 \/api/posts/featured\ 返回 404，按错误状态处理
- **[种子数据硬编码]** → 后续需迁移至数据库，但 Controller 接口不变，前端无影响
- **[头像图片 URL 有效性]** → MVP 阶段使用占位头像 URL（如 \https://i.pravatar.cc/40\），生产环境需替换为真实用户头像
