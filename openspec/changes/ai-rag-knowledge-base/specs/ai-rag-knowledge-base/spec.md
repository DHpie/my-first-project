## Purpose

为 ChinaBuddy AI Travel Assistant 提供 RAG（检索增强生成）知识库能力，使 AI 助手能够基于平台目的地数据和社区帖子内容回答用户问题。通过向量数据库存储文档嵌入，在用户提问时检索相关文档并增强 System Prompt，实现带相关性过滤的知识增强对话。

## ADDED Requirements

### Requirement: 知识摄入

系统 SHALL 将平台目的地数据和社区帖子数据转换为文档并索引到向量数据库，供后续检索使用。

#### Scenario: 应用启动时自动摄入
- **WHEN** 应用启动完成
- **AND** 知识库集合为空（文档数为 0）
- **THEN** 系统 SHALL 自动执行全量摄入
- **AND** SHALL 将所有目的地数据转换为文档（每个目的地 1 个文档）
- **AND** SHALL 将所有社区帖子数据转换为文档（每个帖子 1 个文档）
- **AND** SHALL 通过 Embedding 模型生成向量并写入向量数据库

#### Scenario: 目的地文档内容格式
- **WHEN** 摄入目的地数据
- **THEN** 文档内容 SHALL 为 `"{cityName} — {highlight}"`
- **AND** 文档元数据 SHALL 包含 `sourceType: "DESTINATION"`, `sourceId`, `cityName`, `popularityTag`

#### Scenario: 帖子文档内容格式
- **WHEN** 摄入帖子数据
- **THEN** 文档内容 SHALL 为 `"{title}\n{excerpt}"`
- **AND** 文档元数据 SHALL 包含 `sourceType: "POST"`, `sourceId`, `authorName`

#### Scenario: 启动时摄入失败
- **WHEN** 应用启动时自动摄入过程中向量数据库不可达或 Embedding 服务失败
- **THEN** 系统 SHALL 记录 ERROR 级别日志
- **AND** 应用 SHALL 正常启动（RAG 降级为不可用，对话功能不受影响）

### Requirement: 知识检索

系统 SHALL 根据用户查询检索相关知识文档，并通过相关性阈值过滤无关结果。

#### Scenario: 查询检索 — 有相关结果
- **WHEN** 用户发送与平台数据相关的消息
- **THEN** 系统 SHALL 将消息文本转换为查询向量
- **AND** SHALL 在向量数据库中执行余弦相似度搜索，返回 top-K 结果
- **AND** SHALL 过滤掉相似度低于配置阈值的结果
- **AND** SHALL 返回过滤后的文档列表（包含内容和元数据）

#### Scenario: 查询检索 — 无相关结果
- **WHEN** 用户发送与平台数据无关的消息
- **THEN** 所有检索结果的相似度 SHALL 低于阈值
- **AND** SHALL 返回空列表

#### Scenario: 查询检索 — 向量数据库不可达
- **WHEN** 向量数据库服务不可达（连接超时或拒绝）
- **THEN** 系统 SHALL 记录 WARN 级别日志
- **AND** SHALL 返回空列表（不抛出异常）

#### Scenario: 查询检索 — Embedding 服务失败
- **WHEN** Embedding API 调用失败（网络错误、限流）
- **THEN** 系统 SHALL 记录 WARN 级别日志
- **AND** SHALL 返回空列表（不抛出异常）

#### Scenario: 检索参数可配置
- **WHEN** 系统启动
- **THEN** top-K、relevance-threshold、max-context-chars SHALL 从配置文件读取
- **AND** SHALL 支持修改配置后重启生效

### Requirement: 手动重新索引接口

系统 SHALL 提供 REST API 供管理员手动触发知识库重新索引。

#### Scenario: 重新索引成功
- **WHEN** 管理员调用 `POST /api/ai/knowledge/reindex`
- **THEN** 系统 SHALL 清空知识库集合中的所有现有文档
- **AND** SHALL 重新执行全量摄入
- **AND** SHALL 返回 HTTP 200 与 `{ "code": 200, "data": { "indexedDocuments": 8, "sources": { "DESTINATION": 5, "POST": 3 } } }`

#### Scenario: 重新索引失败 — 向量数据库不可达
- **WHEN** 管理员调用 `POST /api/ai/knowledge/reindex`
- **AND** 向量数据库不可达
- **THEN** API SHALL 返回 HTTP 500 与 `{ "code": 500, "message": "Knowledge reindex failed: Chroma unavailable", "data": null }`

#### Scenario: 重新索引失败 — Embedding 服务不可用
- **WHEN** 管理员调用 `POST /api/ai/knowledge/reindex`
- **AND** Embedding API 不可用
- **THEN** API SHALL 返回 HTTP 500 与 `{ "code": 500, "message": "Knowledge reindex failed: Embedding service unavailable", "data": null }`

#### Scenario: 并发重新索引
- **WHEN** 多个管理员同时调用 `POST /api/ai/knowledge/reindex`
- **THEN** 系统 SHALL 使用应用级锁保证同一时刻仅执行一个重新索引任务
- **AND** 后续请求 SHALL 等待当前任务完成后执行（串行化）
- **AND** 重新索引过程中对话功能 SHALL 正常使用旧索引数据（不中断服务）

### Requirement: 聊天集成 — Prompt 增强

系统 SHALL 在 AI 对话流程中集成知识检索，用检索结果增强 System Prompt。

#### Scenario: RAG 启用且有检索结果
- **WHEN** RAG 功能已启用
- **AND** 知识检索返回 ≥ 1 个相关文档
- **THEN** 系统 SHALL 在原始 System Prompt 后追加检索上下文
- **AND** 上下文格式 SHALL 包含 `[SourceType: Title]` + 内容 + 使用指令
- **AND** 注入的检索内容总长度 SHALL 不超过 max-context-chars 配置值

#### Scenario: RAG 启用但无检索结果
- **WHEN** RAG 功能已启用
- **AND** 知识检索返回空列表
- **THEN** 系统 SHALL 使用原始 System Prompt（不追加任何内容）
- **AND** 行为 SHALL 与 RAG 禁用时完全一致

#### Scenario: RAG 禁用
- **WHEN** RAG 功能配置为禁用
- **THEN** 系统 SHALL 跳过检索步骤
- **AND** SHALL 使用原始 System Prompt
- **AND** 行为 SHALL 与 RAG 功能实现前完全一致

#### Scenario: SSE 流式接口不变
- **WHEN** RAG 功能集成后
- **THEN** `POST /api/ai/chat/stream` 的 SSE 响应格式 SHALL 保持不变
- **AND** 前端 SHALL 无需任何修改
- **AND** RAG 检索过程对用户完全透明

### Requirement: 错误降级

RAG 流程中任何环节失败 SHALL 不阻断对话功能，系统 SHALL 自动退化为纯 LLM 模式。

#### Scenario: 向量数据库不可达时对话降级
- **WHEN** 用户发送消息
- **AND** 向量数据库不可达
- **THEN** 检索 SHALL 返回空列表
- **AND** 对话 SHALL 使用原始 System Prompt 正常进行

#### Scenario: Embedding 服务失败时对话降级
- **WHEN** 用户发送消息
- **AND** Embedding API 调用失败
- **THEN** 检索 SHALL 返回空列表
- **AND** 对话 SHALL 使用原始 System Prompt 正常进行

## REMOVED Requirements

无。
