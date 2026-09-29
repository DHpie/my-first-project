# AI Chat Assistant Implementation Plan

> **For agentic workers:** Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task.

**Goal:** Upgrade ChinaBuddy's mock AI widget into a real chat system with Qwen-Plus LLM streaming via SSE, multi-turn context persistence in MySQL, and frontend streaming rendering.

**Architecture:** Backend uses Spring AI 1.0.x OpenAI-Compatible Client pointing to Alibaba DashScope (Qwen-Plus). SSE via `SseEmitter` streams tokens to frontend. Frontend consumes SSE with `fetch` + `ReadableStream`. MySQL stores conversations and messages; a 20-message sliding window provides multi-turn context.

**Tech Stack:** Java 17, Spring Boot 3.3.3, Spring AI 1.0.x, Spring Data JPA, MySQL 8.4, Next.js 15, React 19, TypeScript, fetch API + ReadableStream

**Spec:** `openspec/changes/ai-chat-assistant/` (proposal.md, design.md, specs/)

## Global Constraints

- Backend API responses use `Result<T>` envelope (`code`, `message`, `data`)
- Auth via `X-User-Id` header (read by `CurrentUserUtil.requireUserId(request)`)
- Entity classes extend `BaseEntity` (provides `id`, `uuid`, `createdAt`, `updatedAt`)
- Service pattern: interface + `*Impl` class with `@Service`, `@RequiredArgsConstructor`, `@Transactional`
- Test pattern: JUnit 5 + Mockito + AssertJ, `@ExtendWith(MockitoExtension.class)`, nested `@Nested` classes
- Frontend API proxy: Next.js rewrites `/api/*` → `http://localhost:8080/api/*`
- All spec content in Chinese; code/identifiers in English

---

## File Structure

### Backend — New Files
| File | Responsibility |
|------|---------------|
| `entity/AiConversation.java` | JPA entity for AI conversation sessions |
| `entity/AiMessage.java` | JPA entity for individual chat messages |
| `repository/AiConversationRepository.java` | JPA repository for conversations |
| `repository/AiMessageRepository.java` | JPA repository for messages |
| `dto/request/AiChatStreamRequest.java` | Request DTO for streaming chat |
| `dto/response/AiChatHistoryResponse.java` | Response DTO for chat history |
| `dto/response/AiChatMessageResponse.java` | Response DTO for individual message |
| `service/AiChatService.java` | Service interface |
| `service/impl/AiChatServiceImpl.java` | Service implementation (core orchestration) |
| `controller/AiChatStreamController.java` | SSE streaming + history + archive endpoints |
| `test/.../service/impl/AiChatServiceImplTest.java` | Service unit tests |
| `test/.../controller/AiChatStreamControllerTest.java` | Controller unit tests |

### Backend — Modified Files
| File | Change |
|------|--------|
| `pom.xml` | Add Spring AI BOM + starters |
| `application.yml` | Add `spring.ai.openai.*` config + system prompt |
| `controller/AiChatController.java` | Add `@Deprecated` annotation |

### Frontend — New Files
| File | Responsibility |
|------|---------------|
| `src/types/ai-chat.ts` | TypeScript interfaces for AI chat |

### Frontend — Modified Files
| File | Change |
|------|--------|
| `src/api/ai.ts` | Add `streamChat()`, `getChatHistory()`, `archiveConversation()` |
| `src/components/ai-widget/chat-message.tsx` | Add `streaming` prop + cursor animation |
| `src/components/ai-widget/ai-widget.tsx` | SSE streaming, history restore, New Chat button |

---

## Task 1: Backend — Spring AI Dependencies

**Files:**
- Modify: `backend/pom.xml`

**Interfaces:**
- Consumes: Nothing
- Produces: Spring AI `ChatModel` auto-configuration available for injection

- [ ] **Step 1: Add Spring AI BOM and starters to pom.xml**

Open `backend/pom.xml`. Add inside `<properties>`:
```xml
<spring-ai.version>1.0.0</spring-ai.version>
```

Add inside `<dependencyManagement><dependencies>`:
```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-bom</artifactId>
    <version>${spring-ai.version}</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
```

Add after the WebSocket dependency:
```xml
<!-- Spring AI (OpenAI-compatible client for Qwen) -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-openai-spring-boot-starter</artifactId>
</dependency>

<!-- WebFlux (required for Flux streaming support) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```

- [ ] **Step 2: Add Spring AI milestone repository**

Spring AI 1.0.0 may require the Spring Milestones repo. Add inside `<repositories>` (create if missing):
```xml
<repository>
    <id>spring-milestones</id>
    <name>Spring Milestones</name>
    <url>https://repo.spring.io/milestone</url>
</repository>
```

- [ ] **Step 3: Verify compilation**

Run: `cd backend; .\mvnw.cmd compile`
Expected: BUILD SUCCESS with no dependency resolution errors.

- [ ] **Step 4: Commit**

```bash
git add backend/pom.xml
git commit -m "feat(ai): add Spring AI 1.0.x and WebFlux dependencies"
```

---

## Task 2: Backend — Application Configuration

**Files:**
- Modify: `backend/src/main/resources/application.yml`

**Interfaces:**
- Consumes: Spring AI auto-configuration
- Produces: Configured `ChatModel` bean pointing to Qwen-Plus

- [ ] **Step 1: Add AI configuration to application.yml**

Add under `spring:` in `application.yml`:
```yaml
  ai:
    openai:
      base-url: https://dashscope.aliyuncs.com/compatible-mode
      api-key: ${DASHSCOPE_API_KEY:}
      chat:
        options:
          model: qwen-plus
          temperature: 0.7
```

Add under `app:` in `application.yml`:
```yaml
  ai:
    system-prompt: >
      You are ChinaBuddy, an expert AI travel assistant specializing in China travel.
      Your knowledge covers destinations, cuisine, culture, transportation, accommodation,
      and local customs across China. Be friendly, concise, and practical.
      Always respond in English unless the user writes in another language.
      Keep responses under 200 words unless the user asks for more detail.
```

- [ ] **Step 2: Verify application starts (may warn about empty API key, but must not crash)**

Run: `cd backend; .\mvnw.cmd spring-boot:run` (stop after startup confirmed)
Expected: Application starts. If `DASHSCOPE_API_KEY` is empty, Spring AI logs a warning but app continues.

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/resources/application.yml
git commit -m "feat(ai): add Qwen-Plus and system prompt configuration"
```

---

## Task 3: Backend — Database DDL

**Files:**
- Create: `backend/src/main/resources/db/migration/V1__ai_chat_tables.sql` (or execute directly)

- [ ] **Step 1: Create the DDL script**

```sql
-- AI Conversation table
CREATE TABLE ai_conversation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid BINARY(16) NOT NULL DEFAULT (UUID_TO_BIN(UUID())),
    user_id BIGINT NOT NULL,
    title VARCHAR(100) NOT NULL DEFAULT 'AI Travel Assistant',
    archived_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ai_conv_user_id (user_id),
    UNIQUE KEY uk_ai_conv_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- AI Message table
CREATE TABLE ai_message (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid BINARY(16) NOT NULL DEFAULT (UUID_TO_BIN(UUID())),
    conversation_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ai_msg_conv FOREIGN KEY (conversation_id) REFERENCES ai_conversation(id),
    INDEX idx_ai_msg_conv_id (conversation_id),
    UNIQUE KEY uk_ai_msg_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

- [ ] **Step 2: Execute DDL against MySQL**

Run the SQL in MySQL. Verify: `SHOW TABLES LIKE 'ai_%';` returns both tables.

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/resources/db/
git commit -m "feat(ai): add ai_conversation and ai_message tables DDL"
```

---

## Task 4: Backend — AiConversation Entity + Repository (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/entity/AiConversation.java`
- Create: `backend/src/main/java/com/example/myfirst/repository/AiConversationRepository.java`
- Create: `backend/src/test/java/com/example/myfirst/repository/AiConversationRepositoryTest.java`

**Interfaces:**
- Consumes: BaseEntity, Spring Data JPA
- Produces: `AiConversation` entity + `AiConversationRepository` for service layer

- [ ] **Step 1: Write the repository test**

```java
package com.example.myfirst.repository;

import com.example.myfirst.entity.AiConversation;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class AiConversationRepositoryTest {

    @Autowired
    private AiConversationRepository repository;

    @Test
    @DisplayName("save and find active by userId")
    void shouldSaveAndFindActiveByUserId() {
        AiConversation conv = new AiConversation();
        conv.setUserId(1L);
        conv.setTitle("AI Travel Assistant");
        repository.save(conv);

        Optional<AiConversation> found = repository.findActiveByUserId(1L);
        assertThat(found).isPresent();
        assertThat(found.get().getTitle()).isEqualTo("AI Travel Assistant");
        assertThat(found.get().getArchivedAt()).isNull();
    }

    @Test
    @DisplayName("archived conversation not returned by findActiveByUserId")
    void shouldNotReturnArchivedConversation() {
        AiConversation conv = new AiConversation();
        conv.setUserId(2L);
        conv.setTitle("Old Chat");
        conv.setArchivedAt(java.time.LocalDateTime.now());
        repository.save(conv);

        Optional<AiConversation> found = repository.findActiveByUserId(2L);
        assertThat(found).isEmpty();
    }
}
```

- [ ] **Step 2: Run test — expect compile failure (classes don't exist yet)**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiConversationRepositoryTest`
Expected: FAIL — `AiConversation` and `AiConversationRepository` not found.

- [ ] **Step 3: Create AiConversation entity**

```java
package com.example.myfirst.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@Entity
@Table(name = "ai_conversation", indexes = {
        @Index(name = "idx_ai_conv_user_id", columnList = "user_id")
})
public class AiConversation extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, length = 100)
    private String title = "AI Travel Assistant";

    @Column(name = "archived_at")
    private LocalDateTime archivedAt;
}
```

- [ ] **Step 4: Create AiConversationRepository**

```java
package com.example.myfirst.repository;

import com.example.myfirst.entity.AiConversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AiConversationRepository extends JpaRepository<AiConversation, Long> {

    Optional<AiConversation> findByUserIdAndArchivedAtIsNull(Long userId);

    default Optional<AiConversation> findActiveByUserId(Long userId) {
        return findByUserIdAndArchivedAtIsNull(userId);
    }
}
```

- [ ] **Step 5: Run test — expect PASS**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiConversationRepositoryTest`
Expected: PASS (2/2 tests).

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/entity/AiConversation.java
git add backend/src/main/java/com/example/myfirst/repository/AiConversationRepository.java
git add backend/src/test/java/com/example/myfirst/repository/AiConversationRepositoryTest.java
git commit -m "feat(ai): add AiConversation entity and repository with tests"
```

---

## Task 5: Backend — AiMessage Entity + Repository (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/entity/AiMessage.java`
- Create: `backend/src/main/java/com/example/myfirst/repository/AiMessageRepository.java`
- Create: `backend/src/test/java/com/example/myfirst/repository/AiMessageRepositoryTest.java`

**Interfaces:**
- Consumes: BaseEntity, AiConversation
- Produces: `AiMessage` entity + `AiMessageRepository`

- [ ] **Step 1: Write the repository test**

```java
package com.example.myfirst.repository;

import com.example.myfirst.entity.AiConversation;
import com.example.myfirst.entity.AiMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class AiMessageRepositoryTest {

    @Autowired
    private AiMessageRepository messageRepository;

    @Autowired
    private AiConversationRepository conversationRepository;

    private Long conversationId;

    @BeforeEach
    void setUp() {
        AiConversation conv = new AiConversation();
        conv.setUserId(1L);
        conv.setTitle("Test");
        conversationId = conversationRepository.save(conv).getId();
    }

    @Test
    @DisplayName("find messages ordered by createdAt ascending")
    void shouldFindMessagesOrderedByCreatedAtAsc() {
        AiMessage msg1 = new AiMessage();
        msg1.setConversationId(conversationId);
        msg1.setRole("user");
        msg1.setContent("Hello");
        messageRepository.save(msg1);

        AiMessage msg2 = new AiMessage();
        msg2.setConversationId(conversationId);
        msg2.setRole("assistant");
        msg2.setContent("Hi there!");
        messageRepository.save(msg2);

        List<AiMessage> messages = messageRepository.findByConversationIdOrderByCreatedAtAsc(conversationId);
        assertThat(messages).hasSize(2);
        assertThat(messages.get(0).getRole()).isEqualTo("user");
        assertThat(messages.get(1).getRole()).isEqualTo("assistant");
    }

    @Test
    @DisplayName("find top 20 messages ordered by createdAt descending")
    void shouldFindTop20ByCreatedAtDesc() {
        for (int i = 0; i < 25; i++) {
            AiMessage msg = new AiMessage();
            msg.setConversationId(conversationId);
            msg.setRole("user");
            msg.setContent("Message " + i);
            messageRepository.save(msg);
        }

        List<AiMessage> top20 = messageRepository.findTop20ByConversationIdOrderByCreatedAtDesc(conversationId);
        assertThat(top20).hasSize(20);
        // First item should be the latest message
        assertThat(top20.get(0).getContent()).isEqualTo("Message 24");
    }

    @Test
    @DisplayName("count messages by conversationId")
    void shouldCountMessagesByConversationId() {
        for (int i = 0; i < 5; i++) {
            AiMessage msg = new AiMessage();
            msg.setConversationId(conversationId);
            msg.setRole("user");
            msg.setContent("Msg " + i);
            messageRepository.save(msg);
        }

        long count = messageRepository.countByConversationId(conversationId);
        assertThat(count).isEqualTo(5L);
    }
}
```

- [ ] **Step 2: Run test — expect compile failure**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiMessageRepositoryTest`
Expected: FAIL — classes not found.

- [ ] **Step 3: Create AiMessage entity**

```java
package com.example.myfirst.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@Entity
@Table(name = "ai_message", indexes = {
        @Index(name = "idx_ai_msg_conv_id", columnList = "conversation_id")
})
public class AiMessage extends BaseEntity {

    @Column(name = "conversation_id", nullable = false)
    private Long conversationId;

    @Column(nullable = false, length = 20)
    private String role;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;
}
```

- [ ] **Step 4: Create AiMessageRepository**

```java
package com.example.myfirst.repository;

import com.example.myfirst.entity.AiMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AiMessageRepository extends JpaRepository<AiMessage, Long> {

    List<AiMessage> findByConversationIdOrderByCreatedAtAsc(Long conversationId);

    List<AiMessage> findTop20ByConversationIdOrderByCreatedAtDesc(Long conversationId);

    long countByConversationId(Long conversationId);
}
```

- [ ] **Step 5: Run test — expect PASS**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiMessageRepositoryTest`
Expected: PASS (3/3 tests).

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/entity/AiMessage.java
git add backend/src/main/java/com/example/myfirst/repository/AiMessageRepository.java
git add backend/src/test/java/com/example/myfirst/repository/AiMessageRepositoryTest.java
git commit -m "feat(ai): add AiMessage entity and repository with tests"
```

---

## Task 6: Backend — DTOs

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/dto/request/AiChatStreamRequest.java`
- Create: `backend/src/main/java/com/example/myfirst/dto/response/AiChatHistoryResponse.java`
- Create: `backend/src/main/java/com/example/myfirst/dto/response/AiChatMessageResponse.java`

- [ ] **Step 1: Create AiChatStreamRequest**

```java
package com.example.myfirst.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class AiChatStreamRequest {

    @NotBlank(message = "Message field is required")
    @Size(max = 500, message = "Message exceeds maximum length of 500 characters")
    private String message;

    private Long conversationId;
}
```

- [ ] **Step 2: Create AiChatMessageResponse**

```java
package com.example.myfirst.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AiChatMessageResponse {
    private Long id;
    private String role;
    private String content;
    private String createdAt;
}
```

- [ ] **Step 3: Create AiChatHistoryResponse**

```java
package com.example.myfirst.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AiChatHistoryResponse {
    private Long conversationId;
    private List<AiChatMessageResponse> messages;
    private boolean hasMore;
}
```

- [ ] **Step 4: Verify compilation**

Run: `cd backend; .\mvnw.cmd compile`
Expected: BUILD SUCCESS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/dto/
git commit -m "feat(ai): add AI chat request/response DTOs"
```

---

## Task 7: Backend — AiChatService (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/service/AiChatService.java`
- Create: `backend/src/main/java/com/example/myfirst/service/impl/AiChatServiceImpl.java`
- Create: `backend/src/test/java/com/example/myfirst/service/impl/AiChatServiceImplTest.java`

**Interfaces:**
- Consumes: AiConversationRepository, AiMessageRepository, ChatModel (Spring AI), system prompt config
- Produces: `Flux<String>` stream, `AiChatHistoryResponse`, archive operation

- [ ] **Step 1: Write the service test**

```java
package com.example.myfirst.service.impl;

import com.example.myfirst.dto.response.AiChatHistoryResponse;
import com.example.myfirst.entity.AiConversation;
import com.example.myfirst.entity.AiMessage;
import com.example.myfirst.repository.AiConversationRepository;
import com.example.myfirst.repository.AiMessageRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.chat.model.ChatModel;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AiChatServiceImplTest {

    @Mock private AiConversationRepository conversationRepository;
    @Mock private AiMessageRepository messageRepository;
    @Mock private ChatModel chatModel;

    @InjectMocks
    private AiChatServiceImpl aiChatService;

    @Nested
    @DisplayName("getChatHistory")
    class GetChatHistory {

        @Test
        @DisplayName("no active conversation → returns empty response")
        void shouldReturnEmptyWhenNoConversation() {
            when(conversationRepository.findActiveByUserId(1L)).thenReturn(Optional.empty());

            AiChatHistoryResponse response = aiChatService.getChatHistory(1L);

            assertThat(response.getConversationId()).isNull();
            assertThat(response.getMessages()).isEmpty();
            assertThat(response.isHasMore()).isFalse();
        }

        @Test
        @DisplayName("active conversation with messages → returns messages ordered asc")
        void shouldReturnMessagesWhenConversationExists() {
            AiConversation conv = new AiConversation();
            conv.setId(100L);
            when(conversationRepository.findActiveByUserId(1L)).thenReturn(Optional.of(conv));

            AiMessage msg1 = new AiMessage();
            msg1.setId(1L);
            msg1.setRole("user");
            msg1.setContent("Hello");
            msg1.setCreatedAt(LocalDateTime.of(2026, 9, 29, 10, 0));

            AiMessage msg2 = new AiMessage();
            msg2.setId(2L);
            msg2.setRole("assistant");
            msg2.setContent("Hi!");
            msg2.setCreatedAt(LocalDateTime.of(2026, 9, 29, 10, 1));

            when(messageRepository.findByConversationIdOrderByCreatedAtAsc(100L))
                    .thenReturn(List.of(msg1, msg2));
            when(messageRepository.countByConversationId(100L)).thenReturn(2L);

            AiChatHistoryResponse response = aiChatService.getChatHistory(1L);

            assertThat(response.getConversationId()).isEqualTo(100L);
            assertThat(response.getMessages()).hasSize(2);
            assertThat(response.getMessages().get(0).getRole()).isEqualTo("user");
            assertThat(response.isHasMore()).isFalse();
        }

        @Test
        @DisplayName("more than 100 messages → hasMore is true, returns only 100")
        void shouldSetHasMoreWhenOver100Messages() {
            AiConversation conv = new AiConversation();
            conv.setId(200L);
            when(conversationRepository.findActiveByUserId(2L)).thenReturn(Optional.of(conv));
            when(messageRepository.countByConversationId(200L)).thenReturn(150L);

            // Return a list of 100 messages (latest 100)
            when(messageRepository.findByConversationIdOrderByCreatedAtAsc(200L))
                    .thenReturn(List.of()); // simplified for test

            AiChatHistoryResponse response = aiChatService.getChatHistory(2L);

            assertThat(response.isHasMore()).isTrue();
        }
    }

    @Nested
    @DisplayName("archiveConversation")
    class Archive {

        @Test
        @DisplayName("active conversation exists → sets archivedAt")
        void shouldSetArchivedAt() {
            AiConversation conv = new AiConversation();
            conv.setId(100L);
            when(conversationRepository.findActiveByUserId(1L)).thenReturn(Optional.of(conv));

            aiChatService.archiveConversation(1L);

            assertThat(conv.getArchivedAt()).isNotNull();
            verify(conversationRepository).save(conv);
        }

        @Test
        @DisplayName("no active conversation → does nothing")
        void shouldDoNothingWhenNoConversation() {
            when(conversationRepository.findActiveByUserId(1L)).thenReturn(Optional.empty());

            aiChatService.archiveConversation(1L);

            verify(conversationRepository, never()).save(any());
        }
    }
}
```

- [ ] **Step 2: Run test — expect compile failure**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiChatServiceImplTest`
Expected: FAIL — `AiChatService` and `AiChatServiceImpl` not found.

- [ ] **Step 3: Create AiChatService interface**

```java
package com.example.myfirst.service;

import com.example.myfirst.dto.response.AiChatHistoryResponse;
import reactor.core.publisher.Flux;

public interface AiChatService {

    Flux<String> streamMessage(Long userId, String message, Long conversationId);

    AiChatHistoryResponse getChatHistory(Long userId);

    void archiveConversation(Long userId);
}
```

- [ ] **Step 4: Create AiChatServiceImpl**

```java
package com.example.myfirst.service.impl;

import com.example.myfirst.dto.response.AiChatHistoryResponse;
import com.example.myfirst.dto.response.AiChatMessageResponse;
import com.example.myfirst.entity.AiConversation;
import com.example.myfirst.entity.AiMessage;
import com.example.myfirst.repository.AiConversationRepository;
import com.example.myfirst.repository.AiMessageRepository;
import com.example.myfirst.service.AiChatService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiChatServiceImpl implements AiChatService {

    private final AiConversationRepository conversationRepository;
    private final AiMessageRepository messageRepository;
    private final ChatModel chatModel;

    @Value("${app.ai.system-prompt}")
    private String systemPrompt;

    private static final int CONTEXT_WINDOW = 20;
    private static final int HISTORY_LIMIT = 100;

    @Override
    public Flux<String> streamMessage(Long userId, String message, Long conversationId) {
        // 1. Find or create active conversation
        AiConversation conversation;
        if (conversationId != null) {
            conversation = conversationRepository.findById(conversationId)
                    .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));
        } else {
            conversation = conversationRepository.findActiveByUserId(userId)
                    .orElseGet(() -> {
                        AiConversation conv = new AiConversation();
                        conv.setUserId(userId);
                        conv.setTitle("AI Travel Assistant");
                        return conversationRepository.save(conv);
                    });
        }

        final Long convId = conversation.getId();

        // 2. Load context window (last 20 messages, reversed to chronological order)
        List<AiMessage> historyDesc = messageRepository.findTop20ByConversationIdOrderByCreatedAtDesc(convId);
        List<AiMessage> history = new ArrayList<>(historyDesc);
        java.util.Collections.reverse(history);

        // 3. Build messages for AI model
        List<Message> messages = new ArrayList<>();
        messages.add(new SystemMessage(systemPrompt));
        for (AiMessage histMsg : history) {
            if ("user".equals(histMsg.getRole())) {
                messages.add(new UserMessage(histMsg.getContent()));
            } else if ("assistant".equals(histMsg.getRole())) {
                messages.add(new AssistantMessage(histMsg.getContent()));
            }
        }
        messages.add(new UserMessage(message));

        // 4. Save user message
        AiMessage userMsg = new AiMessage();
        userMsg.setConversationId(convId);
        userMsg.setRole("user");
        userMsg.setContent(message);
        messageRepository.save(userMsg);

        // 5. Stream response from AI model
        Prompt prompt = new Prompt(messages);
        StringBuilder fullReply = new StringBuilder();

        return chatModel.stream(prompt)
                .flatMap(response -> {
                    String content = response.getResult().getOutput().getText();
                    if (content != null) {
                        fullReply.append(content);
                    }
                    return Flux.just(content != null ? content : "");
                })
                .doOnComplete(() -> {
                    // 6. Persist assistant reply after stream completes
                    AiMessage assistantMsg = new AiMessage();
                    assistantMsg.setConversationId(convId);
                    assistantMsg.setRole("assistant");
                    assistantMsg.setContent(fullReply.toString());
                    messageRepository.save(assistantMsg);
                })
                .doOnError(e -> log.error("AI streaming error for user {}: {}", userId, e.getMessage()));
    }

    @Override
    @Transactional(readOnly = true)
    public AiChatHistoryResponse getChatHistory(Long userId) {
        return conversationRepository.findActiveByUserId(userId)
                .map(conv -> {
                    long totalCount = messageRepository.countByConversationId(conv.getId());
                    List<AiMessage> messages = messageRepository.findByConversationIdOrderByCreatedAtAsc(conv.getId());

                    // If over HISTORY_LIMIT, take only the latest HISTORY_LIMIT
                    List<AiMessage> limited = messages.size() > HISTORY_LIMIT
                            ? messages.subList(messages.size() - HISTORY_LIMIT, messages.size())
                            : messages;

                    List<AiChatMessageResponse> responseMessages = limited.stream()
                            .map(m -> new AiChatMessageResponse(
                                    m.getId(),
                                    m.getRole(),
                                    m.getContent(),
                                    m.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
                            ))
                            .collect(Collectors.toList());

                    return new AiChatHistoryResponse(conv.getId(), responseMessages, totalCount > HISTORY_LIMIT);
                })
                .orElse(new AiChatHistoryResponse(null, List.of(), false));
    }

    @Override
    @Transactional
    public void archiveConversation(Long userId) {
        conversationRepository.findActiveByUserId(userId).ifPresent(conv -> {
            conv.setArchivedAt(LocalDateTime.now());
            conversationRepository.save(conv);
        });
    }
}
```

- [ ] **Step 5: Run test — expect PASS**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiChatServiceImplTest`
Expected: PASS (5/5 tests).

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/service/AiChatService.java
git add backend/src/main/java/com/example/myfirst/service/impl/AiChatServiceImpl.java
git add backend/src/test/java/com/example/myfirst/service/impl/AiChatServiceImplTest.java
git commit -m "feat(ai): add AiChatService with streaming, history, and archive"
```

---

## Task 8: Backend — SSE Controller (TDD)

**Files:**
- Create: `backend/src/main/java/com/example/myfirst/controller/AiChatStreamController.java`
- Create: `backend/src/test/java/com/example/myfirst/controller/AiChatStreamControllerTest.java`

**Interfaces:**
- Consumes: AiChatService, CurrentUserUtil
- Produces: SSE stream endpoint, history endpoint, archive endpoint

- [ ] **Step 1: Write the controller test**

```java
package com.example.myfirst.controller;

import com.example.myfirst.dto.response.AiChatHistoryResponse;
import com.example.myfirst.dto.response.AiChatMessageResponse;
import com.example.myfirst.service.AiChatService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AiChatStreamControllerTest {

    @Mock
    private AiChatService aiChatService;

    @InjectMocks
    private AiChatStreamController controller;

    @Test
    @DisplayName("getChatHistory returns Result with history data")
    void shouldReturnChatHistory() {
        AiChatMessageResponse msg = new AiChatMessageResponse(1L, "user", "Hello", "2026-09-29T10:00:00");
        AiChatHistoryResponse history = new AiChatHistoryResponse(100L, List.of(msg), false);
        when(aiChatService.getChatHistory(1L)).thenReturn(history);

        var result = controller.getChatHistory(1L);

        assertThat(result.getCode()).isEqualTo(200);
        assertThat(result.getData().getConversationId()).isEqualTo(100L);
        assertThat(result.getData().getMessages()).hasSize(1);
    }

    @Test
    @DisplayName("archiveConversation returns success")
    void shouldArchiveConversation() {
        var result = controller.archiveConversation(1L);
        assertThat(result.getCode()).isEqualTo(200);
    }
}
```

- [ ] **Step 2: Run test — expect compile failure**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiChatStreamControllerTest`
Expected: FAIL — `AiChatStreamController` not found.

- [ ] **Step 3: Create AiChatStreamController**

```java
package com.example.myfirst.controller;

import com.example.myfirst.common.CurrentUserUtil;
import com.example.myfirst.common.Result;
import com.example.myfirst.dto.request.AiChatStreamRequest;
import com.example.myfirst.dto.response.AiChatHistoryResponse;
import com.example.myfirst.service.AiChatService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Slf4j
@RestController
@RequestMapping("/api/ai/chat")
@RequiredArgsConstructor
public class AiChatStreamController {

    private final AiChatService aiChatService;
    private final ExecutorService executor = Executors.newCachedThreadPool();

    @PostMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamChat(
            @Valid @RequestBody AiChatStreamRequest request,
            HttpServletRequest httpRequest) {
        Long userId = CurrentUserUtil.requireUserId(httpRequest);
        SseEmitter emitter = new SseEmitter(60_000L); // 60s timeout

        executor.execute(() -> {
            try {
                aiChatService.streamMessage(userId, request.getMessage(), request.getConversationId())
                        .doOnNext(token -> {
                            try {
                                emitter.send(SseEmitter.event()
                                        .data("{\"content\":\"" + escapeJson(token) + "\"}"));
                            } catch (IOException e) {
                                emitter.completeWithError(e);
                            }
                        })
                        .doOnComplete(() -> {
                            try {
                                // Find conversation ID for response
                                var conv = aiChatService.getChatHistory(userId);
                                Long convId = conv.getConversationId();
                                emitter.send(SseEmitter.event()
                                        .data("{\"content\":\"\",\"done\":true,\"conversationId\":" + convId + "}"));
                                emitter.complete();
                            } catch (IOException e) {
                                emitter.completeWithError(e);
                            }
                        })
                        .doOnError(error -> {
                            try {
                                emitter.send(SseEmitter.event()
                                        .data("{\"error\":\"AI service unavailable. Please try again.\"}"));
                                emitter.complete();
                            } catch (IOException e) {
                                emitter.completeWithError(e);
                            }
                        })
                        .subscribe();
            } catch (Exception e) {
                try {
                    emitter.send(SseEmitter.event()
                            .data("{\"error\":\"" + escapeJson(e.getMessage()) + "\"}"));
                    emitter.complete();
                } catch (IOException ex) {
                    emitter.completeWithError(ex);
                }
            }
        });

        emitter.onTimeout(emitter::complete);
        emitter.onError(e -> log.warn("SSE error for user {}: {}", userId, e.getMessage()));

        return emitter;
    }

    @GetMapping("/history")
    public Result<AiChatHistoryResponse> getChatHistory(HttpServletRequest request) {
        Long userId = CurrentUserUtil.requireUserId(request);
        return Result.success(aiChatService.getChatHistory(userId));
    }

    @DeleteMapping("/conversation")
    public Result<Void> archiveConversation(HttpServletRequest request) {
        Long userId = CurrentUserUtil.requireUserId(request);
        aiChatService.archiveConversation(userId);
        return Result.success();
    }

    private String escapeJson(String text) {
        if (text == null) return "";
        return text.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
```

- [ ] **Step 4: Run test — expect PASS**

Run: `cd backend; .\mvnw.cmd test -pl . -Dtest=AiChatStreamControllerTest`
Expected: PASS (2/2 tests).

- [ ] **Step 5: Deprecate old Mock controller**

Add `@Deprecated` annotation to `AiChatController.java` class declaration:
```java
@Deprecated
@RestController
@RequestMapping("/api/ai")
public class AiChatController {
```

- [ ] **Step 6: Full backend compilation and test verification**

Run: `cd backend; .\mvnw.cmd test`
Expected: All tests PASS, BUILD SUCCESS.

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/example/myfirst/controller/
git add backend/src/test/java/com/example/myfirst/controller/
git commit -m "feat(ai): add SSE streaming controller + history + archive endpoints"
```

---

## Task 9: Frontend — TypeScript Types

**Files:**
- Create: `frontend/src/types/ai-chat.ts`

- [ ] **Step 1: Create the types file**

```typescript
export interface AiChatStreamRequest {
  message: string;
  conversationId: number | null;
}

export interface AiChatHistoryResponse {
  conversationId: number | null;
  messages: AiChatMessage[];
  hasMore: boolean;
}

export interface AiChatMessage {
  id: number;
  role: "user" | "assistant";
  content: string;
  createdAt: string;
}

export interface SseChunkData {
  content: string;
  done?: boolean;
  conversationId?: number;
  error?: string;
}
```

- [ ] **Step 2: Verify TypeScript compilation**

Run: `cd frontend; npx tsc --noEmit`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/types/ai-chat.ts
git commit -m "feat(ai): add TypeScript types for AI chat"
```

---

## Task 10: Frontend — API Layer

**Files:**
- Modify: `frontend/src/api/ai.ts`

**Interfaces:**
- Consumes: Types from `types/ai-chat.ts`
- Produces: `streamChat()` async generator, `getChatHistory()`, `archiveConversation()`

- [ ] **Step 1: Add new API functions to ai.ts**

Add to `frontend/src/api/ai.ts` (keep existing `chat()` function):

```typescript
import type { AiChatHistoryResponse, SseChunkData } from "@/types/ai-chat";

function getUserId(): string {
  return localStorage.getItem("user_uuid") || "1";
}

export async function* streamChat(
  message: string,
  conversationId: number | null,
  signal: AbortSignal
): AsyncGenerator<SseChunkData> {
  const response = await fetch("/api/ai/chat/stream", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-User-Id": getUserId(),
    },
    body: JSON.stringify({ message, conversationId }),
    signal,
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() || "";

    for (const line of lines) {
      if (line.startsWith("data:")) {
        const jsonStr = line.slice(5).trim();
        if (!jsonStr) continue;
        try {
          const data: SseChunkData = JSON.parse(jsonStr);
          yield data;
        } catch {
          // Skip malformed JSON lines
        }
      }
    }
  }
}

export async function getChatHistory(): Promise<AiChatHistoryResponse> {
  const response = await fetch("/api/ai/chat/history", {
    headers: { "X-User-Id": getUserId() },
  });
  const result = await response.json();
  return result.data;
}

export async function archiveConversation(): Promise<void> {
  await fetch("/api/ai/chat/conversation", {
    method: "DELETE",
    headers: { "X-User-Id": getUserId() },
  });
}
```

- [ ] **Step 2: Verify TypeScript compilation**

Run: `cd frontend; npx tsc --noEmit`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/api/ai.ts
git commit -m "feat(ai): add streamChat, getChatHistory, archiveConversation API functions"
```

---

## Task 11: Frontend — ChatMessage Streaming Cursor

**Files:**
- Modify: `frontend/src/components/ai-widget/chat-message.tsx`

**Interfaces:**
- Consumes: `ChatMessageData` with new `streaming` field
- Produces: Visual streaming cursor animation

- [ ] **Step 1: Update ChatMessageData interface and component**

Replace `frontend/src/components/ai-widget/chat-message.tsx` with:

```tsx
export interface ChatMessageData {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  timestamp: Date;
  streaming?: boolean;
}

interface ChatMessageProps {
  message: ChatMessageData;
}

export default function ChatMessage({ message }: ChatMessageProps) {
  const isUser = message.role === "user";
  const isSystem = message.role === "system";

  if (isSystem) {
    return (
      <div className="px-3 py-2 text-center text-sm text-destructive">
        {message.content}
      </div>
    );
  }

  return (
    <div className={`flex ${isUser ? "justify-end" : "justify-start"}`}>
      <div
        className={`max-w-[80%] rounded-lg px-3 py-2 text-sm ${
          isUser
            ? "bg-primary text-primary-foreground"
            : "bg-muted text-muted-foreground"
        }`}
      >
        {message.content}
        {message.streaming && (
          <span className="ml-0.5 inline-block animate-pulse">▊</span>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend; npx next build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/ai-widget/chat-message.tsx
git commit -m "feat(ai): add streaming cursor animation to ChatMessage"
```

---

## Task 12: Frontend — AI Widget Full Upgrade

**Files:**
- Modify: `frontend/src/components/ai-widget/ai-widget.tsx`

**Interfaces:**
- Consumes: `streamChat`, `getChatHistory`, `archiveConversation` from `api/ai.ts`
- Produces: Full streaming chat widget with history restore, New Chat button

- [ ] **Step 1: Rewrite ai-widget.tsx with all upgrades**

This is the core frontend change. The full component replaces the existing `ai-widget.tsx`:

Key changes from the existing component:
1. **Import** `streamChat`, `getChatHistory`, `archiveConversation` instead of `chat`
2. **New state**: `conversationId` (number | null), `isStreaming` (boolean)
3. **History restore**: On open, call `getChatHistory()`, populate messages
4. **Streaming send**: Replace `chat()` call with `streamChat()` async generator loop
5. **Streaming cursor**: Set `streaming: true` on AI message during stream, `false` after
6. **New Chat button**: In header, calls `archiveConversation()` + resets state
7. **Remove TypingIndicator**: Streaming itself is the "typing" feedback
8. **Timeout**: 30s AbortController for first token

The component should maintain all existing accessibility features (role="dialog", aria-labels, focus trap, Escape key, responsive sizing).

The `sendMessage` function pattern:
```typescript
const sendMessage = async (messageText: string) => {
  // 1. Add user message to state
  // 2. Create empty AI message with streaming: true
  // 3. Set isStreaming = true
  // 4. Call streamChat() with AbortController (30s timeout)
  // 5. Loop: for await (const chunk of stream) { append chunk.content to AI message }
  // 6. On done chunk: save conversationId, set streaming: false, isStreaming: false
  // 7. On error: set streaming: false, add system error message
};
```

The history restore pattern:
```typescript
const loadHistory = async () => {
  try {
    const history = await getChatHistory();
    if (history.messages.length > 0) {
      setConversationId(history.conversationId);
      setMessages(history.messages.map(m => ({
        id: `hist-${m.id}`,
        role: m.role,
        content: m.content,
        timestamp: new Date(m.createdAt),
      })));
    } else {
      setMessages([WELCOME_MESSAGE]);
    }
  } catch {
    setMessages([WELCOME_MESSAGE]); // Silent fallback
  }
};
```

- [ ] **Step 2: Verify build**

Run: `cd frontend; npx next build`
Expected: Build succeeds, no TypeScript errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/ai-widget/ai-widget.tsx
git commit -m "feat(ai): upgrade AI widget with SSE streaming, history restore, New Chat"
```

---

## Task 13: Integration — Full Build Verification

- [ ] **Step 1: Backend full build + test**

Run: `cd backend; .\mvnw.cmd clean test`
Expected: All tests PASS, BUILD SUCCESS.

- [ ] **Step 2: Frontend full build**

Run: `cd frontend; npx next build`
Expected: Build succeeds with no errors.

- [ ] **Step 3: Start backend and frontend, verify SSE endpoint responds**

Start backend: `cd backend; .\mvnw.cmd spring-boot:run`
Start frontend: `cd frontend; npm run dev`

Test with curl (if DASHSCOPE_API_KEY is set):
```bash
curl -X POST http://localhost:8080/api/ai/chat/stream \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"message":"Hello","conversationId":null}'
```
Expected: SSE stream with `data:` events.

Test history endpoint:
```bash
curl http://localhost:8080/api/ai/chat/history -H "X-User-Id: 1"
```
Expected: `{"code":200,"message":"success","data":{...}}`

- [ ] **Step 4: E2E browser test**

Open `http://localhost:3000` → Click AI floating button → Type a message → Observe streaming response → Send a follow-up to test multi-turn context → Refresh page → Reopen chat to verify history restore → Click "New Chat" → Verify history cleared.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat(ai): AI Chat Assistant - complete implementation"
```
