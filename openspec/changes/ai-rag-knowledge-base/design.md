## Context

AI Chat Assistant 已实现完整的 SSE 流式对话系统：Spring AI 1.0.0 + 通义千问（qwen3-max）via DashScope、MySQL 多轮对话持久化、20 条消息滑动上下文窗口。当前 AI 仅依赖 LLM 内置知识回答旅游问题。

项目使用 MySQL 8.4（非 PostgreSQL，无法使用 pgvector）。目的地数据（5 条）和社区帖子（3 条）当前为硬编码，尚未数据库持久化。

## Goals / Non-Goals

**Goals:**
- 让 AI 助手基于平台目的地和帖子数据回答问题，提升回答准确性
- RAG 失败时透明退化为纯 LLM，不阻断对话
- 所有 RAG 参数（开关、top-K、阈值）可配置
- 前端零改动

**Non-Goals:**
- Post/Destination 实体数据库持久化（独立变更）
- 增量索引（数据变更时自动更新向量）
- 复杂文档分块（当前数据量小，每条记录为单个文档）
- 混合检索（关键词 + 向量）
- 前端修改

## Decisions

### Decision 1: Chroma 作为向量数据库

**选择**: Chroma (Docker)
**理由**: Spring AI 1.0.0 提供官方 `spring-ai-chroma-store-spring-boot-starter` 集成，开箱即用。Chroma 轻量、支持持久化、Docker 部署简单。

**替代方案**:
- Spring AI SimpleVectorStore — 内存存储 + JSON 持久化，零依赖，但不支持高级过滤、不适合生产
- Milvus — 功能最强但过重，对 <1000 条文档过度设计
- MySQL 模拟向量存储 — 查询性能差，无 ANN 索引支持

### Decision 2: DashScope Embedding API

**选择**: DashScope text-embedding-v3（通过 Spring AI OpenAI-compatible EmbeddingModel）
**理由**: 复用现有 DashScope API Key 和 base-url 配置，无需额外账号或依赖。Spring AI 的 OpenAI-compatible client 原生支持 `/v1/embeddings` 端点。

**替代方案**:
- 本地 ONNX/HuggingFace 模型 — 无额外费用但需下载模型文件（~80MB），效果不如云端模型

### Decision 3: 带相关性过滤的 RAG（方案 B）

**选择**: 每次查询都执行向量检索，通过余弦相似度阈值（0.65）过滤无关结果。低于阈值则退化为纯 LLM。
**理由**: 在简洁性和健壮性之间取得最佳平衡。旅行助手既需要回答"成都吃什么"（需要检索），也需要回答"Hi, how are you"（不需要检索）。阈值过滤优雅处理两种场景。

**替代方案**:
- 方案 A（无过滤）— 每次查询都注入检索结果，不相关问题会引入噪声
- 方案 C（Agentic RAG）— 额外 LLM 调用判断是否需要检索，延迟和成本翻倍，对当前规模过度设计

### Decision 4: System Prompt 尾部注入检索上下文

**选择**: 在原始 System Prompt 后追加 `[SourceType: Title]` + 内容 + 使用指令
**理由**: 不干扰历史消息结构。LLM 对 System Prompt 末尾内容注意力高。格式简洁清晰，便于 LLM 理解来源。

**替代方案**:
- 作为 UserMessage 注入 — 会干扰用户消息的语义
- 作为独立的 system message — 多个 system message 的行为在不同模型间不一致

### Decision 5: 启动时自动摄入 + 手动重新索引

**选择**: `@PostConstruct` 检查集合是否为空，为空则全量摄入。提供 `POST /api/ai/knowledge/reindex` 手动触发重新索引。
**理由**: 当前数据为硬编码静态数据，启动时摄入最简单。手动重新索引为未来数据持久化预留扩展路径。应用级锁保证并发安全。

**替代方案**:
- 事件驱动增量索引 — 需要先完成 Post/Destination 数据库持久化，当前不适用
- 定时任务同步 — 对静态数据过度设计

## Risks / Trade-offs

**[DashScope Embedding API 延迟]** → 每次查询增加一次 Embedding API 调用（~100-300ms）。Mitigation: 检索与 LLM 调用串行执行，总延迟增加可控；超时设置 5s，失败即退化。

**[Chroma 单点依赖]** → Chroma 容器挂掉后 RAG 不可用。Mitigation: 透明降级为纯 LLM，对话功能不受影响。Docker restart policy 保证容器自动恢复。

**[相关性阈值调优]** → 0.65 为初始经验值，可能需根据实际效果调整。Mitigation: 阈值通过 application.yml 配置，修改后重启生效，无需改代码。

**[硬编码数据源]** → 目的地和帖子当前为硬编码，数据量极小（8 条）。Mitigation: 摄入服务面向数据源接口编程，未来 Post/Destination 持久化后只需替换数据读取逻辑。

**[Token 预算]** → 检索上下文最大 2000 字符（~500 tokens），加上 20 条历史消息（~2000 tokens）和原始 prompt（~80 tokens），总计 ~2630 tokens，远在 qwen3-max 32K 上下文窗口内。风险极低。
