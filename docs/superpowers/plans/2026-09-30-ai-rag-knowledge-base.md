# AI RAG Knowledge Base Implementation Plan

> **For agentic workers:** Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task.

**Goal:** 为 ChinaBuddy AI Travel Assistant 增加 RAG 知识库能力，使 AI 基于平台目的地和社区帖子数据回答问题。

**Architecture:** Chroma 向量数据库（Docker）存储文档嵌入向量，DashScope text-embedding-v3 生成向量。KnowledgeIngestionService 在启动时将硬编码的目的地和帖子数据索引到 Chroma。KnowledgeRetrievalService 在每次用户提问时执行向量检索，通过余弦相似度阈值过滤无关结果。AiChatServiceImpl 在构建 System Prompt 前调用检索服务，有结果时增强 prompt，无结果或 RAG 失败时透明退化为纯 LLM。

**Tech Stack:** Java 17, Spring Boot 3.3.3, Spring AI 1.0.0, Chroma Docker, DashScope Embedding API, JUnit 5 + Mockito

**Spec:** `openspec/changes/ai-rag-knowledge-base/` (proposal.md, design.md, specs/)

## Global Constraints

- 后端 API 响应使用 `Result<T>` 信封（`code`, `message`, `data`）
- Auth via `X-User-Id` header（`CurrentUserUtil.requireUserId(request)`）
- Service pattern: interface + `*Impl` class with `@Service`, `@RequiredArgsConstructor`
- Test pattern: JUnit 5 + Mockito + AssertJ, `@ExtendWith(MockitoExtension.class)`, `@Nested` classes
- RAG 失败绝不阻断对话功能（核心原则）
- 前端零修改

---

## File Structure

### Backend — New Files
| File | Responsibility |
|------|---------------|
| `config/RagProperties.java` | RAG 配置属性类（enabled, topK, relevanceThreshold, maxContextChars） |
| `dto/RetrievedDocument.java` | 检索结果 DTO（content, sourceType, sourceId, similarityScore, metadata） |
| `dto/response/ReindexResponse.java` | 重新索引响应 DTO（indexedDocuments, sources） |
| `service/KnowledgeIngestionService.java` | 知识摄入服务接口 |
| `service/impl/KnowledgeIngestionServiceImpl.java` | 知识摄入服务实现 |
| `service/KnowledgeRetrievalService.java` | 知识检索服务接口 |
| `service/impl/KnowledgeRetrievalServiceImpl.java` | 知识检索服务实现 |
| `controller/KnowledgeController.java` | 重新索引 REST API |
| `test/.../config/RagPropertiesTest.java` | 配置属性测试 |
| `test/.../service/impl/KnowledgeIngestionServiceImplTest.java` | 摄入服务测试 |
| `test/.../service/impl/KnowledgeRetrievalServiceImplTest.java` | 检索服务测试 |
| `test/.../controller/KnowledgeControllerTest.java` | Controller 测试 |

### Backend — Modified Files
| File | Change |
|------|--------|
| `pom.xml` | 新增 `spring-ai-chroma-store-spring-boot-starter` 依赖 |
| `application.yml` | 新增 embedding、chroma、rag 配置 |
| `service/impl/AiChatServiceImpl.java` | 集成 RAG 检索步骤，增强 System Prompt |
| `test/.../service/impl/AiChatServiceImplTest.java` | 新增 RAG 集成测试用例 |

### Infrastructure — New Files
| File | Responsibility |
|------|---------------|
| `docker-compose.yml` | Chroma 容器编排 |

---

## Task 1: Backend — Chroma 依赖

**Files:**
- Modify: `backend/pom.xml`

**Interfaces:**
- Consumes: Spring AI BOM (已存在)
- Produces: `VectorStore` (ChromaVectorStore) bean 可注入

- [ ] **Step 1: 添加 Chroma vector store 依赖到 pom.xml**

在 `backend/pom.xml` 的 `<dependencies>` 中，WebFlux 依赖之后添加：

```xml
<!-- Spring AI Chroma Vector Store -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-chroma-store-spring-boot-starter</artifactId>
</dependency>
```

- [ ] **Step 2: 验证编译**

Run: `cd backend; .\mvnw.cmd compile`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/pom.xml
git commit -m "feat(rag): add spring-ai-chroma-store dependency"
```

---

## Task 2: Backend — Application Configuration

**Files:**
- Modify: `backend/src/main/resources/application.yml`

**Interfaces:**
- Consumes: Spring AI auto-configuration
- Produces: EmbeddingModel + ChromaVectorStore + RagProperties 配置就绪

- [ ] **Step 1: 添加 embedding、chroma、rag 配置到 application.yml**

在 `spring.ai.openai` 节点下（与现有 `chat:` 同级）添加 `embedding:` 配置：

```yaml
  ai:
    openai:
      base-url: https://dashscope.aliyuncs.com/compatible-mode
      api-key: ${DASHSCOPE_API_KEY:}
      chat:
        options:
          model: qwen3-max
          temperature: 0.7
      embedding:
        options:
          model: text-embedding-v3

    vectorstore:
      chroma:
        client:
          host: http://localhost
          port: 8000
        collection-name: chinabuddy-knowledge
```

在 `app.ai` 节点下（与现有 `system-prompt` 同级）添加 `rag:` 配置：

```yaml
app:
  ai:
    system-prompt: >
      ...（保持不变）...
    rag:
      enabled: true
      top-k: 5
      relevance-threshold: 0.65
      max-context-chars: 2000
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/resources/application.yml
git commit -m "feat(rag): add embedding, chroma, and rag configuration"
```

---

## Task 3: Backend — RagProperties 配置类 (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/config/RagProperties.java`
- Create: `backend/src/test/java/com/example/myfirst/config/RagPropertiesTest.java`

**Interfaces:**
- Consumes: `application.yml` 中 `app.ai.rag.*` 配置
- Produces: `RagProperties` bean 供 KnowledgeRetrievalService 和 AiChatServiceImpl 注入

- [ ] **Step 1: 编写 RagPropertiesTest**

```java
package com.example.myfirst.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RagPropertiesTest {

    @Test
    @DisplayName("默认值应正确设置")
    void shouldHaveCorrectDefaults() {
        RagProperties props = new RagProperties();

        assertThat(props.isEnabled()).isTrue();
        assertThat(props.getTopK()).isEqualTo(5);
        assertThat(props.getRelevanceThreshold()).isEqualTo(0.65);
        assertThat(props.getMaxContextChars()).isEqualTo(2000);
    }
}
```

- [ ] **Step 2: 运行测试 — 预期编译失败**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=RagPropertiesTest`
Expected: FAIL — `RagProperties` not found

- [ ] **Step 3: 创建 RagProperties**

```java
package com.example.myfirst.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

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

- [ ] **Step 4: 运行测试 — 预期通过**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=RagPropertiesTest`
Expected: PASS (1/1)

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/config/RagProperties.java
git add backend/src/test/java/com/example/myfirst/config/RagPropertiesTest.java
git commit -m "feat(rag): add RagProperties configuration class with tests"
```

---

## Task 4: Backend — DTOs

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/dto/RetrievedDocument.java`
- Create: `backend/src/main/java/com/example/myfirst/dto/response/ReindexResponse.java`

**Interfaces:**
- Consumes: Nothing
- Produces: `RetrievedDocument` 供 KnowledgeRetrievalService 返回；`ReindexResponse` 供 KnowledgeController 返回

- [ ] **Step 1: 创建 RetrievedDocument**

```java
package com.example.myfirst.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
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

- [ ] **Step 2: 创建 ReindexResponse**

```java
package com.example.myfirst.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReindexResponse {

    /** 索引的文档总数 */
    private int indexedDocuments;

    /** 各来源类型的文档数量 */
    private Map<String, Integer> sources;
}
```

- [ ] **Step 3: 验证编译**

Run: `cd backend; .\mvnw.cmd compile`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/dto/
git commit -m "feat(rag): add RetrievedDocument and ReindexResponse DTOs"
```

---

## Task 5: Backend — KnowledgeIngestionService (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/service/KnowledgeIngestionService.java`
- Create: `backend/src/main/java/com/example/myfirst/service/impl/KnowledgeIngestionServiceImpl.java`
- Create: `backend/src/test/java/com/example/myfirst/service/impl/KnowledgeIngestionServiceImplTest.java`

**Interfaces:**
- Consumes: `VectorStore` (Chroma), DestinationController 硬编码数据, PostController 硬编码数据
- Produces: 文档已索引到 Chroma，`reindex()` 返回 `ReindexResponse`

- [ ] **Step 1: 编写 KnowledgeIngestionServiceImplTest**

```java
package com.example.myfirst.service.impl;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.VectorStore;

import com.example.myfirst.dto.response.ReindexResponse;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class KnowledgeIngestionServiceImplTest {

    @Mock
    private VectorStore vectorStore;

    @InjectMocks
    private KnowledgeIngestionServiceImpl ingestionService;

    @Nested
    @DisplayName("ingestAll")
    class IngestAll {

        @Test
        @DisplayName("应摄入 5 个目的地 + 3 个帖子 = 8 个文档")
        void shouldIngest8Documents() {
            ingestionService.ingestAll();

            @SuppressWarnings("unchecked")
            ArgumentCaptor<List<Document>> captor = ArgumentCaptor.forClass(List.class);
            verify(vectorStore).add(captor.capture());

            List<Document> docs = captor.getValue();
            assertThat(docs).hasSize(8);
        }

        @Test
        @DisplayName("目的地文档内容格式应为 '{cityName} — {highlight}'")
        void shouldFormatDestinationContentCorrectly() {
            ingestionService.ingestAll();

            @SuppressWarnings("unchecked")
            ArgumentCaptor<List<Document>> captor = ArgumentCaptor.forClass(List.class);
            verify(vectorStore).add(captor.capture());

            List<Document> docs = captor.getValue();
            Document firstDest = docs.get(0);
            assertThat(firstDest.getContent()).isEqualTo("Chengdu — Home of giant pandas and world-famous Sichuan cuisine");
            assertThat(firstDest.getMetadata()).containsEntry("sourceType", "DESTINATION");
            assertThat(firstDest.getMetadata()).containsEntry("sourceId", 1L);
            assertThat(firstDest.getMetadata()).containsEntry("cityName", "Chengdu");
            assertThat(firstDest.getMetadata()).containsEntry("popularityTag", "Hot");
        }

        @Test
        @DisplayName("帖子文档内容格式应为 '{title}\\n{excerpt}'")
        void shouldFormatPostContentCorrectly() {
            ingestionService.ingestAll();

            @SuppressWarnings("unchecked")
            ArgumentCaptor<List<Document>> captor = ArgumentCaptor.forClass(List.class);
            verify(vectorStore).add(captor.capture());

            List<Document> docs = captor.getValue();
            // 帖子从 index 5 开始（5 个目的地之后）
            Document firstPost = docs.get(5);
            assertThat(firstPost.getMetadata()).containsEntry("sourceType", "POST");
            assertThat(firstPost.getMetadata()).containsEntry("sourceId", 1L);
            assertThat(firstPost.getMetadata()).containsEntry("authorName", "Li Wei");
            assertThat(firstPost.getContent()).contains("3 Days in Chengdu");
        }
    }

    @Nested
    @DisplayName("reindex")
    class Reindex {

        @Test
        @DisplayName("应先清空再重新摄入，返回正确统计")
        void shouldClearAndReingest() {
            ReindexResponse response = ingestionService.reindex();

            verify(vectorStore).delete(anyList());
            verify(vectorStore).add(anyList());

            assertThat(response.getIndexedDocuments()).isEqualTo(8);
            assertThat(response.getSources()).containsEntry("DESTINATION", 5);
            assertThat(response.getSources()).containsEntry("POST", 3);
        }
    }
}
```

- [ ] **Step 2: 运行测试 — 预期编译失败**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=KnowledgeIngestionServiceImplTest`
Expected: FAIL — classes not found

- [ ] **Step 3: 创建 KnowledgeIngestionService 接口**

```java
package com.example.myfirst.service;

import com.example.myfirst.dto.response.ReindexResponse;

public interface KnowledgeIngestionService {

    /** 全量摄入所有目的地和帖子数据到向量数据库 */
    void ingestAll();

    /** 清空向量数据库后重新全量摄入（线程安全） */
    ReindexResponse reindex();
}
```

- [ ] **Step 4: 创建 KnowledgeIngestionServiceImpl**

```java
package com.example.myfirst.service.impl;

import com.example.myfirst.dto.response.DestinationResponse;
import com.example.myfirst.dto.response.PostResponse;
import com.example.myfirst.dto.response.ReindexResponse;
import com.example.myfirst.service.KnowledgeIngestionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j
@Service
public class KnowledgeIngestionServiceImpl implements KnowledgeIngestionService {

    private final VectorStore vectorStore;
    private final ReentrantLock reindexLock = new ReentrantLock();

    /** 目的地硬编码数据（与 DestinationController.FEATURED_DESTINATIONS 保持一致） */
    private static final List<DestinationResponse> DESTINATIONS = List.of(
            new DestinationResponse(1L, "Chengdu", "chengdu",
                    "Home of giant pandas and world-famous Sichuan cuisine",
                    "https://images.unsplash.com/photo-1599571234909-29ed5d1321d6?w=800&h=600&fit=crop", "Hot"),
            new DestinationResponse(2L, "Xi'an", "xi-an",
                    "Walk through history along the ancient city walls",
                    "https://images.unsplash.com/photo-1591012911207-0dbac31f37da?w=800&h=600&fit=crop", "Trending"),
            new DestinationResponse(3L, "Guilin", "guilin",
                    "Stunning karst landscapes along the Li River",
                    "https://images.unsplash.com/photo-1537531383496-f4749b8032cf?w=800&h=600&fit=crop", "Editor's Pick"),
            new DestinationResponse(4L, "Shanghai", "shanghai",
                    "Where futuristic skyline meets centuries of culture",
                    "https://images.unsplash.com/photo-1537519646099-5eb3a4f1a3f3?w=800&h=600&fit=crop", "Hot"),
            new DestinationResponse(5L, "Lhasa", "lhasa",
                    "The rooftop of the world and heart of Tibetan culture",
                    "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800&h=600&fit=crop", "Editor's Pick")
    );

    /** 帖子硬编码数据（与 PostController.FEATURED_POSTS 保持一致） */
    private static final List<PostResponse> POSTS = List.of(
            new PostResponse(1L, "Li Wei", "https://i.pravatar.cc/40?u=liwei",
                    "3 Days in Chengdu — A Food Lover's Guide",
                    "From spicy hotpot in Yulin district to the adorable giant pandas at the breeding center, Chengdu exceeded every expectation. Here's my curated 3-day itinerary covering the best food spots and must-see attractions that most travel guides miss completely.",
                    1250),
            new PostResponse(2L, "Sarah Chen", "https://i.pravatar.cc/40?u=sarahchen",
                    "Hidden Gems Along the Li River",
                    "Skip the crowded tourist boats and discover these secret spots along the Li River between Guilin and Yangshuo. I spent two weeks exploring caves, bamboo forests, and local villages that barely appear in any guidebook.",
                    876),
            new PostResponse(3L, "Marco Rossi", "https://i.pravatar.cc/40?u=marco",
                    "First-Time Visitor Tips for Xi'an",
                    "Planning your first trip to Xi'an? Here are my top tips after living here for 5 years — from the best time to visit the Terracotta Warriors to finding authentic biangbiang noodles in the Muslim Quarter.",
                    42)
    );

    public KnowledgeIngestionServiceImpl(VectorStore vectorStore) {
        this.vectorStore = vectorStore;
    }

    @PostConstruct
    void autoIngestOnStartup() {
        try {
            // 检查集合是否为空（通过空查询试探）
            List<Document> existing = vectorStore.similaritySearch(
                    org.springframework.ai.vectorstore.SearchRequest.query("check").withTopK(1));
            if (existing.isEmpty()) {
                log.info("Chroma collection is empty, starting auto-ingestion...");
                ingestAll();
                log.info("Auto-ingestion completed: 8 documents indexed (5 destinations + 3 posts)");
            } else {
                log.info("Chroma collection already has documents, skipping auto-ingestion");
            }
        } catch (Exception e) {
            log.error("Auto-ingestion failed (RAG will be degraded): {}", e.getMessage());
        }
    }

    @Override
    public void ingestAll() {
        List<Document> documents = new ArrayList<>();

        // 转换目的地数据为文档
        for (DestinationResponse dest : DESTINATIONS) {
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("sourceType", "DESTINATION");
            metadata.put("sourceId", dest.getId());
            metadata.put("cityName", dest.getCityName());
            metadata.put("popularityTag", dest.getPopularityTag());

            String content = dest.getCityName() + " — " + dest.getHighlight();
            documents.add(new Document(content, metadata));
        }

        // 转换帖子数据为文档
        for (PostResponse post : POSTS) {
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("sourceType", "POST");
            metadata.put("sourceId", post.getId());
            metadata.put("authorName", post.getAuthorName());

            String content = post.getTitle() + "\n" + post.getExcerpt();
            documents.add(new Document(content, metadata));
        }

        vectorStore.add(documents);
        log.info("Ingested {} documents into vector store", documents.size());
    }

    @Override
    public ReindexResponse reindex() {
        reindexLock.lock();
        try {
            // 清空现有文档
            List<Document> allDocs = vectorStore.similaritySearch(
                    org.springframework.ai.vectorstore.SearchRequest.query("*").withTopK(1000));
            if (!allDocs.isEmpty()) {
                vectorStore.delete(allDocs);
                log.info("Cleared {} existing documents from vector store", allDocs.size());
            }

            // 重新摄入
            ingestAll();

            Map<String, Integer> sources = Map.of(
                    "DESTINATION", DESTINATIONS.size(),
                    "POST", POSTS.size()
            );
            return new ReindexResponse(DESTINATIONS.size() + POSTS.size(), sources);
        } finally {
            reindexLock.unlock();
        }
    }
}
```

- [ ] **Step 5: 运行测试 — 预期通过**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=KnowledgeIngestionServiceImplTest`
Expected: PASS (3/3)

注意：`autoIngestOnStartup()` 的 `@PostConstruct` 方法在单元测试中不会被触发（因为 `VectorStore` 是 Mock，且 `@PostConstruct` 只在 Spring 容器管理时触发）。集成测试中会覆盖。

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/service/KnowledgeIngestionService.java
git add backend/src/main/java/com/example/myfirst/service/impl/KnowledgeIngestionServiceImpl.java
git add backend/src/test/java/com/example/myfirst/service/impl/KnowledgeIngestionServiceImplTest.java
git commit -m "feat(rag): add KnowledgeIngestionService with auto-ingest and reindex"
```

---

## Task 6: Backend — KnowledgeRetrievalService (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/service/KnowledgeRetrievalService.java`
- Create: `backend/src/main/java/com/example/myfirst/service/impl/KnowledgeRetrievalServiceImpl.java`
- Create: `backend/src/test/java/com/example/myfirst/service/impl/KnowledgeRetrievalServiceImplTest.java`

**Interfaces:**
- Consumes: `VectorStore` (Chroma), `RagProperties`
- Produces: `List<RetrievedDocument>` 供 AiChatServiceImpl 使用

- [ ] **Step 1: 编写 KnowledgeRetrievalServiceImplTest**

```java
package com.example.myfirst.service.impl;

import com.example.myfirst.config.RagProperties;
import com.example.myfirst.dto.RetrievedDocument;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class KnowledgeRetrievalServiceImplTest {

    @Mock
    private VectorStore vectorStore;

    private RagProperties ragProperties;
    private KnowledgeRetrievalServiceImpl retrievalService;

    @BeforeEach
    void setUp() {
        ragProperties = new RagProperties();
        ragProperties.setTopK(5);
        ragProperties.setRelevanceThreshold(0.65);
        ragProperties.setMaxContextChars(2000);
        retrievalService = new KnowledgeRetrievalServiceImpl(vectorStore, ragProperties);
    }

    @Nested
    @DisplayName("retrieve")
    class Retrieve {

        @Test
        @DisplayName("有相关结果时应返回过滤后的文档列表")
        void shouldReturnFilteredDocuments() {
            Document doc1 = new Document("Chengdu food guide", Map.of(
                    "sourceType", "DESTINATION", "sourceId", 1L, "cityName", "Chengdu"));
            Document doc2 = new Document("Xi'an tips", Map.of(
                    "sourceType", "POST", "sourceId", 2L, "authorName", "Sarah"));

            when(vectorStore.similaritySearch(any(SearchRequest.class)))
                    .thenReturn(List.of(
                            createScoredDocument(doc1, 0.85),
                            createScoredDocument(doc2, 0.50)  // 低于 0.65 阈值
                    ));

            List<RetrievedDocument> results = retrievalService.retrieve("What to eat in Chengdu?");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).getContent()).isEqualTo("Chengdu food guide");
            assertThat(results.get(0).getSourceType()).isEqualTo("DESTINATION");
            assertThat(results.get(0).getSimilarityScore()).isEqualTo(0.85);
        }

        @Test
        @DisplayName("所有结果低于阈值时应返回空列表")
        void shouldReturnEmptyWhenAllBelowThreshold() {
            Document doc = new Document("Unrelated content", Map.of("sourceType", "POST"));
            when(vectorStore.similaritySearch(any(SearchRequest.class)))
                    .thenReturn(List.of(createScoredDocument(doc, 0.30)));

            List<RetrievedDocument> results = retrievalService.retrieve("Hello, how are you?");

            assertThat(results).isEmpty();
        }

        @Test
        @DisplayName("VectorStore 异常时应返回空列表（不抛异常）")
        void shouldReturnEmptyOnVectorStoreException() {
            when(vectorStore.similaritySearch(any(SearchRequest.class)))
                    .thenThrow(new RuntimeException("Chroma unavailable"));

            List<RetrievedDocument> results = retrievalService.retrieve("test query");

            assertThat(results).isEmpty();
        }

        @Test
        @DisplayName("检索结果总内容长度不应超过 maxContextChars")
        void shouldTruncateByMaxContextChars() {
            ragProperties.setMaxContextChars(50); // 设置很小的值用于测试
            retrievalService = new KnowledgeRetrievalServiceImpl(vectorStore, ragProperties);

            String longContent = "A".repeat(30);
            Document doc1 = new Document(longContent, Map.of("sourceType", "DESTINATION", "sourceId", 1L));
            Document doc2 = new Document(longContent, Map.of("sourceType", "POST", "sourceId", 1L));

            when(vectorStore.similaritySearch(any(SearchRequest.class)))
                    .thenReturn(List.of(
                            createScoredDocument(doc1, 0.90),
                            createScoredDocument(doc2, 0.80)
                    ));

            List<RetrievedDocument> results = retrievalService.retrieve("test");

            int totalChars = results.stream().mapToInt(d -> d.getContent().length()).sum();
            assertThat(totalChars).isLessThanOrEqualTo(50);
        }
    }

    /**
     * 辅助方法：创建带 score 的 Document（Spring AI 的 Document 通过 metadata 中的 "distance" 存储分数）
     */
    private Document createScoredDocument(Document doc, double score) {
        Map<String, Object> metadata = new java.util.HashMap<>(doc.getMetadata());
        metadata.put("distance", 1.0 - score); // distance = 1 - similarity
        return new Document(doc.getContent(), metadata);
    }
}
```

- [ ] **Step 2: 运行测试 — 预期编译失败**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=KnowledgeRetrievalServiceImplTest`
Expected: FAIL — classes not found

- [ ] **Step 3: 创建 KnowledgeRetrievalService 接口**

```java
package com.example.myfirst.service;

import com.example.myfirst.dto.RetrievedDocument;

import java.util.List;

public interface KnowledgeRetrievalService {

    /**
     * 根据用户查询检索相关知识文档。
     * 失败时返回空列表（不抛出异常），确保 RAG 不阻断对话。
     */
    List<RetrievedDocument> retrieve(String query);
}
```

- [ ] **Step 4: 创建 KnowledgeRetrievalServiceImpl**

```java
package com.example.myfirst.service.impl;

import com.example.myfirst.config.RagProperties;
import com.example.myfirst.dto.RetrievedDocument;
import com.example.myfirst.service.KnowledgeRetrievalService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class KnowledgeRetrievalServiceImpl implements KnowledgeRetrievalService {

    private final VectorStore vectorStore;
    private final RagProperties ragProperties;

    public KnowledgeRetrievalServiceImpl(VectorStore vectorStore, RagProperties ragProperties) {
        this.vectorStore = vectorStore;
        this.ragProperties = ragProperties;
    }

    @Override
    public List<RetrievedDocument> retrieve(String query) {
        try {
            List<Document> results = vectorStore.similaritySearch(
                    SearchRequest.query(query).withTopK(ragProperties.getTopK()));

            List<RetrievedDocument> filtered = new ArrayList<>();
            int totalChars = 0;

            for (Document doc : results) {
                // Spring AI Chroma 返回的 distance = 1 - cosine_similarity
                double distance = getDistance(doc);
                double similarity = 1.0 - distance;

                if (similarity < ragProperties.getRelevanceThreshold()) {
                    continue;
                }

                String content = doc.getContent() != null ? doc.getContent() : "";
                if (totalChars + content.length() > ragProperties.getMaxContextChars()) {
                    break; // 超过最大上下文长度，停止添加
                }

                Map<String, Object> metadata = doc.getMetadata();
                filtered.add(RetrievedDocument.builder()
                        .content(content)
                        .sourceType(getStringMeta(metadata, "sourceType"))
                        .sourceId(getLongMeta(metadata, "sourceId"))
                        .similarityScore(similarity)
                        .metadata(metadata)
                        .build());

                totalChars += content.length();
            }

            return filtered;
        } catch (Exception e) {
            log.warn("Knowledge retrieval failed (degrading to pure LLM): {}", e.getMessage());
            return List.of();
        }
    }

    private double getDistance(Document doc) {
        Object distanceObj = doc.getMetadata().get("distance");
        if (distanceObj instanceof Number) {
            return ((Number) distanceObj).doubleValue();
        }
        return 1.0; // 默认最大距离（最低相似度）
    }

    private String getStringMeta(Map<String, Object> metadata, String key) {
        Object value = metadata.get(key);
        return value != null ? value.toString() : null;
    }

    private Long getLongMeta(Map<String, Object> metadata, String key) {
        Object value = metadata.get(key);
        if (value instanceof Number) {
            return ((Number) value).longValue();
        }
        return null;
    }
}
```

- [ ] **Step 5: 运行测试 — 预期通过**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=KnowledgeRetrievalServiceImplTest`
Expected: PASS (4/4)

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/service/KnowledgeRetrievalService.java
git add backend/src/main/java/com/example/myfirst/service/impl/KnowledgeRetrievalServiceImpl.java
git add backend/src/test/java/com/example/myfirst/service/impl/KnowledgeRetrievalServiceImplTest.java
git commit -m "feat(rag): add KnowledgeRetrievalService with threshold filtering"
```

---

## Task 7: Backend — KnowledgeController (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/controller/KnowledgeController.java`
- Create: `backend/src/test/java/com/example/myfirst/controller/KnowledgeControllerTest.java`

**Interfaces:**
- Consumes: `KnowledgeIngestionService`
- Produces: `POST /api/ai/knowledge/reindex` 端点

- [ ] **Step 1: 编写 KnowledgeControllerTest**

```java
package com.example.myfirst.controller;

import com.example.myfirst.dto.response.ReindexResponse;
import com.example.myfirst.service.KnowledgeIngestionService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class KnowledgeControllerTest {

    @Mock
    private KnowledgeIngestionService ingestionService;

    @InjectMocks
    private KnowledgeController controller;

    @Test
    @DisplayName("重新索引成功时应返回 200 + 正确响应体")
    void shouldReturnSuccessResponse() {
        ReindexResponse reindexResponse = new ReindexResponse(8, Map.of("DESTINATION", 5, "POST", 3));
        when(ingestionService.reindex()).thenReturn(reindexResponse);

        var result = controller.reindex();

        assertThat(result.getCode()).isEqualTo(200);
        assertThat(result.getData().getIndexedDocuments()).isEqualTo(8);
        assertThat(result.getData().getSources()).containsEntry("DESTINATION", 5);
        assertThat(result.getData().getSources()).containsEntry("POST", 3);
    }

    @Test
    @DisplayName("重新索引失败时应抛出异常（由 GlobalExceptionHandler 处理为 500）")
    void shouldThrowOnReindexFailure() {
        when(ingestionService.reindex()).thenThrow(new RuntimeException("Chroma unavailable"));

        assertThatThrownBy(() -> controller.reindex())
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Chroma unavailable");
    }
}
```

- [ ] **Step 2: 运行测试 — 预期编译失败**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=KnowledgeControllerTest`
Expected: FAIL — `KnowledgeController` not found

- [ ] **Step 3: 创建 KnowledgeController**

```java
package com.example.myfirst.controller;

import com.example.myfirst.common.Result;
import com.example.myfirst.dto.response.ReindexResponse;
import com.example.myfirst.service.KnowledgeIngestionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/api/ai/knowledge")
@RequiredArgsConstructor
public class KnowledgeController {

    private final KnowledgeIngestionService ingestionService;

    @PostMapping("/reindex")
    public Result<ReindexResponse> reindex() {
        ReindexResponse response = ingestionService.reindex();
        return Result.success(response);
    }
}
```

- [ ] **Step 4: 运行测试 — 预期通过**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=KnowledgeControllerTest`
Expected: PASS (2/2)

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/controller/KnowledgeController.java
git add backend/src/test/java/com/example/myfirst/controller/KnowledgeControllerTest.java
git commit -m "feat(rag): add KnowledgeController with reindex endpoint"
```

---

## Task 8: Backend — AiChatService RAG 集成 (TDD)

**Files:**
- Modify: `backend/src/main/java/com/example/myfirst/service/impl/AiChatServiceImpl.java`
- Modify: `backend/src/test/java/com/example/myfirst/service/impl/AiChatServiceImplTest.java`

**Interfaces:**
- Consumes: `KnowledgeRetrievalService`, `RagProperties`
- Produces: RAG 增强的 System Prompt（当有检索结果时）

- [ ] **Step 1: 在 AiChatServiceImplTest 中新增 RAG 测试用例**

在现有 `AiChatServiceImplTest.java` 中添加以下 import 和 Mock 字段：

```java
// 新增 imports
import com.example.myfirst.config.RagProperties;
import com.example.myfirst.dto.RetrievedDocument;
import com.example.myfirst.service.KnowledgeRetrievalService;

// 新增 Mock 字段（在现有 @Mock 字段后添加）
@Mock private KnowledgeRetrievalService knowledgeRetrievalService;

// 新增 RagProperties（非 Mock，使用真实对象）
private RagProperties ragProperties;
```

在 `setUp()` 或 `@BeforeEach` 方法中初始化（如果没有则添加）：

```java
@org.junit.jupiter.api.BeforeEach
void setUp() {
    ragProperties = new RagProperties();
    ragProperties.setEnabled(true);
    ragProperties.setTopK(5);
    ragProperties.setRelevanceThreshold(0.65);
    ragProperties.setMaxContextChars(2000);

    // 通过反射注入 @Value 字段和新的依赖
    org.springframework.test.util.ReflectionTestUtils.setField(aiChatService, "systemPrompt",
            "You are ChinaBuddy, an expert AI travel assistant.");
    org.springframework.test.util.ReflectionTestUtils.setField(aiChatService, "ragProperties", ragProperties);
    org.springframework.test.util.ReflectionTestUtils.setField(aiChatService, "knowledgeRetrievalService",
            knowledgeRetrievalService);
}
```

在 `@Nested` 类中添加新的测试组：

```java
@Nested
@DisplayName("RAG 集成")
class RagIntegration {

    @Test
    @DisplayName("RAG 启用且有检索结果时 System Prompt 应被增强")
    void shouldEnhanceSystemPromptWhenRagReturnsResults() {
        ragProperties.setEnabled(true);

        RetrievedDocument doc = RetrievedDocument.builder()
                .content("Chengdu — Home of giant pandas")
                .sourceType("DESTINATION")
                .sourceId(1L)
                .similarityScore(0.85)
                .metadata(java.util.Map.of("cityName", "Chengdu", "sourceType", "DESTINATION"))
                .build();

        when(knowledgeRetrievalService.retrieve("What to eat in Chengdu?"))
                .thenReturn(java.util.List.of(doc));

        // 准备 conversation
        AiConversation conv = new AiConversation();
        conv.setId(100L);
        conv.setUserId(1L);
        when(conversationRepository.findActiveByUserId(1L)).thenReturn(java.util.Optional.of(conv));
        when(messageRepository.findTop20ByConversationIdOrderByCreatedAtDesc(100L))
                .thenReturn(java.util.List.of());

        // Mock chatModel.stream 以捕获 Prompt
        org.mockito.ArgumentCaptor<org.springframework.ai.chat.prompt.Prompt> promptCaptor =
                org.mockito.ArgumentCaptor.forClass(org.springframework.ai.chat.prompt.Prompt.class);
        lenient().when(chatModel.stream(promptCaptor.capture()))
                .thenReturn(reactor.core.publisher.Flux.empty());

        // 执行
        aiChatService.streamMessage(1L, "What to eat in Chengdu?", null);

        // 验证 System Prompt 包含检索上下文
        org.springframework.ai.chat.prompt.Prompt capturedPrompt = promptCaptor.getValue();
        String systemContent = capturedPrompt.getInstructions().get(0).getContent();
        assertThat(systemContent).contains("Chengdu — Home of giant pandas");
        assertThat(systemContent).contains("[DESTINATION:");
    }

    @Test
    @DisplayName("RAG 启用但无检索结果时 System Prompt 应保持不变")
    void shouldNotEnhanceWhenNoResults() {
        ragProperties.setEnabled(true);
        when(knowledgeRetrievalService.retrieve("Hello")).thenReturn(java.util.List.of());

        AiConversation conv = new AiConversation();
        conv.setId(100L);
        conv.setUserId(1L);
        when(conversationRepository.findActiveByUserId(1L)).thenReturn(java.util.Optional.of(conv));
        when(messageRepository.findTop20ByConversationIdOrderByCreatedAtDesc(100L))
                .thenReturn(java.util.List.of());

        org.mockito.ArgumentCaptor<org.springframework.ai.chat.prompt.Prompt> promptCaptor =
                org.mockito.ArgumentCaptor.forClass(org.springframework.ai.chat.prompt.Prompt.class);
        lenient().when(chatModel.stream(promptCaptor.capture()))
                .thenReturn(reactor.core.publisher.Flux.empty());

        aiChatService.streamMessage(1L, "Hello", null);

        org.springframework.ai.chat.prompt.Prompt capturedPrompt = promptCaptor.getValue();
        String systemContent = capturedPrompt.getInstructions().get(0).getContent();
        assertThat(systemContent).isEqualTo("You are ChinaBuddy, an expert AI travel assistant.");
        assertThat(systemContent).doesNotContain("[DESTINATION:");
    }

    @Test
    @DisplayName("RAG 禁用时应跳过检索")
    void shouldSkipRetrievalWhenRagDisabled() {
        ragProperties.setEnabled(false);

        AiConversation conv = new AiConversation();
        conv.setId(100L);
        conv.setUserId(1L);
        when(conversationRepository.findActiveByUserId(1L)).thenReturn(java.util.Optional.of(conv));
        when(messageRepository.findTop20ByConversationIdOrderByCreatedAtDesc(100L))
                .thenReturn(java.util.List.of());

        org.mockito.ArgumentCaptor<org.springframework.ai.chat.prompt.Prompt> promptCaptor =
                org.mockito.ArgumentCaptor.forClass(org.springframework.ai.chat.prompt.Prompt.class);
        lenient().when(chatModel.stream(promptCaptor.capture()))
                .thenReturn(reactor.core.publisher.Flux.empty());

        aiChatService.streamMessage(1L, "test", null);

        // 验证未调用检索服务
        verify(knowledgeRetrievalService, never()).retrieve(any());
    }

    @Test
    @DisplayName("检索服务异常时 System Prompt 应保持不变（透明降级）")
    void shouldDegradeGracefullyOnRetrievalException() {
        ragProperties.setEnabled(true);
        when(knowledgeRetrievalService.retrieve("test"))
                .thenThrow(new RuntimeException("Chroma unavailable"));

        AiConversation conv = new AiConversation();
        conv.setId(100L);
        conv.setUserId(1L);
        when(conversationRepository.findActiveByUserId(1L)).thenReturn(java.util.Optional.of(conv));
        when(messageRepository.findTop20ByConversationIdOrderByCreatedAtDesc(100L))
                .thenReturn(java.util.List.of());

        org.mockito.ArgumentCaptor<org.springframework.ai.chat.prompt.Prompt> promptCaptor =
                org.mockito.ArgumentCaptor.forClass(org.springframework.ai.chat.prompt.Prompt.class);
        lenient().when(chatModel.stream(promptCaptor.capture()))
                .thenReturn(reactor.core.publisher.Flux.empty());

        aiChatService.streamMessage(1L, "test", null);

        org.springframework.ai.chat.prompt.Prompt capturedPrompt = promptCaptor.getValue();
        String systemContent = capturedPrompt.getInstructions().get(0).getContent();
        assertThat(systemContent).isEqualTo("You are ChinaBuddy, an expert AI travel assistant.");
    }
}
```

- [ ] **Step 2: 运行测试 — 预期编译失败**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiChatServiceImplTest`
Expected: FAIL — `KnowledgeRetrievalService`, `RagProperties` 等未注入到 AiChatServiceImpl

- [ ] **Step 3: 修改 AiChatServiceImpl 集成 RAG**

在 `AiChatServiceImpl.java` 中进行以下修改：

**新增 imports**（在现有 imports 后添加）：

```java
import com.example.myfirst.config.RagProperties;
import com.example.myfirst.dto.RetrievedDocument;
import com.example.myfirst.service.KnowledgeRetrievalService;
import org.springframework.beans.factory.annotation.Autowired;
```

**修改字段声明**（将 `@RequiredArgsConstructor` 替换为显式构造函数，因为 `KnowledgeRetrievalService` 是可选注入）：

删除类上的 `@RequiredArgsConstructor` 注解，替换为：

```java
    private final AiConversationRepository conversationRepository;
    private final AiMessageRepository messageRepository;
    private final ChatModel chatModel;
    private final KnowledgeRetrievalService knowledgeRetrievalService;
    private final RagProperties ragProperties;

    @Autowired
    public AiChatServiceImpl(
            AiConversationRepository conversationRepository,
            AiMessageRepository messageRepository,
            ChatModel chatModel,
            @Autowired(required = false) KnowledgeRetrievalService knowledgeRetrievalService,
            RagProperties ragProperties) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.chatModel = chatModel;
        this.knowledgeRetrievalService = knowledgeRetrievalService;
        this.ragProperties = ragProperties;
    }
```

**在 `streamMessage()` 方法中，步骤 3（Build messages for AI model）之前插入 RAG 检索逻辑**：

将现有的：
```java
        // 3. Build messages for AI model
        List<Message> messages = new ArrayList<>();
        messages.add(new SystemMessage(systemPrompt));
```

替换为：
```java
        // 3. Build messages for AI model (with optional RAG enhancement)
        String effectivePrompt = systemPrompt;
        if (ragProperties.isEnabled() && knowledgeRetrievalService != null) {
            try {
                List<RetrievedDocument> docs = knowledgeRetrievalService.retrieve(message);
                if (!docs.isEmpty()) {
                    effectivePrompt = systemPrompt + buildContextSection(docs);
                }
            } catch (Exception e) {
                log.warn("RAG retrieval failed, using original prompt: {}", e.getMessage());
            }
        }

        List<Message> messages = new ArrayList<>();
        messages.add(new SystemMessage(effectivePrompt));
```

**在类末尾添加 `buildContextSection()` 私有方法**：

```java
    private String buildContextSection(List<RetrievedDocument> docs) {
        StringBuilder sb = new StringBuilder();
        sb.append("\n\n---\n");
        sb.append("Based on the following platform data, provide accurate and relevant information:\n\n");

        for (RetrievedDocument doc : docs) {
            String title = "";
            if ("DESTINATION".equals(doc.getSourceType())) {
                Object cityName = doc.getMetadata() != null ? doc.getMetadata().get("cityName") : null;
                title = cityName != null ? cityName.toString() : "Unknown";
            } else if ("POST".equals(doc.getSourceType())) {
                Object author = doc.getMetadata() != null ? doc.getMetadata().get("authorName") : null;
                title = author != null ? "Post by " + author : "Post";
            }
            sb.append("[").append(doc.getSourceType()).append(": ").append(title).append("]\n");
            sb.append(doc.getContent()).append("\n\n");
        }

        sb.append("---\n\n");
        sb.append("Instructions for using platform data:\n");
        sb.append("- Use the above information to enhance your response accuracy.\n");
        sb.append("- If the platform data conflicts with your knowledge, prefer the platform data.\n");
        sb.append("- Do not mention \"platform data\" or \"retrieved information\" in your response.\n");
        sb.append("- If the platform data is not relevant, ignore it and answer from your own knowledge.\n");

        return sb.toString();
    }
```

- [ ] **Step 4: 运行测试 — 预期全部通过**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiChatServiceImplTest`
Expected: PASS（原有测试 + 新增 4 个 RAG 测试全部通过）

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/service/impl/AiChatServiceImpl.java
git add backend/src/test/java/com/example/myfirst/service/impl/AiChatServiceImplTest.java
git commit -m "feat(rag): integrate RAG retrieval into AiChatServiceImpl with graceful degradation"
```

---

## Task 9: Infrastructure — Docker Compose

**Files:**
- Create: `docker-compose.yml` (项目根目录)

**Interfaces:**
- Consumes: Docker 环境
- Produces: Chroma 容器在端口 8000 运行

- [ ] **Step 1: 创建 docker-compose.yml**

```yaml
version: '3.8'
services:
  chroma:
    image: ghcr.io/chroma-core/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - chroma-data:/chroma/chroma
    environment:
      - IS_PERSISTENT=TRUE
      - ANONYMIZED_TELEMETRY=TRUE
    restart: unless-stopped

volumes:
  chroma-data:
```

- [ ] **Step 2: 启动 Chroma 容器并验证**

Run: `docker compose up -d`
Expected: Container started

Run: `curl http://localhost:8000/api/v1/heartbeat`
Expected: 返回 200

- [ ] **Step 3: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(rag): add docker-compose.yml for Chroma vector database"
```

---

## Task 10: 全量构建与集成验证

- [ ] **Step 1: 后端全量构建 + 测试**

Run: `cd backend; .\mvnw.cmd clean test`
Expected: All tests PASS, BUILD SUCCESS

- [ ] **Step 2: 启动 Chroma + 后端，验证自动摄入**

确保 Chroma 容器运行（`docker compose up -d`），然后启动后端：
Run: `cd backend; .\mvnw.cmd spring-boot:run`
Expected: 启动日志包含 "Auto-ingestion completed: 8 documents indexed"

- [ ] **Step 3: 验证 RAG 增强的对话**

```bash
curl -X POST http://localhost:8080/api/ai/chat/stream \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"message":"What should I eat in Chengdu?","conversationId":null}'
```
Expected: SSE 流式响应，AI 回答包含成都相关平台数据

- [ ] **Step 4: 验证无检索结果时的正常对话**

```bash
curl -X POST http://localhost:8080/api/ai/chat/stream \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"message":"Hello, how are you?","conversationId":null}'
```
Expected: SSE 流式响应，AI 正常回答

- [ ] **Step 5: 验证重新索引 API**

```bash
curl -X POST http://localhost:8080/api/ai/knowledge/reindex
```
Expected: `{"code":200,"data":{"indexedDocuments":8,"sources":{"DESTINATION":5,"POST":3}}}`

- [ ] **Step 6: 验证 Chroma 不可达时的透明降级**

停止 Chroma 容器（`docker compose stop chroma`），再次发送聊天请求。
Expected: 对话正常进行（退化为纯 LLM），无错误暴露给用户

- [ ] **Step 7: 验证 SSE 响应格式不变**

对比变更前后的 SSE 响应格式，确认 `data: {"content":"..."}\n\n` 和 `data: {"content":"","done":true,"conversationId":...}\n\n` 格式完全一致。

- [ ] **Step 8: Final commit**

```bash
git add -A
git commit -m "feat(rag): AI RAG Knowledge Base - complete implementation"
```
