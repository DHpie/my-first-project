## 1. 后端依赖与配置

- [x] 1.1 在 `pom.xml` 中添加 Spring AI BOM（1.0.x）依赖管理 + `spring-ai-openai-spring-boot-starter` + `spring-boot-starter-webflux`，运行 `mvnw.cmd compile` 验证依赖引入成功且无冲突
- [x] 1.2 在 `application.yml` 中添加 `spring.ai.openai.*` 配置块（base-url: `https://dashscope.aliyuncs.com/compatible-mode/v1`、api-key 环境变量引用 `${DASHSCOPE_API_KEY}`、chat.model: `qwen-plus`、chat.options.temperature: `0.7`），添加 `app.ai.system-prompt` 配置项（ChinaBuddy 旅游专家角色 prompt），验证应用正常启动

## 2. 数据库表

- [x] 2.1 创建 `ai_conversation` 表 DDL（id BIGINT PK AUTO_INCREMENT, user_id BIGINT NOT NULL, title VARCHAR(100) NOT NULL, archived_at DATETIME NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, INDEX idx_user_id (user_id)），在 MySQL 中执行并验证表创建成功
- [x] 2.2 创建 `ai_message` 表 DDL（id BIGINT PK AUTO_INCREMENT, conversation_id BIGINT NOT NULL, role VARCHAR(20) NOT NULL, content TEXT NOT NULL, created_at DATETIME NOT NULL, FK conversation_id → ai_conversation.id），在 MySQL 中执行并验证表创建成功

## 3. 后端 Entity + Repository

- [x] 3.1 创建 `AiConversation` Entity 类（字段：id, userId, title, archivedAt, createdAt, updatedAt），验证编译通过
- [x] 3.2 创建 `AiMessage` Entity 类（字段：id, conversationId, role, content, createdAt），验证编译通过
- [x] 3.3 创建 `AiConversationRepository` 接口，包含方法：`findActiveByUserId(Long userId)`（WHERE user_id=? AND archived_at IS NULL）、`findByUserIdAndArchivedAtIsNull`，验证编译通过
- [x] 3.4 创建 `AiMessageRepository` 接口，包含方法：`findByConversationIdOrderByCreatedAtAsc(Long conversationId)`、`findTop20ByConversationIdOrderByCreatedAtDesc(Long conversationId)`、`countByConversationId(Long conversationId)`，验证编译通过

## 4. 后端 DTO

- [x] 4.1 创建 `AiChatStreamRequest` DTO（message: String @NotBlank @Size(max=500), conversationId: Long nullable），验证编译通过
- [x] 4.2 创建 `AiChatHistoryResponse` DTO（conversationId: Long, messages: List, hasMore: boolean），验证编译通过
- [x] 4.3 创建 `AiChatMessageResponse` DTO（id: Long, role: String, content: String, createdAt: String），验证编译通过

## 5. 后端 Service 层

- [x] 5.1 创建 `AiChatService` 接口，定义方法：`Flux<String> streamMessage(Long userId, String message, Long conversationId)`、`AiChatHistoryResponse getChatHistory(Long userId)`、`void archiveConversation(Long userId)`，验证编译通过
- [x] 5.2 实现 `AiChatServiceImpl.streamMessage()`：查找或创建活跃会话 → 加载最近 20 条历史 → 构建 messages 数组（system prompt + history + new message）→ 调用 Spring AI `ChatClient.prompt().stream().content()` → 通过 Flux 逐 token 返回 → 流结束后异步持久化 user + assistant 消息。验证编译通过
- [x] 5.3 实现 `AiChatServiceImpl.getChatHistory()`：查找活跃会话 → 加载消息（最多 100 条）→ 计算 hasMore → 返回 DTO。验证编译通过
- [x] 5.4 实现 `AiChatServiceImpl.archiveConversation()`：查找活跃会话 → 设置 archived_at = now → 保存。验证编译通过

## 6. 后端 Controller（SSE 端点）

- [x] 6.1 创建 `POST /api/ai/chat/stream` 端点：接收 `AiChatStreamRequest` + `X-User-Id` header → 创建 `SseEmitter`（超时 60s）→ 订阅 `AiChatService.streamMessage()` 的 Flux → 每个 token 发送 `data: {"content":"..."}\n\n` → 完成时发送 `data: {"content":"","done":true,"conversationId":...}\n\n` → 错误时发送 `data: {"error":"..."}\n\n`。注册 onCompletion/onTimeout/onError 回调清理资源。验证通过 curl 手动测试 SSE 流式输出
- [x] 6.2 创建 `GET /api/ai/chat/history` 端点：读取 `X-User-Id` → 调用 `AiChatService.getChatHistory()` → 返回 `Result<AiChatHistoryResponse>`。验证 curl 请求返回正确格式
- [x] 6.3 创建 `DELETE /api/ai/chat/conversation` 端点：读取 `X-User-Id` → 调用 `AiChatService.archiveConversation()` → 返回 `Result<Void>`。验证 curl 请求返回 200
- [x] 6.4 在现有 `AiChatController` 类上添加 `@Deprecated` 注解，标记 Mock API 为废弃

## 7. 前端 API 层

- [x] 7.1 在 `api/ai.ts` 中新增 `streamChat()` 函数：使用 `fetch` + `ReadableStream` 消费 `POST /api/ai/chat/stream` 的 SSE 响应，解析 `data:` 行提取 JSON，以 `AsyncGenerator<string>` 逐 token yield 内容。保留原有 `chat()` 函数不删除。验证函数签名和类型正确
- [x] 7.2 在 `api/ai.ts` 中新增 `getChatHistory()` 函数：`GET /api/ai/chat/history`，携带 `X-User-Id` header，返回 `AiChatHistoryResponse`。验证函数签名正确
- [x] 7.3 在 `api/ai.ts` 中新增 `archiveConversation()` 函数：`DELETE /api/ai/chat/conversation`，携带 `X-User-Id` header。验证函数签名正确
- [x] 7.4 新增 `types/ai-chat.ts` 类型定义文件：`AiChatStreamRequest`、`AiChatHistoryResponse`、`AiChatMessage`、`SseChunkData` 接口。验证 TypeScript 编译通过

## 8. 前端组件升级

- [x] 8.1 升级 `chat-message.tsx`：`ChatMessageData` 接口新增 `streaming?: boolean` 字段。当 `streaming === true` 时，消息内容末尾渲染闪烁光标 `▊`（CSS 动画）。验证光标在 streaming 状态显示、非 streaming 状态隐藏
- [x] 8.2 升级 `ai-widget.tsx` 状态管理：新增 `conversationId` state（number | null）、`isStreaming` state（boolean）。移除 `isLoading` 对 TypingIndicator 的控制（流式输出本身即为视觉反馈）。验证组件编译通过
- [x] 8.3 升级 `ai-widget.tsx` 会话历史恢复：打开对话窗时调用 `getChatHistory()`，有历史时恢复消息列表并保存 conversationId，无历史时显示欢迎消息，API 失败时静默降级为欢迎消息。验证打开对话窗后历史消息正确加载
- [x] 8.4 升级 `ai-widget.tsx` 消息发送逻辑：`sendMessage()` 改为调用 `streamChat()` AsyncGenerator，逐 token 追加到当前 AI 消息的 content 中（设置 `streaming: true`），流结束后设置 `streaming: false` 并保存 conversationId。验证 AI 回复逐字渲染
- [x] 8.5 升级 `ai-widget.tsx` 流式期间输入控制：streaming 期间禁用输入框和发送按钮，隐藏 TypingIndicator。验证 streaming 期间无法输入
- [x] 8.6 升级 `ai-widget.tsx` 错误处理：SSE 连接中断时保留已接收内容并追加系统错误消息，30s 超时中断请求显示错误 + Retry 按钮，SSE 错误事件解析并显示为系统消息。验证各类错误场景处理正确
- [x] 8.7 升级 `ai-widget.tsx` header 区域：添加 "New Chat" 按钮（`aria-label="Start new chat"`），点击调用 `archiveConversation()` → 清空本地消息 → 重置 conversationId → 显示欢迎消息。API 失败时仅本地重置。验证按钮功能正确

## 9. 集成验证

- [x] 9.1 后端启动验证：`mvnw.cmd compile` 编译通过，应用正常启动（Spring AI ChatClient Bean 注入成功）
- [x] 9.2 前端构建验证：`npm run build` 编译通过，无 TypeScript 错误
- [x] 9.3 端到端流式聊天验证：打开首页 → 点击 AI 悬浮按钮 → 发送消息 → 观察 AI 回复逐字渲染 → 发送追问验证多轮上下文 → 刷新页面 → 重新打开对话窗验证历史恢复
- [x] 9.4 新建对话验证：点击 "New Chat" → 验证历史清空 → 发送新消息 → 验证新会话创建
- [x] 9.5 错误场景验证：断开网络发送消息 → 验证错误消息 + Retry → API Key 缺失 → 验证友好提示
