## Context

当前 \rontend/src/app/page.tsx\ 中 Destinations Section 区域为占位注释。\homepage-shell\ 变更已实现页面骨架。后端已有 Spring Boot 项目结构（\com.example.myfirst\），包含 User CRUD 的完整分层（controller/service/repository/entity）。本区域需要新增 \GET /api/destinations/featured\ API 端点，MVP 阶段使用内存种子数据。

## Goals / Non-Goals

**Goals:**
- 在 \page.tsx\ 的 Destinations Section 占位处集成 DestinationsSection 组件
- 实现 4-6 张目的地卡片网格，含封面图、城市名、亮点、热度标签
- 新增后端 API 端点返回内存种子数据
- 实现 loading/error/empty 三态渲染
- 响应式布局：移动端横向滚动，桌面端网格

**Non-Goals:**
- 基于算法的目的地推荐或用户个性化排序
- 目的地详情页内容（属于独立 spec）
- 数据库持久化（MVP 阶段使用内存数据）

## Decisions

### 1. Client Component + API 获取

**决策:** DestinationsSection 实现为 Client Component（\"use client"\），组件挂载时调用 \GET /api/destinations/featured\ 获取数据。

**理由:**
- 需要 loading/error/empty 三态渲染，必须客户端状态管理
- 使用 \useEffect\ + \useState\ 实现数据获取生命周期
- 10 秒超时通过 \AbortController\ 实现

**替代方案:** Server Component + \etch\ — rejected，无法实现客户端三态渲染和 Retry 按钮。

### 2. 后端 API：内存种子数据

**决策:** \DestinationController\ 内硬编码 4-6 条精选目的地数据，直接返回 \Result<List<DestinationResponse>>\。

**理由:**
- MVP 阶段快速验证前端集成，无需数据库
- 遵循项目已有 \Result<T>\ 信封格式
- 后续接入数据库时仅需替换数据源，Controller 接口不变

**替代方案:** 使用 H2 内存数据库 + JPA — rejected，MVP 阶段过度设计，种子数据量小且固定。

### 3. 组件拆分

**决策:**
- \destinations-section.tsx\：Client Component，负责数据获取、三态渲染、布局
- \destination-card.tsx\：纯展示组件，接收 \Destination\ prop 渲染单张卡片

**理由:**
- 关注点分离：数据逻辑与 UI 渲染解耦
- \destination-card.tsx\ 可复用（如目的地列表页）

### 4. 图片加载失败回退

**决策:** 封面图加载失败时显示渐变背景（\g-gradient-to-br from-blue-400 to-purple-600\）+ 白色城市名文本。

**理由:**
- 渐变背景视觉吸引力强，符合品牌调性
- 城市名文本确保信息不丢失

## Risks / Trade-offs

- **[API 端点尚未实现]** → 前端开发阶段可使用 mock 数据或 \/api/destinations/featured\ 返回 404，按错误状态处理
- **[种子数据硬编码]** → 后续需迁移至数据库，但 Controller 接口不变，前端无影响
- **[横向滚动移动端体验]** → \snap-x\ 提供原生滚动吸附，无需额外 JS 库
