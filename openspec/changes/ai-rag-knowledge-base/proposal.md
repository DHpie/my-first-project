## Why

AI Travel Assistant 当前仅依赖通义千问模型的内置知识回答中国旅游相关问题，缺乏平台真实数据支撑。用户询问平台上的目的地或社区帖子内容时，AI 无法提供准确信息。通过引入 RAG（检索增强生成）能力，AI 助手可以基于平台目的地数据和社区帖子回答问题，提升回答的准确性和平台数据利用率。

## What Changes

- 新增 Chroma 向量数据库 Docker 部署（端口 8000）
- 新增 DashScope text-embedding-v3 Embedding 模型集成
- 新增知识摄入服务（KnowledgeIngestionService）— 将目的地和帖子数据转换为文档并索引到 Chroma
- 新增知识检索服务（KnowledgeRetrievalService）— 查询嵌入 + 余弦相似度搜索 + 相关性阈值过滤
- 修改 AiChatServiceImpl — 在构建 System Prompt 前执行知识检索，用检索结果增强 prompt
- 新增手动重新索引接口 `POST /api/ai/knowledge/reindex`
- 新增 RAG 配置项（开关、top-K、阈值、最大上下文长度）
- RAG 失败时自动退化为纯 LLM 模式，不阻断对话功能

## Capabilities

### New Capabilities
- `ai-rag-knowledge-base`: RAG 知识库能力 — 涵盖知识摄入（目的地 + 帖子文档索引到 Chroma）、知识检索（Embedding 查询 + 相似度搜索 + 相关性过滤）、手动重新索引 API、Chroma 向量存储配置、DashScope Embedding 集成、错误降级策略

### Modified Capabilities
- `ai-chat-assistant`: AiChatServiceImpl 集成 RAG 检索步骤 — 在构建 messages 数组前执行知识检索，有结果时增强 System Prompt，无结果或 RAG 禁用时保持原始行为不变。SSE 流式接口格式不变，前端无需修改。

## Impact

- **后端代码**: 新增 4 个服务类（2 接口 + 2 实现）、1 个 Controller、2 个 DTO、1 个配置类；修改 AiChatServiceImpl
- **后端依赖**: pom.xml 新增 `spring-ai-chroma-store-spring-boot-starter`
- **配置**: application.yml 新增 Embedding 模型配置、Chroma 连接配置、RAG 参数
- **基础设施**: 新增 docker-compose.yml（Chroma 容器）
- **API**: 新增 `POST /api/ai/knowledge/reindex` 端点
- **数据库**: 无变更（Chroma 独立存储）
- **前端**: 无变更（RAG 对前端完全透明）
