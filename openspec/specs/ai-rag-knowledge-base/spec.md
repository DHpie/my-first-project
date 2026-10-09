## Purpose

为 ChinaBuddy AI Travel Assistant 增加 RAG（Retrieval-Augmented Generation）知识库能力，使 AI 助手能够基于平台真实数据（目的地信息 + 社区帖子）回答用户问题。通过 Chroma 向量数据库存储文档嵌入向量，DashScope Embedding API 生成查询向量，检索相关文档后注入 System Prompt，实现带相关性过滤的检索增强生成。RAG 失败时自动退化为纯 LLM 模式，确保对话功能不中断。

## In Scope

1. 后端知识摄入服务（KnowledgeIngestionService）— 将目的地和帖子数据转换为文档并索引到 Chroma
2. 后端知识检索服务（KnowledgeRetrievalService）— 查询嵌入 + 相似度搜索 + 相关性阈值过滤
3. 后端 AiChatServiceImpl 集成 RAG — 检索结果增强 System Prompt
4. 后端手动重新索引接口（`POST /api/ai/knowledge/reindex`）
5. Chroma 向量数据库 Docker 部署
6. DashScope text-embedding-v3 Embedding 模型集成
7. 应用启动时自动摄入（首次空集合时触发）
8. RAG 配置化（开关、top-K、阈值、最大上下文长度）
9. 错误降级策略（RAG 失败退化为纯 LLM）

## Requirements

### Requirement: 知识摄入服务

系统 SHALL 提供知识摄入服务，将平台目的地数据和社区帖子数据转换为文档并索引到 Chroma 向量数据库。

#### Scenario: 应用启动时自动摄入
- **WHEN** 应用启动完成
- **AND** Chroma 集合为空（文档数为 0）
- **THEN** 系统 SHALL 自动执行全量摄入
- **AND** SHALL 将 5 个目的地数据转换为 5 个文档
- **AND** SHALL 将 3 个社区帖子数据转换为 3 个文档
- **AND** SHALL 通过 DashScope text-embedding-v3 生成嵌入向量
- **AND** SHALL 将文档内容和向量写入 Chroma 集合

#### Scenario: 目的地文档结构
- **WHEN** 摄入目的地数据
- **THEN** 每个目的地 SHALL 生成 1 个文档
- **AND** 文档内容格式 SHALL 为 `"{cityName} — {highlight}"`
- **AND** 文档元数据 SHALL 包含 `sourceType: "DESTINATION"`, `sourceId`, `cityName`, `popularityTag`

#### Scenario: 帖子文档结构
- **WHEN** 摄入帖子数据
- **THEN** 每个帖子 SHALL 生成 1 个文档
- **AND** 文档内容格式 SHALL 为 `"{title}\n{excerpt}"`
- **AND** 文档元数据 SHALL 包含 `sourceType: "POST"`, `sourceId`, `authorName`

#### Scenario: 手动重新索引
- **WHEN** 管理员调用 `POST /api/ai/knowledge/reindex`
- **THEN** 系统 SHALL 清空 Chroma 集合中的所有现有文档
- **AND** SHALL 重新执行全量摄入
- **AND** SHALL 返回 HTTP 200 与 `{ "code": 200, "data": { "indexedDocuments": 8, "sources": { "DESTINATION": 5, "POST": 3 } } }`

#### Scenario: 重新索引失败 — Chroma 不可达
- **WHEN** 管理员调用 `POST /api/ai/knowledge/reindex`
- **AND** Chroma 不可达
- **THEN** API SHALL 返回 HTTP 500 与 `{ "code": 500, "message": "Knowledge reindex failed: Chroma unavailable", "data": null }`

#### Scenario: 重新索引失败 — Embedding API 不可用
- **WHEN** 管理员调用 `POST /api/ai/knowledge/reindex`
- **AND** DashScope Embedding API 不可用
- **THEN** API SHALL 返回 HTTP 500 与 `{ "code": 500, "message": "Knowledge reindex failed: Embedding service unavailable", "data": null }`

#### Scenario: 并发重新索引
- **WHEN** 多个管理员同时调用 `POST /api/ai/knowledge/reindex`
- **THEN** 系统 SHALL 使用应用级锁保证同一时刻仅执行一个重新索引任务
- **AND** 后续请求 SHALL 等待当前任务完成后执行（串行化）
- **AND** 重新索引过程中对话功能 SHALL 正常使用旧索引数据（不中断服务）

#### Scenario: 启动时摄入失败
- **WHEN** 应用启动时自动摄入过程中 Chroma 不可达或 DashScope Embedding 失败
- **THEN** 系统 SHALL 记录 ERROR 级别日志
- **AND** 应用 SHALL 正常启动（RAG 降级为不可用，对话功能不受影响）

### Requirement: 知识检索服务

系统 SHALL 提供知识检索服务，根据用户查询检索相关知识文档。

#### Scenario: 查询检索 — 有相关结果
- **WHEN** 用户发送消息 "What should I eat in Chengdu?"
- **THEN** 系统 SHALL 将消息文本通过 DashScope text-embedding-v3 转换为查询向量
- **AND** SHALL 在 Chroma 中执行余弦相似度搜索，返回 top-5 结果
- **AND** SHALL 过滤掉相似度 < 0.65 的结果
- **AND** SHALL 返回过滤后的文档列表（包含内容和元数据）

#### Scenario: 查询检索 — 无相关结果
- **WHEN** 用户发送消息 "Hello, how are you?"
- **THEN** 系统 SHALL 执行向量检索
- **AND** 所有结果的相似度 SHALL 低于 0.65 阈值
- **AND** SHALL 返回空列表

#### Scenario: 查询检索 — Chroma 不可达
- **WHEN** Chroma 服务不可达（连接超时或拒绝）
- **THEN** 系统 SHALL 记录 WARN 级别日志
- **AND** SHALL 返回空列表（不抛出异常）

#### Scenario: 查询检索 — Embedding API 失败
- **WHEN** DashScope Embedding API 调用失败（网络错误、限流）
- **THEN** 系统 SHALL 记录 WARN 级别日志
- **AND** SHALL 返回空列表（不抛出异常）

#### Scenario: 检索参数可配置
- **WHEN** 系统启动
- **THEN** top-K（默认 5）、relevance-threshold（默认 0.65）、max-context-chars（默认 2000）SHALL 从 `application.yml` 读取
- **AND** SHALL 支持修改配置后重启生效

### Requirement: 聊天集成 — Prompt 增强

系统 SHALL 在 AI 对话流程中集成知识检索，用检索结果增强 System Prompt。

#### Scenario: RAG 启用且有检索结果
- **WHEN** `app.ai.rag.enabled` 为 `true`
- **AND** 知识检索返回 ≥ 1 个相关文档
- **THEN** 系统 SHALL 在原始 System Prompt 后追加检索上下文
- **AND** 上下文格式 SHALL 为：
  ```
  ---
  Based on the following platform data, provide accurate and relevant information:

  [Destination: Chengdu]
  Home of giant pandas and world-famous Sichuan cuisine

  [Post: 3 Days in Chengdu — A Food Lover's Guide by Li Wei]
  From spicy hotpot in Yulin district...
  ---

  Instructions for using platform data:
  - Use the above information to enhance your response accuracy.
  - If the platform data conflicts with your knowledge, prefer the platform data.
  - Do not mention "platform data" or "retrieved information" in your response.
  - If the platform data is not relevant, ignore it and answer from your own knowledge.
  ```
- **AND** 注入的检索内容总长度 SHALL 不超过 `max-context-chars`（默认 2000 字符）

#### Scenario: RAG 启用但无检索结果
- **WHEN** `app.ai.rag.enabled` 为 `true`
- **AND** 知识检索返回空列表（无相关文档或检索失败）
- **THEN** 系统 SHALL 使用原始 System Prompt（不追加任何内容）
- **AND** 行为 SHALL 与 RAG 禁用时完全一致

#### Scenario: RAG 禁用
- **WHEN** `app.ai.rag.enabled` 为 `false`
- **THEN** 系统 SHALL 跳过检索步骤
- **AND** SHALL 使用原始 System Prompt
- **AND** 行为 SHALL 与 RAG 功能实现前完全一致

#### Scenario: 上下文注入位置
- **WHEN** 构建发送给通义千问的 messages 数组
- **THEN** 增强后的 System Prompt SHALL 作为第一条消息（system role）
- **AND** 历史消息顺序和结构 SHALL 保持不变
- **AND** 用户新消息 SHALL 保持为最后一条

#### Scenario: SSE 流式接口不变
- **WHEN** RAG 功能集成后
- **THEN** `POST /api/ai/chat/stream` 的 SSE 响应格式 SHALL 保持不变
- **AND** 前端 SHALL 无需任何修改
- **AND** RAG 检索过程对用户完全透明

### Requirement: Chroma 向量存储配置

系统 SHALL 通过 Docker 运行 Chroma 向量数据库，并通过 Spring AI 集成。

#### Scenario: Chroma 容器启动
- **WHEN** 执行 `docker compose up -d chroma`
- **THEN** Chroma SHALL 在端口 8000 启动
- **AND** 数据 SHALL 持久化到 Docker volume `chroma-data`

#### Scenario: Spring AI 连接 Chroma
- **WHEN** 后端应用启动
- **THEN** Spring AI ChromaVectorStore SHALL 连接到 `http://localhost:8000`
- **AND** SHALL 使用集合名 `chinabuddy-knowledge`

#### Scenario: Chroma 未启动时应用行为
- **WHEN** 后端应用启动但 Chroma 未运行
- **AND** `app.ai.rag.enabled` 为 `true`
- **THEN** 自动摄入 SHALL 失败并记录 ERROR 日志
- **AND** 应用 SHALL 正常启动（RAG 降级为不可用，对话功能不受影响）

#### Scenario: Chroma 未启动时查询行为
- **WHEN** 用户发送消息
- **AND** Chroma 不可达
- **THEN** 检索 SHALL 返回空列表
- **AND** 对话 SHALL 退化为纯 LLM 模式

### Requirement: DashScope Embedding 集成

系统 SHALL 使用 DashScope text-embedding-v3 模型生成文档和查询的嵌入向量。

#### Scenario: Embedding 配置
- **WHEN** 后端启动
- **THEN** Spring AI EmbeddingModel SHALL 配置 model 为 `text-embedding-v3`
- **AND** SHALL 复用现有 DashScope API Key（`spring.ai.openai.api-key`）
- **AND** SHALL 复用现有 base-url（`https://dashscope.aliyuncs.com/compatible-mode`）

#### Scenario: Embedding API Key 缺失
- **WHEN** `spring.ai.openai.api-key` 未配置
- **AND** `app.ai.rag.enabled` 为 `true`
- **THEN** 摄入和检索 SHALL 失败
- **AND** 系统 SHALL 退化为纯 LLM 模式

## Data Structures

### RetrievedDocument（后端检索结果 DTO）

```java
public class RetrievedDocument {
    /** 文档内容 */
    private String content;
    /** 文档来源类型: "DESTINATION" | "POST" */
    private String sourceType;
    /** 文档来源 ID */
    private Long sourceId;
    /** 相似度分数 (0.0 - 1.0) */
    private double similarityScore;
    /** 附加元数据 */
    private Map<String, Object> metadata;
}
```

### ReindexResponse（后端重新索引响应 DTO）

```java
public class ReindexResponse {
    /** 索引的文档总数 */
    private int indexedDocuments;
    /** 各来源类型的文档数量 */
    private Map<String, Integer> sources;
}
```

### Chroma Document Metadata Schema

```json
// Destination document metadata
{
  "sourceType": "DESTINATION",
  "sourceId": 1,
  "cityName": "Chengdu",
  "popularityTag": "Hot"
}

// Post document metadata
{
  "sourceType": "POST",
  "sourceId": 1,
  "authorName": "Li Wei"
}
```

### 后端 Configuration Properties

```java
@Data
@Component
@ConfigurationProperties(prefix = "app.ai.rag")
public class RagProperties {
    /** RAG 功能开关 */
    private boolean enabled = true;
    /** 检索返回的最大文档数 */
    private int topK = 5;
    /** 余弦相似度阈值，低于此值的文档被丢弃 */
    private double relevanceThreshold = 0.65;
    /** 注入到 prompt 的检索内容总长度上限（字符数） */
    private int maxContextChars = 2000;
}
```

## Acceptance Checklist

### 知识摄入
- [ ] 应用启动时自动摄入 8 条文档（5 目的地 + 3 帖子）到 Chroma
- [ ] 目的地文档内容格式为 `"{cityName} — {highlight}"`
- [ ] 帖子文档内容格式为 `"{title}\n{excerpt}"`
- [ ] 文档元数据包含 sourceType、sourceId、cityName/popularityTag 或 authorName
- [ ] `POST /api/ai/knowledge/reindex` 返回 `{ "indexedDocuments": 8, "sources": {...} }`
- [ ] 重新索引失败（Chroma 不可达）→ HTTP 500
- [ ] 重新索引失败（Embedding 不可用）→ HTTP 500
- [ ] 并发重新索引通过应用级锁串行化
- [ ] 启动时摄入失败不阻止应用启动

### 知识检索
- [ ] 查询通过 DashScope text-embedding-v3 生成向量
- [ ] Chroma 余弦相似度搜索返回 top-5
- [ ] 相似度 < 0.65 的文档被过滤
- [ ] 无相关结果时返回空列表
- [ ] Chroma 不可达时返回空列表（不抛异常）
- [ ] Embedding API 失败时返回空列表（不抛异常）
- [ ] top-K、阈值、最大上下文长度从 application.yml 读取

### 聊天集成
- [ ] 有检索结果时 System Prompt 追加平台数据上下文
- [ ] 上下文格式为 `[SourceType: Title]` + 内容 + 使用指令
- [ ] 无检索结果时使用原始 System Prompt
- [ ] `app.ai.rag.enabled: false` 时完全跳过检索
- [ ] 注入内容不超过 2000 字符（可配置）
- [ ] 增强后的 System Prompt 作为 messages 数组第一条（system role）
- [ ] 历史消息结构不变
- [ ] SSE 流式接口格式不变
- [ ] 前端无需任何修改

### Chroma 与 Embedding
- [ ] Chroma Docker 容器在端口 8000 正常启动
- [ ] Spring AI ChromaVectorStore 连接 `http://localhost:8000`
- [ ] 集合名为 `chinabuddy-knowledge`
- [ ] Chroma 未启动时应用正常启动（RAG 降级）
- [ ] DashScope Embedding model 为 `text-embedding-v3`
- [ ] Embedding 复用现有 API Key 和 base-url
- [ ] API Key 缺失时退化为纯 LLM

### 错误处理
- [ ] Chroma 不可达 → 退化为纯 LLM（对话不中断）
- [ ] Embedding API 失败 → 退化为纯 LLM（对话不中断）
- [ ] 检索结果全部低于阈值 → 使用原始 System Prompt
- [ ] RAG 失败不阻断对话功能（核心原则）

## Out of Scope

- Post 实体数据库持久化（当前为硬编码数据，后续独立变更）
- Destination 实体数据库持久化（同上）
- 增量索引（Post/Destination 创建或更新时自动索引）
- 用户自定义知识库上传（管理员上传文档）
- 多语言 Embedding（当前仅支持英文）
- 向量数据库管理 UI
- 检索结果的来源引用展示（在 AI 回答中标注信息来源）
- 混合检索（关键词搜索 + 向量搜索结合）
- 对话历史作为检索对象
- RAG 效果评估指标（recall@K、MRR 等）
- 复杂文档分块策略（当前数据量小，每条记录作为单个文档）
- 前端任何修改（RAG 对前端完全透明）
