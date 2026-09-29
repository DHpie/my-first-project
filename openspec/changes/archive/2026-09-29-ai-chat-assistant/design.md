## Context

ChinaBuddy 后端当前 `AiChatController` 为纯 Mock（关键词匹配硬编码回复），前端 `ai-widget.tsx` 通过 Axios 调用 `POST /api/ai/chat` 一次性获取完整响应。项目采用 Spring Boot 3.3.3 + Java 17 + Spring Data JPA + MySQL，前端 Next.js 15 App Router。认证使用 `X-User-Id` header（MVP 临时方案）。详见 proposal.md。

## Goals / Non-Goals

**Goals:**
- 通过 Spring AI 1.0.x OpenAI-Compatible Client 接入通义千问 qwen-plus 模型
- 后端 SSE 流式输出，前端逐字渲染 AI 回复
- MySQL 持久化对话上下文，支持最近 20 条消息作为多轮上下文窗口
- 前端会话历史恢复（打开对话窗自动加载）
- 会话归档与新建对话

**Non-Goals:**
- 多会话管理（侧边栏列表）— 仅单会话模式
- 聊天富媒体（Markdown 渲染、图片、链接预览）
- 向量数据库 / RAG 检索增强
- 真实用户认证（继续使用 X-User-Id MVP 方案）

## Decisions

### 决策 1：Spring AI 1.0.x + OpenAI-Compatible Client（选通义千问）

**选择**：引入 `spring-ai-bom` 1.0.x + `spring-ai-openai-spring-boot-starter`，将 `base-url` 指向 `https://dashscope.aliyuncs.com/compatible-mode/v1`。

**理由**：
- 通义千问 API 完全兼容 OpenAI 协议，Spring AI 的 OpenAI starter 只需改 base-url 即可对接
- Spring AI 1.0.x 兼容项目当前 Spring Boot 3.3.3（2.0 需要 Boot 4.1，不可用）
- `ChatClient.prompt().stream().content()` 直接返回 `Flux<String>`，与 `SseEmitter` 集成自然
- 未来切换模型供应商仅需修改配置，业务代码零改动

**替代方案**：
- 直接 WebClient 调 HTTP API → 需手动处理流式 JSON 解析、认证、重试，维护成本高
- 智谱 AI → 用户明确要求切换为通义千问

### 决策 2：SSE 通信方式（非 WebSocket）

**选择**：`POST /api/ai/chat/stream` 返回 `text/event-stream`，使用 Spring `SseEmitter`。

**理由**：
- AI 聊天是单向流式（服务端→客户端），SSE 天然匹配
- 无需引入 WebSocket 的双向通信开销和连接管理复杂度
- 前端 `fetch` + `ReadableStream` 原生支持 SSE 消费，无需额外库
- 与项目现有 REST 架构风格一致

**替代方案**：
- WebSocket → 双向通信过重，且项目已有 WebSocket 用于即时消息，增加混淆
- 长轮询 → 延迟高，资源浪费

### 决策 3：数据库表设计（会话 + 消息双表）

**选择**：`ai_conversation`（会话）+ `ai_message`（消息）两张表，通过 `archived_at` 字段实现逻辑归档。

**理由**：
- 会话/消息双表是聊天系统的标准范式，与项目已有的 `conversation` + `message` 模式一致
- `archived_at` 逻辑归档而非物理删除，保留历史数据可供未来分析
- 活跃会话唯一性通过业务逻辑保证（`WHERE archived_at IS NULL`），而非 UNIQUE 约束，因为同一用户归档后可创建新会话

**替代方案**：
- 单表 + JSON 列存所有消息 → 查询和截断上下文不便
- 内存存储（原 MVP 方案）→ 刷新丢失，不支持多轮上下文

### 决策 4：前端 SSE 消费（fetch + ReadableStream）

**选择**：使用原生 `fetch` + `ReadableStream` 替代 Axios 消费 SSE 流。

**理由**：
- Axios 不支持流式响应读取
- 原生 `fetch` 的 `response.body.getReader()` 提供逐 chunk 读取能力
- 无需引入额外 SSE 客户端库
- 与 Next.js App Router 的 Client Component 兼容

### 决策 5：上下文窗口大小（20 条消息）

**选择**：加载最近 20 条消息作为 AI 上下文窗口。

**理由**：
- qwen-plus 上下文窗口 128K tokens，20 条消息（约 2000-4000 tokens）远在限制内
- 20 条覆盖约 10 轮对话，对旅游问答场景足够
- 避免上下文过大导致 token 成本增加和响应延迟

### 决策 6：消息持久化时机（流结束后）

**选择**：SSE 流完整结束后，将用户消息和完整 AI 回复一次性持久化。

**理由**：
- 流式传输中逐 token 写数据库增加 I/O 开销且无必要
- 流结束后写入保证数据完整性
- 客户端断开时丢弃未完成回复，避免脏数据

## Risks / Trade-offs

- **[Spring AI 版本兼容性]** → Spring AI 1.0.x 需验证与 Spring Boot 3.3.3 的精确兼容性。→ 缓解：实施前先做最小化依赖引入 + 编译验证。
- **[通义千问 API Key 管理]** → API Key 硬编码在 application.yml 中存在泄露风险。→ 缓解：MVP 阶段使用环境变量 `${DASHSCOPE_API_KEY}` 引用，不直接写入配置文件。生产环境应使用密钥管理服务。
- **[SSE 连接泄漏]** → 客户端异常断开时 SseEmitter 可能未及时释放。→ 缓解：设置 SseEmitter 超时时间（60s），注册 onCompletion/onTimeout/onError 回调清理资源。
- **[前端 fetch 兼容性]** → ReadableStream 在极旧浏览器中不可用。→ 缓解：MVP 目标浏览器（Chrome/Edge/Firefox 最新版）均支持，无需 polyfill。
- **[上下文截断丢失语义]** → 20 条截断可能切断正在讨论的话题。→ 缓解：截断从最早的用户消息开始，保持 user-assistant 配对完整性。
- **[现有 Mock API 共存]** → `POST /api/ai/chat` 保留但前端不再使用，可能造成混淆。→ 缓解：在 Mock Controller 上添加 `@Deprecated` 注解，后续版本移除。
