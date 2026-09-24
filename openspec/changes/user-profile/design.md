## Context

当前 ChinaBuddy 后端 User 实体（`entity/User.java`）仅包含 `id`、`username`、`email`、`createdAt`、`updatedAt` 五个字段。前端无个人中心页面。所有社交互动功能（消息通知、站内信）依赖用户展示信息（头像、昵称），必须先建立个人中心作为基础设施。

产品需求与交互规格详见 `docs/user-module/prd-profile.md` 和 `docs/user-module/interaction-profile.md`。

## Goals / Non-Goals

**Goals:**
- 扩展 User 实体，新增 `nickname`、`bio`、`avatarUrl`、`interestTags` 字段
- 实现头像上传 API（本地文件系统存储，JPG/PNG/WebP ≤ 2MB）
- 实现资料查看与编辑 REST API
- 实现兴趣标签列表 API（10 项预定义标签）
- 实现前端 `/profile` 查看页与 `/profile/edit` 编辑页
- 实现编辑页未保存离开确认对话框
- 实现响应式布局（Mobile / Desktop）与无障碍支持

**Non-Goals:**
- 查看他人个人主页（本期不支持）
- 头像裁剪 UI（上传后后端自动生成方形缩略图，前端不做裁剪）
- 兴趣标签多语言（标签列表由后端配置，英文）
- 认证机制（假设已有登录功能）
- 头像 CDN / 对象存储（使用本地文件系统）

## Decisions

### 1. 数据模型扩展方式：直接修改 User 实体

**决策:** 在现有 `entity/User.java` 上新增 4 个字段（`nickname VARCHAR(30)`、`bio VARCHAR(200)`、`avatarUrl VARCHAR(500)`、`interestTags VARCHAR(200)`），不创建独立的 Profile 表。

**理由:**
- 个人资料与 User 是 1:1 关系，独立表增加 JOIN 成本但无实质收益
- `interestTags` 以 JSON 数组序列化存储（如 `["Food","History"]`），`VARCHAR(200)` 足以容纳 5 个短标签
- 所有现有 API（`GET /api/users`）自动携带新字段，无需修改查询逻辑

**替代方案:** 创建独立 `profiles` 表 + 1:1 关联 — rejected，增加查询复杂度，对 1:1 关系过度设计。

### 2. 头像存储：本地文件系统 + 静态资源服务

**决策:** 后端接收 `MultipartFile`，生成 UUID 文件名，存储到 `backend/uploads/avatars/` 目录。通过 Spring Boot 静态资源映射暴露 `/uploads/avatars/{filename}` 路径。前端通过 Next.js rewrites 将 `/uploads/*` 转发到后端。

**理由:**
- MVP 阶段无需引入对象存储（S3/OSS），本地文件系统最简单
- UUID 文件名避免命名冲突和路径遍历攻击
- 静态资源映射让头像通过 HTTP 直接访问，无需额外 API 端点

**替代方案:** 对象存储（阿里云 OSS / AWS S3）— rejected，MVP 阶段过度设计。Base64 存入数据库 — rejected，增大数据库体积。

### 3. 头像上传 API 设计：独立端点

**决策:** 头像上传使用独立端点 `POST /api/profile/avatar`（`multipart/form-data`），不与资料编辑 `PUT /api/profile`（`application/json`）合并。

**理由:**
- `multipart/form-data` 和 `application/json` 是不同的 Content-Type，混在一个端点增加复杂度
- 头像上传成功后直接更新数据库中的 `avatarUrl`，前端无需额外调用

**替代方案:** 将头像作为 `PUT /api/profile` 的一个 `multipart` 字段 — rejected，混合 Content-Type 不符合 REST 惯例。

### 4. 兴趣标签存储：JSON 序列化 VARCHAR

**决策:** `interestTags` 以 JSON 数组字符串形式存储在 `VARCHAR(200)` 字段中。后端使用 Jackson `ObjectMapper` 进行序列化/反序列化。

**理由:**
- 最多 5 个标签，每个标签最长 12 字符，JSON 序列化后最长约 80 字符，`VARCHAR(200)` 充裕
- 避免引入额外的关联表，简化查询
- 标签列表由后端硬编码配置，前端通过 API 拉取

**替代方案:** 关联表 `user_interest_tags(user_id, tag_name)` — rejected，对最多 5 个标签的简单场景过度设计。

### 5. 前端页面结构：查看页与编辑页分离

**决策:** 创建两个独立页面路由 `/profile`（查看页）和 `/profile/edit`（编辑页），而非单页面切换编辑模式。

**理由:**
- URL 分离使"查看"和"编辑"有独立的语义
- 编辑页表单状态复杂（dirty tracking、validation、saving），独立页面简化状态管理
- Next.js App Router 天然支持路由级代码分割

**替代方案:** 单页面 inline 编辑模式 — rejected，编辑表单字段多，inline 编辑 UI 复杂度高。

### 6. 离开确认：beforeunload + Next.js 路由拦截

**决策:** 使用 `window.addEventListener('beforeunload')` 拦截浏览器关闭/刷新，使用 Next.js `useRouter` 的 `beforePopState` 拦截浏览器后退/前进，使用自定义 `isDirty` 状态追踪未保存修改。

**理由:**
- `beforeunload` 是浏览器标准 API
- Next.js App Router 不提供内置的导航拦截 Hook，需要自行组合
- `isDirty` 通过比较表单当前值与初始值计算，不依赖外部表单库

## Risks / Trade-offs

- **[本地文件存储扩展性]** → Docker 部署时需要 volume 挂载，多实例部署时文件不共享 → MVP 阶段可接受，后续迁移到对象存储时仅需替换 Service 内部实现。
- **[interestTags JSON 解析性能]** → 每次查询都需要 JSON 序列化/反序列化 → 对单用户资料查询，性能影响可忽略。
- **[头像上传安全性]** → 需要验证文件类型、大小、文件名安全 → 后端实现多层校验（MIME type + 扩展名 + UUID 替换文件名）。
- **[昵称唯一性]** → 本期不要求昵称唯一，仅作为展示用途 → 如果未来需要唯一昵称，需新增唯一约束和迁移。
- **[视觉设计文档与 spec 一致性]** → `interaction-profile.md` 与 `spec.md` 可能存在措辞差异 → `spec.md` 为权威源。
