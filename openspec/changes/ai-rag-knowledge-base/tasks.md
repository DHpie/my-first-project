## 1. 基础设施 — Docker + 依赖 + 配置

- [ ] 1.1 项目根目录创建 `docker-compose.yml`，定义 Chroma 服务（image: `ghcr.io/chroma-core/chroma:latest`，端口 8000，volume 持久化），启动容器并验证 `curl http://localhost:8000/api/v1/heartbeat` 返回 200
- [ ] 1.2 `backend/pom.xml` 新增 `spring-ai-chroma-store-spring-boot-starter` 依赖，运行 `mvnw.cmd compile` 验证依赖解析成功
- [ ] 1.3 `backend/src/main/resources/application.yml` 新增三段配置：`spring.ai.openai.embedding.options.model: text-embedding-v3`、`spring.ai.vectorstore.chroma`（host/port/collection-name）、`app.ai.rag`（enabled/top-k/relevance-threshold/max-context-chars），启动应用验证配置加载无报错

## 2. DTO + 配置类

- [ ] 2.1 创建 `RagProperties` 配置类（`@ConfigurationProperties(prefix = "app.ai.rag")`），包含 enabled(boolean)、topK(int)、relevanceThreshold(double)、maxContextChars(int) 四个字段及默认值，编写单元测试验证默认值正确
- [ ] 2.2 创建 `RetrievedDocument` DTO（content、sourceType、sourceId、similarityScore、metadata 字段），创建 `ReindexResponse` DTO（indexedDocuments、sources 字段），运行 `mvnw.cmd compile` 验证编译通过

## 3. 知识摄入服务（TDD）

- [ ] 3.1 创建 `KnowledgeIngestionService` 接口，定义 `ingestAll()` 和 `reindex()` 方法
- [ ] 3.2 编写 `KnowledgeIngestionServiceImplTest` 单元测试（Mock VectorStore + EmbeddingModel）：验证 ingestAll() 将 5 个目的地 + 3 个帖子转换为文档并写入 VectorStore，验证文档内容格式和元数据正确性
- [ ] 3.3 运行测试验证编译失败（类不存在），然后创建 `KnowledgeIngestionServiceImpl` 实现类：读取 DestinationController 硬编码目的地数据和 PostController 硬编码帖子数据，转换为 Document 对象（内容 + metadata），调用 VectorStore.add() 写入。`reindex()` 先调用 `VectorStore.delete()` 清空再调用 `ingestAll()`，使用 ReentrantLock 保证并发安全
- [ ] 3.4 运行测试验证全部通过，运行 `mvnw.cmd compile` 验证编译成功

## 4. 知识检索服务（TDD）

- [ ] 4.1 创建 `KnowledgeRetrievalService` 接口，定义 `retrieve(String query)` 方法，返回 `List<RetrievedDocument>`
- [ ] 4.2 编写 `KnowledgeRetrievalServiceImplTest` 单元测试（Mock VectorStore + EmbeddingModel）：验证有相关结果时正确过滤（top-K + 阈值）、无相关结果时返回空列表、VectorStore 异常时返回空列表（不抛异常）、EmbeddingModel 异常时返回空列表
- [ ] 4.3 运行测试验证编译失败，然后创建 `KnowledgeRetrievalServiceImpl` 实现类：调用 EmbeddingModel 生成查询向量，调用 VectorStore.similaritySearch() 检索，按 relevanceThreshold 过滤，按 maxContextChars 截断总长度。所有异常 catch 后记录 WARN 日志并返回空列表
- [ ] 4.4 运行测试验证全部通过

## 5. 重新索引 Controller（TDD）

- [ ] 5.1 编写 `KnowledgeControllerTest` 单元测试（Mock KnowledgeIngestionService）：验证重新索引成功时返回 200 + 正确响应体，验证 Chroma 不可用时返回 500
- [ ] 5.2 运行测试验证编译失败，然后创建 `KnowledgeController`（`@RestController`, `@RequestMapping("/api/ai/knowledge")`），实现 `POST /reindex` 端点，调用 `KnowledgeIngestionService.reindex()` 返回 `Result<ReindexResponse>`，异常时返回 HTTP 500
- [ ] 5.3 运行测试验证全部通过

## 6. 启动时自动摄入

- [ ] 6.1 在 `KnowledgeIngestionServiceImpl` 中添加 `@PostConstruct` 方法：检查 VectorStore 集合文档数是否为空（通过 similaritySearch 空查询判断），为空则调用 `ingestAll()`。摄入失败记录 ERROR 日志但不阻止应用启动。编写单元测试验证空集合时触发摄入、非空集合时跳过摄入、摄入异常时不抛出

## 7. AiChatService RAG 集成（TDD）

- [ ] 7.1 修改 `AiChatServiceImplTest`：新增测试用例验证 RAG 启用且有检索结果时 System Prompt 被增强、RAG 启用但无检索结果时 System Prompt 不变、RAG 禁用时跳过检索、检索服务异常时 System Prompt 不变（透明降级）
- [ ] 7.2 运行测试验证编译失败，然后修改 `AiChatServiceImpl`：注入 `KnowledgeRetrievalService`（`@Autowired(required = false)` 避免 Chroma 不可用时启动失败）和 `RagProperties`。在 `streamMessage()` 方法构建 messages 前，当 ragEnabled 为 true 时调用 `retrievalService.retrieve(message)` 获取文档列表，非空时调用 `buildContextSection(docs)` 增强 systemPrompt。`buildContextSection()` 按 `[SourceType: Title]\nContent` 格式拼接，总长度不超过 maxContextChars
- [ ] 7.3 运行测试验证全部通过（包含原有测试不受影响 + 新增 RAG 测试）

## 8. 全量构建与集成验证

- [ ] 8.1 运行 `mvnw.cmd clean test` 验证所有后端测试通过，BUILD SUCCESS
- [ ] 8.2 启动 Chroma 容器 + 后端应用，验证启动日志包含知识摄入成功信息（8 个文档已索引）
- [ ] 8.3 调用 `POST /api/ai/chat/stream` 发送 "What should I eat in Chengdu?"，验证 AI 回答包含成都相关平台数据（目的地信息或帖子内容）
- [ ] 8.4 调用 `POST /api/ai/chat/stream` 发送 "Hello, how are you?"，验证 AI 正常回答（不注入检索上下文）
- [ ] 8.5 停止 Chroma 容器，调用 `POST /api/ai/chat/stream` 发送消息，验证对话正常进行（退化为纯 LLM）
- [ ] 8.6 调用 `POST /api/ai/knowledge/reindex`，验证返回 `{ "indexedDocuments": 8, "sources": { "DESTINATION": 5, "POST": 3 } }`
- [ ] 8.7 验证 `POST /api/ai/chat/stream` SSE 响应格式与变更前完全一致（前端无需修改）
